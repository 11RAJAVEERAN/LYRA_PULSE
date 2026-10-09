import unittest

from config import MAX_TEMPLATE_COUNT
from services.fingerprint_service import FingerprintService


class SearchSensor:
    def __init__(self, result):
        self.result = result
        self.search_arguments = None

    def search(self, **kwargs):
        self.search_arguments = kwargs
        return self.result


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


if __name__ == "__main__":
    unittest.main()
