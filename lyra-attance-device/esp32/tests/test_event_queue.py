import errno
import json
import os
import unittest
from unittest.mock import patch

from services.event_queue import PersistentEventQueue


class FakeAPI:
    def __init__(self, fail=False, responses=None):
        self.events = []
        self.fail = fail
        self.responses = responses or []

    def post_queued_event(self, device_id, event):
        self.events.append((device_id, dict(event)))
        if self.responses:
            return self.responses.pop(0)
        return {"success": not self.fail, "data": {"status": "CHECKED_IN"}}


class PersistentEventQueueTests(unittest.TestCase):
    @staticmethod
    def read_queue(path):
        with open(path, "r") as handle:
            return json.loads(handle.read())

    @staticmethod
    def read_bytes(path):
        with open(path, "rb") as handle:
            return handle.read()

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
        self.assertEqual(self.read_queue(self.path), [])

    def test_pending_count_reports_persisted_events(self):
        self.assertEqual(self.queue.pending_count(), 0)
        self.queue.append({"event_id": "event-count-1", "fingerprint_slot": 4, "occurred_at": "2026-10-21T10:00:00+00:00"})
        self.queue.append({"event_id": "event-count-2", "fingerprint_slot": 4, "occurred_at": "2026-10-21T10:01:00+00:00"})
        self.assertEqual(PersistentEventQueue(self.path).pending_count(), 2)

    def test_failed_sync_keeps_queue_for_retry(self):
        event = {"event_id": "event-3", "fingerprint_slot": 9, "occurred_at": "2026-10-21T10:02:00+00:00"}
        self.queue.append(event)
        self.assertEqual(self.queue.flush(FakeAPI(fail=True), "device-1"), {})
        self.assertEqual(self.read_queue(self.path), [event])

    def test_unmapped_event_stays_queued_and_retries_with_same_event_id(self):
        event = {"event_id": "event-4", "fingerprint_slot": 2, "occurred_at": "2026-10-21T10:03:00+00:00"}
        self.queue.append(event)
        api = FakeAPI(responses=[
            {"success": False, "status_code": 404},
            {"success": True, "data": {"status": "CHECKED_IN"}},
        ])

        self.assertEqual(self.queue.flush(api, "device-1"), {})
        self.assertEqual(self.read_queue(self.path), [event])

        result = self.queue.flush(api, "device-1")

        self.assertIn("event-4", result)
        self.assertEqual([item[1]["event_id"] for item in api.events], ["event-4", "event-4"])
        self.assertEqual(self.read_queue(self.path), [])

    def test_flush_propagates_read_error_without_changing_queue(self):
        event = {"event_id": "event-5", "fingerprint_slot": 2, "occurred_at": "2026-10-21T10:04:00+00:00"}
        self.queue.append(event)
        original = self.read_bytes(self.path)

        with patch("builtins.open", side_effect=OSError(errno.EIO, "read failed")):
            with self.assertRaises(OSError):
                self.queue.flush(FakeAPI(), "device-1")

        self.assertEqual(self.read_bytes(self.path), original)

    def test_append_read_error_does_not_replace_existing_queue(self):
        event = {"event_id": "event-6", "fingerprint_slot": 2, "occurred_at": "2026-10-21T10:05:00+00:00"}
        self.queue.append(event)
        original = self.read_bytes(self.path)
        appended = {"event_id": "event-7", "fingerprint_slot": 3, "occurred_at": "2026-10-21T10:06:00+00:00"}

        with patch("builtins.open", side_effect=OSError(errno.EACCES, "read denied")):
            with self.assertRaises(OSError):
                self.queue.append(appended)

        self.assertEqual(self.read_bytes(self.path), original)
        self.assertFalse(os.path.exists(self.path + ".tmp"))

    def test_append_write_error_leaves_existing_queue_unchanged(self):
        event = {"event_id": "event-8", "fingerprint_slot": 2, "occurred_at": "2026-10-21T10:07:00+00:00"}
        self.queue.append(event)
        original = self.read_bytes(self.path)
        appended = {"event_id": "event-9", "fingerprint_slot": 3, "occurred_at": "2026-10-21T10:08:00+00:00"}

        with patch("services.event_queue.os.replace", side_effect=OSError(errno.EIO, "replace failed")):
            with self.assertRaises(OSError):
                self.queue.append(appended)

        self.assertEqual(self.read_bytes(self.path), original)
        self.assertFalse(os.path.exists(self.path + ".tmp"))

    def test_replace_unavailable_uses_rename_without_losing_fifo(self):
        first = {"event_id": "event-11", "fingerprint_slot": 2, "occurred_at": "2026-10-21T10:09:00+00:00"}
        second = {"event_id": "event-12", "fingerprint_slot": 3, "occurred_at": "2026-10-21T10:10:00+00:00"}
        self.queue.append(first)

        with patch("services.event_queue.os.replace", None):
            self.queue.append(second)

        self.assertEqual(self.read_queue(self.path), [first, second])
        self.assertEqual(
            [event["event_id"] for event in self.read_queue(self.path)],
            ["event-11", "event-12"],
        )
        self.assertFalse(os.path.exists(self.path + ".tmp"))

    def test_rename_failure_preserves_original_queue_bytes(self):
        event = {"event_id": "event-13", "fingerprint_slot": 2, "occurred_at": "2026-10-21T10:11:00+00:00"}
        self.queue.append(event)
        original = self.read_bytes(self.path)
        appended = {"event_id": "event-14", "fingerprint_slot": 3, "occurred_at": "2026-10-21T10:12:00+00:00"}

        with patch("services.event_queue.os.replace", None):
            with patch("services.event_queue.os.rename", side_effect=OSError(errno.EIO, "rename failed")):
                with self.assertRaisesRegex(OSError, "Safe queue replacement unavailable"):
                    self.queue.append(appended)

        self.assertEqual(self.read_bytes(self.path), original)
        self.assertFalse(os.path.exists(self.path + ".tmp"))

    def test_temporary_file_write_failure_preserves_original_queue_bytes(self):
        event = {"event_id": "event-15", "fingerprint_slot": 2, "occurred_at": "2026-10-21T10:13:00+00:00"}
        self.queue.append(event)
        original = self.read_bytes(self.path)
        appended = {"event_id": "event-16", "fingerprint_slot": 3, "occurred_at": "2026-10-21T10:14:00+00:00"}

        with patch(
            "services.event_queue.json.dumps",
            side_effect=OSError(errno.ENOSPC, "temporary write failed"),
        ):
            with self.assertRaises(OSError):
                self.queue.append(appended)

        self.assertEqual(self.read_bytes(self.path), original)
        self.assertFalse(os.path.exists(self.path + ".tmp"))

    def test_queue_recovers_after_failed_replacement(self):
        first = {"event_id": "event-17", "fingerprint_slot": 2, "occurred_at": "2026-10-21T10:15:00+00:00"}
        second = {"event_id": "event-18", "fingerprint_slot": 3, "occurred_at": "2026-10-21T10:16:00+00:00"}
        self.queue.append(first)
        original = self.read_bytes(self.path)

        with patch("services.event_queue.os.replace", side_effect=OSError(errno.EIO, "replace failed")):
            with self.assertRaises(OSError):
                self.queue.append(second)

        self.assertEqual(self.read_bytes(self.path), original)
        self.assertFalse(os.path.exists(self.path + ".tmp"))

        self.queue.append(second)

        self.assertEqual(self.read_queue(self.path), [first, second])

    def test_non_list_queue_data_is_not_treated_as_empty(self):
        with open(self.path, "w") as handle:
            handle.write("{}")
        original = self.read_bytes(self.path)

        with self.assertRaises(ValueError):
            self.queue.append({"event_id": "event-10"})

        self.assertEqual(self.read_bytes(self.path), original)


if __name__ == "__main__":
    unittest.main()
