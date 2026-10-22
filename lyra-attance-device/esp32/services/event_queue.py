"""Small persistent FIFO for offline attendance events (event IDs stay stable across retries)."""
import json
import os


class PersistentEventQueue:
    def __init__(self, path="/attendance_queue.json", max_events=500):
        self.path = path
        self.max_events = max_events

    def _read(self):
        try:
            with open(self.path, "r") as handle:
                data = json.loads(handle.read())
            return data if isinstance(data, list) else []
        except OSError:
            return []

    def _write(self, events):
        temporary = self.path + ".tmp"
        with open(temporary, "w") as handle:
            handle.write(json.dumps(events))
            if hasattr(handle, "flush"):
                handle.flush()
        try:
            os.replace(temporary, self.path)
        except AttributeError:
            try:
                os.remove(self.path)
            except OSError:
                pass
            os.rename(temporary, self.path)

    def append(self, event):
        events = self._read()
        if len(events) >= self.max_events:
            raise OSError("Offline attendance queue is full; sync is required")
        events.append(event)
        self._write(events)

    def flush(self, api_client, device_id):
        outcomes = {}
        events = self._read()
        while events:
            current = events[0]
            result = api_client.post_queued_event(device_id, current)
            if not result.get("success"):
                break  # Keep the head and all later events; preserve scan order for safe recovery.
            outcomes[current["event_id"]] = result
            events.pop(0)
            self._write(events)
        return outcomes
