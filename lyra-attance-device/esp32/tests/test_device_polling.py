import sys
import types
import unittest

import fakes

fakes.machine.I2C = lambda *args, **kwargs: None
micropython = types.ModuleType("micropython")
micropython.const = lambda value: value
sys.modules.setdefault("micropython", micropython)

from main import poll_enrollment_command, run_attendance_scan


class FakeAPI:
    def __init__(self, response):
        self.response = response
        self.polled_device_id = None

    def poll_enrollment(self, device_id):
        self.polled_device_id = device_id
        return self.response


class FakeAttendanceAPI:
    def __init__(self):
        self.events = []

    def send_attendance(self, device_id, fingerprint_slot):
        self.events.append(("api", device_id, fingerprint_slot))
        return {
            "success": True,
            "data": {
                "status": "CHECKED_IN",
                "employee": {"id": 3, "name": "Test Employee"},
            },
        }


class FakeAttendanceFingerprintService:
    def __init__(self, matched_slot, events):
        self.matched_slot = matched_slot
        self.events = events

    def wait_for_finger(self):
        self.events.append(("finger",))

    def capture_fingerprint(self):
        self.events.append(("capture",))

    def search_fingerprint(self):
        self.events.append(("search",))
        return self.matched_slot

    def wait_for_finger_removed(self):
        self.events.append(("remove",))


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

        self.assertIn(("api", "LYRA-DEVICE-001", 137), events)
        self.assertLess(events.index(("search",)), events.index(("api", "LYRA-DEVICE-001", 137)))
        self.assertLess(
            events.index(("api", "LYRA-DEVICE-001", 137)),
            events.index(("remove",)),
        )
        self.assertEqual(api.events, [("api", "LYRA-DEVICE-001", 137)])

    def test_unknown_fingerprint_does_not_call_attendance_api(self):
        events = []
        api = FakeAttendanceAPI()
        fingerprint = FakeAttendanceFingerprintService(None, events)

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

        self.assertEqual(api.events, [])
        self.assertIn(("remove",), events)


if __name__ == "__main__":
    unittest.main()
