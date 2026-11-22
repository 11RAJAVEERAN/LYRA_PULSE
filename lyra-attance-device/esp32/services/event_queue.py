"""Small persistent FIFO for offline attendance events (event IDs stay stable across retries)."""
import errno
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
        except OSError as exc:
            error_number = getattr(exc, "errno", None)
            if error_number is None and getattr(exc, "args", None):
                error_number = exc.args[0]
            if error_number == errno.ENOENT:
                return []
            raise
        if not isinstance(data, list):
            raise ValueError("Attendance queue must contain a JSON list")
        return data

    def _write(self, events):
        temporary = self.path + ".tmp"
        try:
            with open(temporary, "w") as handle:
                handle.write(json.dumps(events))
                if hasattr(handle, "flush"):
                    handle.flush()
            replace = getattr(os, "replace", None)
            if replace is None:
                try:
                    os.rename(temporary, self.path)
                except OSError as exc:
                    raise OSError(
                        "Safe queue replacement unavailable; existing queue was preserved: %s"
                        % exc
                    )
            else:
                replace(temporary, self.path)
        except Exception as exc:
            try:
                self._remove_temporary(temporary)
            except OSError as cleanup_error:
                raise OSError(
                    "Queue replacement failed (%s); temporary-file cleanup failed (%s)"
                    % (exc, cleanup_error)
                )
            raise

    @staticmethod
    def _remove_temporary(path):
        try:
            os.remove(path)
        except OSError as exc:
            error_number = getattr(exc, "errno", None)
            if error_number is None and getattr(exc, "args", None):
                error_number = exc.args[0]
            if error_number != errno.ENOENT:
                raise

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
