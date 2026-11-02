import unittest

import fakes

from drivers.r307 import R307FingerError, R307ImageError, R307TemplateError
from services.fingerprint_service import EnrollmentError, FingerprintService


class FakeSensor:
    def __init__(self, duplicate=None, verification=None):
        self.images = [True, False, True, False, True]
        self.conversion_error = None
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
        if self.images.pop(0):
            return True
        raise R307FingerError("No finger")

    def image_to_template(self, buffer_id):
        self.converted_buffers.append(buffer_id)
        if self.conversion_error is not None:
            raise self.conversion_error

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


class EnrollmentTouchSensor:
    active_level = 0

    def __init__(self):
        self.events = [True, True]
        self.active = False
        self.release_calls = 0

    def poll_touch_edge(self):
        if not self.events:
            return False
        detected = self.events.pop(0)
        self.active = detected
        return detected

    def is_active(self):
        return self.active

    def current_level(self):
        return 0 if self.active else 1

    def is_released_debounced(self):
        return not self.active

    def wait_for_release(self, timeout_seconds=None):
        self.release_calls += 1
        self.active = False
        return True

    def reset_baseline(self):
        self.active = False


class FakeAPI:
    def __init__(self, response=None):
        self.statuses = []
        self.response = response

    def report_enrollment_status(self, device_id, enrollment_id, status, fingerprint_slot=None):
        self.statuses.append((status, fingerprint_slot))
        if self.response is not None:
            return self.response
        return {
            "success": True,
            "data": {"status": status, "fingerprint_slot": fingerprint_slot},
        }


class FingerprintEnrollmentFlowTests(unittest.TestCase):
    def setUp(self):
        self.sensor = FakeSensor()
        self.touch = EnrollmentTouchSensor()
        self.service = FingerprintService(self.sensor, self.touch)
        self.display = FakeDisplay()
        self.api = FakeAPI()

    def test_reports_success_after_two_scans_model_creation_and_slot_storage(self):
        command = {"action": "ENROLL_FINGERPRINT", "enrollment_id": "enroll-1"}

        slot = self.service.enroll_from_command(
            command,
            self.display,
            self.api,
            "LYRA-DEVICE-001",
        )

        self.assertEqual(slot, 1)
        self.assertEqual(self.sensor.converted_buffers, [1, 2])
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
        self.assertEqual(
            self.display.prompts,
            ["Place finger 1/2", "Same finger 2/2"],
        )
        self.assertTrue(self.service._awaiting_removal)
        self.assertEqual(self.touch.release_calls, 1)

    def test_server_rejection_prevents_enrollment_success_feedback(self):
        self.api = FakeAPI({"success": False, "response": {"message": "rejected"}})
        command = {"action": "ENROLL_FINGERPRINT", "enrollment_id": "enroll-rejected"}

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "DEVICE_API_ERROR")
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

    def test_sensor_conversion_error_is_reported_without_storing_a_template(self):
        self.sensor.conversion_error = R307ImageError("Image conversion failed")
        command = {"action": "ENROLL_FINGERPRINT", "enrollment_id": "enroll-image-error"}

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "IMAGE_CAPTURE_FAILED")
        self.assertEqual(str(error.exception), "Image conversion failed")
        self.assertFalse(self.sensor.stored)

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
