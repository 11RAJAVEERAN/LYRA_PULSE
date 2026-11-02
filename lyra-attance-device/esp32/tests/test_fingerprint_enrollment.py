import unittest

import fakes

from drivers.r307 import R307FingerError, R307ImageError, R307TemplateError
from services.fingerprint_service import EnrollmentError, FingerprintService


class FakeSensor:
    def __init__(self, duplicate=None, verification=None):
        self.images = [True] * 8
        self.conversion_errors = []
        self.duplicate = duplicate
        self.verification = verification or {"fingerprint_id": 1, "score": 512}
        self.search_count = 0
        self.converted_buffers = []
        self.stored = []
        self.slot_probe_buffers = []
        self.match_calls = []
        self.match_errors = []
        self.loaded = []
        self.occupied = set()
        self.model_created = False
        self.model_error = None
        self.slot_error = None

    def get_image(self):
        if self.images and self.images.pop(0):
            return True
        raise R307FingerError("No finger")

    def image_to_template(self, buffer_id):
        self.converted_buffers.append(buffer_id)
        if self.conversion_errors:
            error = self.conversion_errors.pop(0)
            if error is not None:
                raise error

    def search(self, **kwargs):
        self.search_count += 1
        if self.duplicate is not None:
            return self.duplicate
        if kwargs.get("start_page") in self.occupied:
            return {
                "fingerprint_id": kwargs["start_page"],
                "score": 512,
            }
        return None

    def create_model(self):
        if self.model_error is not None:
            raise self.model_error
        self.model_created = True

    def match_templates(self, first_buffer, second_buffer):
        self.match_calls.append((first_buffer, second_buffer))
        if self.match_errors:
            error = self.match_errors.pop(0)
            if error is not None:
                raise error
        return {"score": 512}

    def is_template_slot_occupied(self, slot):
        return slot in self.occupied

    def load_template(self, slot, buffer_id):
        if slot not in self.occupied:
            raise R307TemplateError("Template load failed at slot %s: 12" % slot)
        self.loaded.append((slot, buffer_id))

    def find_free_template_slot(self, max_template_count, start_page, buffer_id):
        self.slot_probe_buffers.append(buffer_id)
        if self.slot_error is not None:
            raise self.slot_error
        return 1

    def store_model(self, slot, buffer_id):
        self.stored.append((slot, buffer_id))
        self.occupied.add(slot)


class FakeDisplay:
    def __init__(self):
        self.prompts = []
        self.progress = []
        self.success_slot = None

    def show_enrollment_prompt(self, prompt):
        self.prompts.append(prompt)

    def show_enrollment_progress(
        self,
        employee_id,
        finger_index,
        total_fingers,
        capture_index,
        status,
        finger,
    ):
        self.progress.append(
            (employee_id, finger_index, total_fingers, capture_index, status, finger)
        )

    def show_enrollment_remove_finger(self):
        return None

    def show_enrollment_success(self, slot):
        self.success_slot = slot


class EnrollmentTouchSensor:
    active_level = 0

    def __init__(self):
        self.events = [True] * 8
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

    def wait_for_release(self, timeout_seconds=None, on_wait=None):
        self.release_calls += 1
        self.active = False
        return True

    def reset_baseline(self):
        self.active = False


class FakeAPI:
    def __init__(self, response=None):
        self.statuses = []
        self.response = response
        self.fail_status = None

    def report_enrollment_status(
        self,
        device_id,
        enrollment_id,
        status,
        fingerprint_slot=None,
        error_code=None,
    ):
        self.statuses.append((status, fingerprint_slot))
        if status == self.fail_status:
            return {"success": False}
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

    @staticmethod
    def command(**values):
        command = {
            "action": "ENROLL_FINGERPRINT",
            "enrollment_id": "enroll-1",
            "employee_id": 7,
            "finger": "right_thumb",
            "finger_index": 1,
            "total_fingers": 2,
            "pair_id": "pair-1",
            "status": "WAITING_FOR_FINGER",
        }
        command.update(values)
        return command

    def test_reports_success_after_four_captures_validation_and_storage(self):
        command = self.command()

        slot = self.service.enroll_from_command(
            command,
            self.display,
            self.api,
            "LYRA-DEVICE-001",
        )

        self.assertEqual(slot, 1)
        self.assertEqual(self.sensor.converted_buffers, [1, 2, 2, 2])
        self.assertEqual(self.sensor.match_calls, [(1, 2), (1, 2), (1, 2)])
        self.assertTrue(self.sensor.model_created)
        self.assertEqual(self.sensor.stored, [(1, 1)])
        self.assertEqual(self.sensor.slot_probe_buffers, [2])
        self.assertEqual(
            self.api.statuses,
            [
                ("WAITING_FOR_SECOND_SCAN", None),
                ("PROCESSING", None),
                ("STORING", 1),
                ("SUCCESS", 1),
            ],
        )
        self.assertEqual(self.display.success_slot, 1)
        self.assertEqual(
            [
                (progress[3], progress[4])
                for progress in self.display.progress
                if progress[4] != "REMOVE FINGER"
            ],
            [
                (1, "PLACE FINGER"),
                (2, "PLACE FINGER"),
                (3, "PLACE FINGER"),
                (4, "PLACE FINGER"),
                (4, "ENROLLMENT SUCCESS"),
            ],
        )
        self.assertFalse(self.service._awaiting_removal)
        self.assertEqual(self.touch.release_calls, 4)

    def test_server_rejection_prevents_enrollment_success_feedback(self):
        self.api = FakeAPI({"success": False, "response": {"message": "rejected"}})
        command = self.command(enrollment_id="enroll-rejected")

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
        command = self.command(enrollment_id="enroll-3")

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
        command = self.command(enrollment_id="enroll-image-error")
        self.sensor.conversion_errors = [
            R307ImageError("Image conversion failed")
        ] * 3

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "IMAGE_CAPTURE_FAILED")
        self.assertIn("failed after 3 attempts", str(error.exception))
        self.assertFalse(self.sensor.stored)

    def test_model_generation_error_is_classified_and_preserves_sensor_status(self):
        self.sensor.model_error = R307TemplateError("Model generation failed: 10")
        command = self.command(enrollment_id="enroll-model-error")

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
        command = self.command(enrollment_id="enroll-slot-error")

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

    def test_capture_retry_does_not_increment_progress(self):
        self.sensor.conversion_errors = [R307ImageError("Poor image")]
        command = self.command()

        self.service.enroll_from_command(
            command,
            self.display,
            self.api,
            "LYRA-DEVICE-001",
        )

        capture_one_progress = [
            status
            for _, _, _, capture_index, status, _ in self.display.progress
            if capture_index == 1 and status != "REMOVE FINGER"
        ]
        self.assertEqual(
            capture_one_progress,
            ["PLACE FINGER", "RETRY", "PLACE FINGER"],
        )

    def test_match_failure_retries_the_same_capture_index(self):
        self.sensor.match_errors = [
            R307TemplateError("Fingerprint samples did not match")
        ]

        self.service.enroll_from_command(
            self.command(),
            self.display,
            self.api,
            "LYRA-DEVICE-001",
        )

        capture_three_progress = [
            status
            for _, _, _, capture_index, status, _ in self.display.progress
            if capture_index == 3 and status != "REMOVE FINGER"
        ]
        self.assertEqual(
            capture_three_progress,
            ["PLACE FINGER", "RETRY", "PLACE FINGER"],
        )

    def test_recovery_confirms_reserved_template_without_new_captures(self):
        self.sensor.occupied.add(17)
        command = self.command(
            status="STORING",
            fingerprint_slot=17,
        )

        slot = self.service.enroll_from_command(
            command,
            self.display,
            self.api,
            "LYRA-DEVICE-001",
        )

        self.assertEqual(slot, 17)
        self.assertEqual(self.sensor.loaded, [(17, 1)])
        self.assertFalse(self.sensor.converted_buffers)
        self.assertEqual(self.api.statuses, [("SUCCESS", 17)])

    def test_reserved_slot_is_not_overwritten_if_existing_template_cannot_be_confirmed(self):
        self.sensor.occupied.add(17)
        self.sensor.verification = None
        self.sensor.search = lambda **_kwargs: None
        command = self.command(
            status="STORING",
            fingerprint_slot=17,
        )

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "SLOT_VERIFICATION_FAILED")
        self.assertFalse(self.sensor.stored)

    def test_network_failure_reporting_storing_does_not_store_or_report_failure(self):
        self.api.fail_status = "STORING"
        command = self.command()

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "DEVICE_API_ERROR")
        self.assertFalse(self.sensor.stored)
        self.assertEqual(self.api.statuses[-1], ("STORING", 1))

    def test_success_report_network_failure_recovers_from_reserved_slot(self):
        self.api.fail_status = "SUCCESS"
        command = self.command()

        with self.assertRaises(EnrollmentError) as error:
            self.service.enroll_from_command(
                command,
                self.display,
                self.api,
                "LYRA-DEVICE-001",
            )

        self.assertEqual(error.exception.error_code, "DEVICE_API_ERROR")
        self.assertEqual(self.sensor.stored, [(1, 1)])

        self.api.fail_status = None
        recovered = self.service.enroll_from_command(
            self.command(status="STORING", fingerprint_slot=1),
            self.display,
            self.api,
            "LYRA-DEVICE-001",
        )

        self.assertEqual(recovered, 1)
        self.assertEqual(self.sensor.stored, [(1, 1)])
        self.assertEqual(self.api.statuses[-1], ("SUCCESS", 1))


if __name__ == "__main__":
    unittest.main()
