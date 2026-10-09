import unittest

import fakes

from drivers.r307 import R307FingerError, R307ImageError, R307TemplateError
from services.fingerprint_service import EnrollmentError, FingerprintService


class FakeSensor:
    def __init__(self, duplicate=None, verification=None):
        self.images = [True, False, True, False, True]
        self.image_error = None
        self.duplicate = duplicate
        self.verification = verification or {"fingerprint_id": 1, "score": 512}
        self.search_count = 0
        self.converted_buffers = []
        self.stored = []
        self.slot_probe_buffers = []
        self.model_created = False
        self.model_error = None
        self.slot_error = None

    def get_image(self):
        if self.image_error is not None:
            raise self.image_error
        if self.images.pop(0):
            return True
        raise R307FingerError("No finger")

    def image_to_template(self, buffer_id):
        self.converted_buffers.append(buffer_id)

    def search(self, **kwargs):
        self.search_count += 1
        return self.duplicate if self.search_count == 1 else self.verification

    def create_model(self):
        if self.model_error is not None:
            raise self.model_error
        self.model_created = True

    def find_free_template_slot(self, max_template_count, start_page, buffer_id):
        self.slot_probe_buffers.append(buffer_id)
        if self.slot_error is not None:
            raise self.slot_error
        return 1

    def store_model(self, slot, buffer_id):
        self.stored.append((slot, buffer_id))


class FakeDisplay:
    def __init__(self):
        self.prompts = []
        self.success_slot = None

    def show_enrollment_prompt(self, prompt):
        self.prompts.append(prompt)

    def show_enrollment_remove_finger(self):
        return None

    def show_enrollment_success(self, slot):
        self.success_slot = slot


class FakeAPI:
    def __init__(self):
        self.statuses = []

    def report_enrollment_status(self, device_id, enrollment_id, status, fingerprint_slot=None):
        self.statuses.append((status, fingerprint_slot))
        return {
            "success": True,
            "data": {"status": status, "fingerprint_slot": fingerprint_slot},
        }


class FingerprintEnrollmentFlowTests(unittest.TestCase):
    def setUp(self):
        self.sensor = FakeSensor()
        self.service = FingerprintService(self.sensor)
        self.display = FakeDisplay()
        self.api = FakeAPI()

    def test_reports_success_only_after_third_scan_confirms_stored_slot(self):
        command = {"action": "ENROLL_FINGERPRINT", "enrollment_id": "enroll-1"}

        slot = self.service.enroll_from_command(
            command,
            self.display,
            self.api,
            "LYRA-DEVICE-001",
        )

        self.assertEqual(slot, 1)
        self.assertEqual(self.sensor.converted_buffers, [1, 2, 1])
        self.assertTrue(self.sensor.model_created)
        self.assertEqual(self.sensor.stored, [(1, 1)])
        self.assertEqual(self.sensor.slot_probe_buffers, [2])
        self.assertEqual(
            self.api.statuses,
            [
                ("WAITING_FOR_SECOND_SCAN", None),
                ("PROCESSING", None),
                ("SUCCESS", 1),
            ],
        )
        self.assertEqual(self.display.success_slot, 1)

    def test_different_fingerprint_on_third_scan_never_reports_success(self):
        self.sensor.verification = {"fingerprint_id": 23, "score": 900}
        command = {"action": "ENROLL_FINGERPRINT", "enrollment_id": "enroll-2"}

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "SLOT_VERIFICATION_FAILED")
        self.assertNotIn("SUCCESS", [status for status, _ in self.api.statuses])
        self.assertIsNone(self.display.success_slot)

    def test_existing_fingerprint_is_rejected_before_template_storage(self):
        self.sensor.duplicate = {"fingerprint_id": 18, "score": 700}
        command = {"action": "ENROLL_FINGERPRINT", "enrollment_id": "enroll-3"}

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "DUPLICATE_FINGERPRINT")
        self.assertFalse(self.sensor.stored)
        self.assertEqual(
            self.api.statuses,
            [
                ("WAITING_FOR_SECOND_SCAN", None),
                ("PROCESSING", None),
            ],
        )

    def test_sensor_image_error_is_wrapped_in_micro_python_compatible_error(self):
        self.sensor.image_error = R307ImageError("Image acquisition failed: 2")
        command = {"action": "ENROLL_FINGERPRINT", "enrollment_id": "enroll-image-error"}

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "IMAGE_CAPTURE_FAILED")
        self.assertEqual(str(error.exception), "Image acquisition failed: 2")

    def test_model_generation_error_is_classified_and_preserves_sensor_status(self):
        self.sensor.model_error = R307TemplateError("Model generation failed: 10")
        command = {"action": "ENROLL_FINGERPRINT", "enrollment_id": "enroll-model-error"}

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "TEMPLATE_CREATE_FAILED")
        self.assertEqual(str(error.exception), "Model generation failed: 10")
        self.assertFalse(self.sensor.stored)

    def test_slot_read_error_is_reported_without_storing_a_template(self):
        self.sensor.slot_error = R307TemplateError(
            "Template load failed at slot 256: 12"
        )
        command = {"action": "ENROLL_FINGERPRINT", "enrollment_id": "enroll-slot-error"}

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "SENSOR_TEMPLATE_READ_ERROR")
        self.assertEqual(str(error.exception), "Template load failed at slot 256: 12")
        self.assertFalse(self.sensor.stored)


if __name__ == "__main__":
    unittest.main()
