import json
import unittest

import fakes

from services import api_service
from services.api_service import AttendanceAPIClient


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
        self.get_arguments = None
        self.get_count = 0

    def post(self, url, data=None, headers=None, timeout=None):
        self.post_count += 1
        self.post_arguments = {
            "url": url,
            "data": data,
            "headers": headers,
            "timeout": timeout,
        }
        return FakeResponse()

    def get(self, url, headers=None, timeout=None):
        self.get_count += 1
        self.get_arguments = {
            "url": url,
            "headers": headers,
            "timeout": timeout,
        }
        return FakeResponse()


class DeviceResultRequestTests(unittest.TestCase):
    def test_enrollment_poll_is_bounded_and_not_retried(self):
        fake_requests = FakeRequests()
        previous_requests = api_service.requests
        api_service.requests = fake_requests
        try:
            client = AttendanceAPIClient(
                base_url="http://backend",
                timeout=10,
                retry_count=2,
            )
            result = client.poll_enrollment("LYRA-DEVICE-001")
        finally:
            api_service.requests = previous_requests

        self.assertTrue(result["success"])
        self.assertEqual(fake_requests.get_count, 1)
        self.assertEqual(
            fake_requests.get_arguments["url"],
            "http://backend/api/v1/devices/LYRA-DEVICE-001/enrollment/pending/",
        )
        self.assertEqual(fake_requests.get_arguments["timeout"], 0.5)

    def test_enrollment_poll_timeout_returns_failure_without_retrying(self):
        class TimeoutRequests:
            def __init__(self):
                self.get_count = 0
                self.timeout = None

            def get(self, _url, headers=None, timeout=None):
                self.get_count += 1
                self.timeout = timeout
                raise OSError("request timed out")

        fake_requests = TimeoutRequests()
        previous_requests = api_service.requests
        api_service.requests = fake_requests
        try:
            client = AttendanceAPIClient(
                base_url="http://backend",
                timeout=10,
                retry_count=2,
            )
            result = client.poll_enrollment("LYRA-DEVICE-001")
        finally:
            api_service.requests = previous_requests

        self.assertFalse(result["success"])
        self.assertEqual(fake_requests.get_count, 1)
        self.assertEqual(fake_requests.timeout, 0.5)
        self.assertIn("timed out", result["error"])

    def test_result_post_uses_urequests_compatible_data_argument(self):
        fake_requests = FakeRequests()
        previous_requests = api_service.requests
        api_service.requests = fake_requests
        try:
            client = AttendanceAPIClient(
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
            client = AttendanceAPIClient(
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
            "http://backend/api/v1/attendance/fingerprint/",
        )
        self.assertEqual(
            json.loads(fake_requests.post_arguments["data"].decode("utf-8")),
            {"device_id": "LYRA-DEVICE-001", "fingerprint_slot": 137},
        )
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
            client = AttendanceAPIClient(
                base_url="http://backend",
                timeout=4,
                retry_count=3,
            )
            result = client.send_attendance("LYRA-DEVICE-001", 137)
        finally:
            api_service.requests = previous_requests

        self.assertFalse(result["success"])
        self.assertEqual(fake_requests.post_count, 1)
        self.assertIn("timed out", result["error"])


if __name__ == "__main__":
    unittest.main()
