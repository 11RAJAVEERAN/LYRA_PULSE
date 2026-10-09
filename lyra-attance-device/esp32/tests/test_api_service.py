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

    def post(self, url, data=None, headers=None, timeout=None):
        self.post_arguments = {
            "url": url,
            "data": data,
            "headers": headers,
            "timeout": timeout,
        }
        return FakeResponse()


class DeviceResultRequestTests(unittest.TestCase):
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
        api_service.requests = fake_requests
        try:
            client = AttendanceAPIClient(
                base_url="http://backend",
                timeout=4,
                retry_count=0,
            )
            result = client.send_attendance("LYRA-DEVICE-001", 137)
        finally:
            api_service.requests = previous_requests

        self.assertTrue(result["success"])
        self.assertEqual(
            fake_requests.post_arguments["url"],
            "http://backend/api/v1/attendance/fingerprint/",
        )
        self.assertEqual(
            json.loads(fake_requests.post_arguments["data"].decode("utf-8")),
            {"device_id": "LYRA-DEVICE-001", "fingerprint_slot": 137},
        )
        self.assertTrue(
            fake_requests.post_arguments["headers"]["Authorization"].startswith("Device ")
        )


if __name__ == "__main__":
    unittest.main()
