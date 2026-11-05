import json
import os
import unittest
import uuid

import fakes

from services import api_service
from services.api_service import AttendanceAPIClient
from services.event_queue import PersistentEventQueue


class FakeResponse:
    status = 200

    def json(self):
        return {
            "success": True,
            "message": "Enrollment result recorded",
            "data": {"status": "FAILED"},
        }

    def close(self):
        return None


class FakeRequests:
    def __init__(self):
        self.post_arguments = None
        self.post_count = 0

    def post(self, url, data=None, headers=None, timeout=None):
        self.post_count += 1
        self.post_arguments = {
            "url": url,
            "data": data,
            "headers": headers,
            "timeout": timeout,
        }
        return FakeResponse()


class DeviceResultRequestTests(unittest.TestCase):
    def make_client(self, **kwargs):
        path = os.path.join(os.path.dirname(__file__), ".api_queue_%s.json" % os.getpid())
        self.addCleanup(lambda: os.remove(path) if os.path.exists(path) else None)
        return AttendanceAPIClient(event_queue=PersistentEventQueue(path), **kwargs)

    def test_result_post_uses_urequests_compatible_data_argument(self):
        fake_requests = FakeRequests()
        previous_requests = api_service.requests
        api_service.requests = fake_requests
        try:
            client = self.make_client(
                base_url="http://backend",
                timeout=4,
                retry_count=0,
            )
            result = client.report_enrollment_status(
                "LYRA-DEVICE-001",
                "enrollment-1",
                "FAILED",
                error_code="IMAGE_CAPTURE_FAILED",
            )
        finally:
            api_service.requests = previous_requests

        self.assertTrue(result["success"])
        self.assertEqual(
            fake_requests.post_arguments["url"],
            "http://backend/api/v1/devices/LYRA-DEVICE-001/enrollment/enrollment-1/result/",
        )
        self.assertEqual(
            json.loads(fake_requests.post_arguments["data"].decode("utf-8")),
            {"status": "FAILED", "error_code": "IMAGE_CAPTURE_FAILED"},
        )
        self.assertEqual(
            fake_requests.post_arguments["headers"]["Content-Type"],
            "application/json",
        )

    def test_attendance_posts_the_sensor_matched_slot_with_device_auth(self):
        fake_requests = FakeRequests()
        previous_requests = api_service.requests
        previous_token = api_service.DEVICE_TOKEN
        api_service.requests = fake_requests
        api_service.DEVICE_TOKEN = "test-device-token"
        try:
            client = self.make_client(
                base_url="http://backend",
                timeout=4,
                retry_count=0,
            )
            result = client.send_attendance("LYRA-DEVICE-001", 137)
        finally:
            api_service.requests = previous_requests
            api_service.DEVICE_TOKEN = previous_token

        self.assertTrue(result["success"])
        self.assertEqual(
            fake_requests.post_arguments["url"],
            "http://backend/api/v1/attendance/fingerprint/events/",
        )
        body = json.loads(fake_requests.post_arguments["data"].decode("utf-8"))
        self.assertEqual(body["device_id"], "LYRA-DEVICE-001")
        self.assertEqual(body["fingerprint_slot"], 137)
        self.assertEqual(str(uuid.UUID(body["event_id"])), body["event_id"])
        self.assertTrue(body["occurred_at"].endswith("+00:00"))
        self.assertEqual(
            fake_requests.post_arguments["headers"]["Authorization"],
            "Device test-device-token",
        )
        self.assertEqual(fake_requests.post_count, 1)

    def test_attendance_timeout_is_not_retried(self):
        class TimeoutRequests:
            def __init__(self):
                self.post_count = 0

            def post(self, *args, **kwargs):
                self.post_count += 1
                raise OSError("request timed out")

        fake_requests = TimeoutRequests()
        previous_requests = api_service.requests
        api_service.requests = fake_requests
        try:
            client = self.make_client(
                base_url="http://backend",
                timeout=4,
                retry_count=3,
            )
            result = client.send_attendance("LYRA-DEVICE-001", 137)
        finally:
            api_service.requests = previous_requests

        self.assertFalse(result["success"])
        self.assertEqual(fake_requests.post_count, 1)
        self.assertTrue(result["queued"])


if __name__ == "__main__":
    unittest.main()
