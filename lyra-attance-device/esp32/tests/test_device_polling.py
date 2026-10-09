import sys
import types
import unittest

import fakes

fakes.machine.I2C = lambda *args, **kwargs: None
micropython = types.ModuleType("micropython")
micropython.const = lambda value: value
sys.modules.setdefault("micropython", micropython)

from main import poll_enrollment_command, run_attendance_scan, run_enrollment
from drivers.r307 import R307CommunicationError
from services.fingerprint_service import EnrollmentError


class FakeAPI:
    def __init__(self, response):
        self.response = response
        self.polled_device_id = None

    def poll_enrollment(self, device_id):
        self.polled_device_id = device_id
        return self.response


class FakeAttendanceAPI:
    def __init__(self, response=None):
        self.response = response or {
            "success": True,
            "http_status": 200,
            "data": {
                "status": "CHECKED_IN",
                "employee": {"id": 3, "name": "Test Employee"},
            },
        }
        self.events = []

    def send_attendance(self, device_id, fingerprint_slot):
        self.events.append(("api", device_id, fingerprint_slot))
        return self.response


class FakeEnrollmentAPI:
    def __init__(self):
        self.reports = []

    def report_enrollment_status(self, device_id, enrollment_id, status, **kwargs):
        self.reports.append((device_id, enrollment_id, status, kwargs))
        return {"success": True, "data": {"status": status}}


class FakeAttendanceFingerprintService:
    def __init__(self, matched_slot, events, capture_error=None):
        self.matched_slot = matched_slot
        self.events = events
        self.capture_error = capture_error

    def wait_for_finger(self):
        self.events.append(("finger",))

    def capture_fingerprint(self):
        self.events.append(("capture",))
        if self.capture_error is not None:
            raise self.capture_error

    def search_fingerprint(self):
        self.events.append(("search",))
        return self.matched_slot

    def wait_for_finger_removed(self):
        self.events.append(("remove",))
        return True


class FakeOled:
    def __init__(self, events):
        self.events = events

    def __getattr__(self, method_name):
        return lambda *args: self.events.append((method_name,) + args)


class FakeOutput:
    def __init__(self, events, output_name):
        self.events = events
        self.output_name = output_name

    def __getattr__(self, method_name):
        return lambda: self.events.append((self.output_name, method_name))


class DevicePollingTests(unittest.TestCase):
    def run_scan(self, api, fingerprint, events):
        import main
        original_sleep = main.time.sleep
        main.time.sleep = lambda _seconds: None
        try:
            run_attendance_scan(
                "LYRA-DEVICE-001",
                api,
                fingerprint,
                FakeOled(events),
                FakeOutput(events, "buzzer"),
                FakeOutput(events, "led"),
            )
        finally:
            main.time.sleep = original_sleep

    def test_duplicate_enrollment_is_reported_as_failed_to_backend(self):
        import main

        events = []
        api = FakeEnrollmentAPI()

        class DuplicateFingerprintService:
            def enroll_from_command(self, *_args):
                raise EnrollmentError(
                    "DUPLICATE_FINGERPRINT",
                    "Finger already exists in sensor slot 1",
                )

        original_sleep = main.time.sleep
        main.time.sleep = lambda _seconds: None
        try:
            run_enrollment(
                {"enrollment_id": "enroll-duplicate"},
                "LYRA-DEVICE-001",
                api,
                DuplicateFingerprintService(),
                FakeOled(events),
                FakeOutput(events, "buzzer"),
                FakeOutput(events, "led"),
            )
        finally:
            main.time.sleep = original_sleep

        self.assertEqual(
            api.reports,
            [(
                "LYRA-DEVICE-001",
                "enroll-duplicate",
                "FAILED",
                {"error_code": "DUPLICATE_FINGERPRINT"},
            )],
        )
        self.assertIn(("show_enrollment_failed",), events)
        self.assertIn(("buzzer", "error_beep"), events)

    def test_empty_poll_returns_without_starting_enrollment(self):
        api = FakeAPI({"success": True, "data": None})

        command = poll_enrollment_command(api, "LYRA-DEVICE-001")

        self.assertIsNone(command)
        self.assertEqual(api.polled_device_id, "LYRA-DEVICE-001")

    def test_pending_enrollment_is_returned_for_enrollment_flow(self):
        pending = {
            "action": "ENROLL_FINGERPRINT",
            "enrollment_id": "enroll-1",
            "employee_id": 3,
            "finger": "right_index",
        }
        api = FakeAPI({"success": True, "data": pending})

        command = poll_enrollment_command(api, "LYRA-DEVICE-001")

        self.assertEqual(command, pending)

    def test_r307_matched_slot_is_sent_to_attendance_api_before_finger_removal(self):
        events = []
        api = FakeAttendanceAPI()
        fingerprint = FakeAttendanceFingerprintService(137, events)
        original_send_attendance = api.send_attendance

        def send_attendance(device_id, fingerprint_slot):
            events.append(("api", device_id, fingerprint_slot))
            return original_send_attendance(device_id, fingerprint_slot)

        api.send_attendance = send_attendance

        self.run_scan(api, fingerprint, events)

        self.assertIn(("api", "LYRA-DEVICE-001", 137), events)
        self.assertLess(events.index(("search",)), events.index(("api", "LYRA-DEVICE-001", 137)))
        self.assertLess(
            events.index(("api", "LYRA-DEVICE-001", 137)),
            events.index(("remove",)),
        )
        self.assertEqual(api.events, [("api", "LYRA-DEVICE-001", 137)])
        self.assertEqual(events.count(("buzzer", "beep_once")), 1)
        self.assertNotIn(("buzzer", "beep_twice"), events)
        self.assertIn(("show_attendance_success", "Test Employee", "CHECKED_IN"), events)
        self.assertIn(("led", "match_success"), events)
        self.assertLess(
            events.index(("api", "LYRA-DEVICE-001", 137)),
            events.index(("buzzer", "beep_once")),
        )
        self.assertEqual(events[-3:], [
            ("buzzer", "off"),
            ("led", "ready_status"),
            ("show_ready",),
        ])

    def test_unknown_fingerprint_does_not_call_attendance_api(self):
        events = []
        api = FakeAttendanceAPI()
        fingerprint = FakeAttendanceFingerprintService(None, events)

        self.run_scan(api, fingerprint, events)

        self.assertEqual(api.events, [])
        self.assertIn(("remove",), events)
        self.assertIn(("show_not_found",), events)
        self.assertEqual(events.count(("buzzer", "beep_twice")), 1)
        self.assertNotIn(("buzzer", "beep_once"), events)
        self.assertIn(("led", "match_failed"), events)

    def test_scan_waits_for_removal_then_one_second_before_ready(self):
        import main

        events = []
        api = FakeAttendanceAPI()
        fingerprint = FakeAttendanceFingerprintService(137, events)
        original_sleep = main.time.sleep
        main.time.sleep = lambda seconds: events.append(("sleep", seconds))
        try:
            run_attendance_scan(
                "LYRA-DEVICE-001",
                api,
                fingerprint,
                FakeOled(events),
                FakeOutput(events, "buzzer"),
                FakeOutput(events, "led"),
            )
        finally:
            main.time.sleep = original_sleep

        remove_index = events.index(("remove",))
        settle_index = events.index(("sleep", 1))
        ready_index = events.index(("led", "ready_status"), settle_index)
        self.assertLess(remove_index, settle_index)
        self.assertLess(settle_index, ready_index)
        self.assertEqual(api.events, [("api", "LYRA-DEVICE-001", 137)])

    def test_following_scan_starts_only_after_previous_scan_removed_finger(self):
        events = []
        api = FakeAttendanceAPI()
        fingerprint = FakeAttendanceFingerprintService(137, events)
        original_send_attendance = api.send_attendance

        def send_attendance(device_id, fingerprint_slot):
            events.append(("api", device_id, fingerprint_slot))
            return original_send_attendance(device_id, fingerprint_slot)

        api.send_attendance = send_attendance

        self.run_scan(api, fingerprint, events)
        first_finger = events.index(("finger",))
        first_api = events.index(("api", "LYRA-DEVICE-001", 137))
        first_remove = events.index(("remove",))
        self.run_scan(api, fingerprint, events)

        finger_indices = [index for index, event in enumerate(events) if event == ("finger",)]
        api_indices = [
            index
            for index, event in enumerate(events)
            if event == ("api", "LYRA-DEVICE-001", 137)
        ]
        removal_indices = [index for index, event in enumerate(events) if event == ("remove",)]

        self.assertEqual(first_finger, finger_indices[0])
        self.assertEqual(len(api_indices), 2)
        self.assertEqual(len(removal_indices), 2)
        self.assertLess(first_api, first_remove)
        self.assertLess(removal_indices[0], finger_indices[1])
        self.assertLess(finger_indices[1], api_indices[1])
        self.assertLess(api_indices[1], removal_indices[1])
        self.assertEqual(len(api.events), 2)

    def test_oled_failure_does_not_suppress_confirmed_success_feedback(self):
        events = []
        api = FakeAttendanceAPI()
        fingerprint = FakeAttendanceFingerprintService(137, events)

        class FailingAttendanceOled(FakeOled):
            def show_attendance_success(self, *_args):
                self.events.append(("show_attendance_success",))
                raise OSError("I2C write failed")

        self.run_scan_with_oled(api, fingerprint, events, FailingAttendanceOled(events))

        self.assertEqual(events.count(("buzzer", "beep_once")), 1)
        self.assertIn(("led", "match_success"), events)
        self.assertNotIn(("led", "api_error"), events)
        self.assertIn("OLED ERROR", [tag for tag, _message in self.logs])

    def test_oled_failure_does_not_suppress_no_match_feedback(self):
        events = []
        api = FakeAttendanceAPI()
        fingerprint = FakeAttendanceFingerprintService(None, events)

        class FailingNoMatchOled(FakeOled):
            def show_not_found(self):
                self.events.append(("show_not_found",))
                raise OSError("I2C write failed")

        self.run_scan_with_oled(api, fingerprint, events, FailingNoMatchOled(events))

        self.assertEqual(api.events, [])
        self.assertEqual(events.count(("buzzer", "beep_twice")), 1)
        self.assertIn(("led", "match_failed"), events)
        self.assertIn("OLED ERROR", [tag for tag, _message in self.logs])

    def run_scan_with_oled(self, api, fingerprint, events, oled):
        import main

        original_sleep = main.time.sleep
        original_log = main.log
        self.logs = []
        main.time.sleep = lambda _seconds: None
        main.log = lambda tag, message: self.logs.append((tag, message))
        try:
            run_attendance_scan(
                "LYRA-DEVICE-001",
                api,
                fingerprint,
                oled,
                FakeOutput(events, "buzzer"),
                FakeOutput(events, "led"),
            )
        finally:
            main.time.sleep = original_sleep
            main.log = original_log

    def test_sensor_error_is_not_reported_as_no_match(self):
        events = []
        api = FakeAttendanceAPI()
        fingerprint = FakeAttendanceFingerprintService(
            25,
            events,
            capture_error=R307CommunicationError("checksum failed"),
        )

        self.run_scan(api, fingerprint, events)

        self.assertEqual(api.events, [])
        self.assertNotIn(("show_not_found",), events)
        self.assertIn(("show_sensor_error",), events)
        self.assertIn(("remove",), events)

    def test_api_error_is_distinct_and_does_not_signal_match_success(self):
        events = []
        api = FakeAttendanceAPI({
            "success": False,
            "status_code": 503,
            "error": "backend unavailable",
        })
        fingerprint = FakeAttendanceFingerprintService(25, events)

        self.run_scan(api, fingerprint, events)

        self.assertIn(("api", "LYRA-DEVICE-001", 25), api.events)
        self.assertIn(("show_api_error",), events)
        self.assertNotIn(("led", "match_success"), events)
        self.assertNotIn(("buzzer", "beep_once"), events)
        self.assertIn(("remove",), events)

    def test_ready_status_is_restored_after_a_completed_scan(self):
        events = []
        api = FakeAttendanceAPI()
        fingerprint = FakeAttendanceFingerprintService(42, events)

        self.run_scan(api, fingerprint, events)

        self.assertEqual(events[0:2], [("led", "ready_status"), ("show_ready",)])
        self.assertEqual(events[-3:], [
            ("buzzer", "off"),
            ("led", "ready_status"),
            ("show_ready",),
        ])


if __name__ == "__main__":
    unittest.main()
