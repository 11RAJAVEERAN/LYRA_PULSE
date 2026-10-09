import unittest
from unittest.mock import patch

from config import MAX_TEMPLATE_COUNT
from drivers.r307 import R307FingerError
from services.fingerprint_service import FingerprintService


class SearchSensor:
    def __init__(self, result):
        self.result = result
        self.search_arguments = None

    def search(self, **kwargs):
        self.search_arguments = kwargs
        return self.result


class FingerRemovalSensor:
    def __init__(self, present_polls):
        self.present_polls = present_polls
        self.calls = 0

    def get_image(self):
        self.calls += 1
        if self.calls > self.present_polls:
            raise R307FingerError("No finger placed on sensor")
        return True


class FingerprintAttendanceSearchTests(unittest.TestCase):
    def test_uses_r307_match_slot_and_searches_configured_template_range(self):
        sensor = SearchSensor({"fingerprint_id": 847, "score": 932})
        service = FingerprintService(sensor)

        matched_slot = service.search_fingerprint()

        self.assertEqual(matched_slot, 847)
        self.assertEqual(
            sensor.search_arguments,
            {
                "buffer_id": 1,
                "start_page": 0,
                "page_num": MAX_TEMPLATE_COUNT,
            },
        )

    def test_sensor_no_match_is_returned_as_none(self):
        sensor = SearchSensor(None)
        service = FingerprintService(sensor)

        self.assertIsNone(service.search_fingerprint())

    def test_wait_for_removal_does_not_return_while_finger_is_detected(self):
        sensor = FingerRemovalSensor(present_polls=3)
        service = FingerprintService(sensor)

        with patch("services.fingerprint_service.time.sleep") as sleep:
            self.assertTrue(service.wait_for_finger_removed())

        self.assertEqual(sensor.calls, 4)
        self.assertEqual([call.args for call in sleep.call_args_list], [(0.2,)] * 3)


if __name__ == "__main__":
    unittest.main()
