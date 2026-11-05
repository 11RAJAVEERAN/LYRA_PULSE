import json
import os
import unittest

from services.event_queue import PersistentEventQueue


class FakeAPI:
    def __init__(self, fail=False):
        self.events = []
        self.fail = fail

    def post_queued_event(self, device_id, event):
        self.events.append((device_id, dict(event)))
        return {"success": not self.fail, "data": {"status": "CHECKED_IN"}}


class PersistentEventQueueTests(unittest.TestCase):
    def setUp(self):
        self.path = os.path.join(os.path.dirname(__file__), ".queue_test_%s.json" % os.getpid())
        self.queue = PersistentEventQueue(self.path)

    def tearDown(self):
        for path in (self.path, self.path + ".tmp"):
            try:
                os.remove(path)
            except OSError:
                pass

    def test_queue_persists_and_flushes_in_order(self):
        self.queue.append({"event_id": "event-1", "fingerprint_slot": 4, "occurred_at": "2026-10-21T10:00:00+00:00"})
        self.queue.append({"event_id": "event-2", "fingerprint_slot": 4, "occurred_at": "2026-10-21T10:01:00+00:00"})
        reopened = PersistentEventQueue(self.path)
        api = FakeAPI()
        result = reopened.flush(api, "device-1")
        self.assertEqual(list(result), ["event-1", "event-2"])
        self.assertEqual([item[1]["event_id"] for item in api.events], ["event-1", "event-2"])
        self.assertEqual(json.loads(open(self.path).read()), [])

    def test_failed_sync_keeps_queue_for_retry(self):
        event = {"event_id": "event-3", "fingerprint_slot": 9, "occurred_at": "2026-10-21T10:02:00+00:00"}
        self.queue.append(event)
        self.assertEqual(self.queue.flush(FakeAPI(fail=True), "device-1"), {})
        self.assertEqual(json.loads(open(self.path).read()), [event])


if __name__ == "__main__":
    unittest.main()
