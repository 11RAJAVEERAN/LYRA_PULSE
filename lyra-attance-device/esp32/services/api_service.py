"""HTTP client for posting attendance events to the configured Django backend."""

import json
import os
import time

try:
    import urequests as requests
except ImportError:  # pragma: no cover - CPython fallback for local testing
    import urllib.request
    import urllib.error

    class _CPythonResponse:
        def __init__(self, payload, status):
            self._payload = payload
            self.status = status

        def json(self):
            return json.loads(self._payload.decode("utf-8"))

        def close(self):
            return None

    class _CPythonRequests:
        @staticmethod
        def post(url, data=None, headers=None, timeout=None):
            request = urllib.request.Request(url, data=data, headers=headers or {}, method="POST")
            try:
                with urllib.request.urlopen(request, timeout=timeout) as response:
                    payload = response.read()
                    return _CPythonResponse(payload, response.status)
            except urllib.error.HTTPError as exc:
                payload = exc.read() if exc.fp else b"{}"
                return _CPythonResponse(payload, exc.code)
            except Exception:
                raise

        @staticmethod
        def get(url, headers=None, timeout=None):
            request = urllib.request.Request(url, headers=headers or {}, method="GET")
            try:
                with urllib.request.urlopen(request, timeout=timeout) as response:
                    return _CPythonResponse(response.read(), response.status)
            except urllib.error.HTTPError as exc:
                payload = exc.read() if exc.fp else b"{}"
                return _CPythonResponse(payload, exc.code)

    requests = _CPythonRequests()

from config import (
    API_BASE_URL,
    API_DEVICE_ENROLLMENT_PENDING,
    API_DEVICE_ENROLLMENT_RESULT,
    API_FINGERPRINT_ENDPOINT,
    API_RETRY_COUNT,
    API_TIMEOUT,
    DEVICE_TOKEN,
)
from utils.logger import log
from services.event_queue import PersistentEventQueue


def _uuid4():
    try:
        raw = bytearray(os.urandom(16))
    except Exception:
        raw = bytearray([int(time.time() * 1000) & 255 for _ in range(16)])
    raw[6] = (raw[6] & 0x0F) | 0x40
    raw[8] = (raw[8] & 0x3F) | 0x80
    value = "%032x" % int.from_bytes(raw, "big")
    return "%s-%s-%s-%s-%s" % (value[:8], value[8:12], value[12:16], value[16:20], value[20:])


def _utc_timestamp():
    value = time.gmtime()
    if value[0] < 2020:
        raise ValueError("Device clock is not synchronized")
    return "%04d-%02d-%02dT%02d:%02d:%02d+00:00" % tuple(value[:6])


class AttendanceAPIClient:
    def __init__(self, base_url=API_BASE_URL, timeout=API_TIMEOUT, retry_count=API_RETRY_COUNT, event_queue=None):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.retry_count = retry_count
        self.event_queue = event_queue or PersistentEventQueue()

    def _endpoint(self):
        return self.base_url + API_FINGERPRINT_ENDPOINT

    def send_attendance(self, device_id, fingerprint_slot):
        event = {"event_id": _uuid4(), "fingerprint_slot": int(fingerprint_slot), "occurred_at": _utc_timestamp()}
        self.event_queue.append(event)
        result = self.event_queue.flush(self, device_id).get(event["event_id"])
        if result is None:
            return {"success": False, "queued": True, "message": "Attendance saved on device and waiting for synchronization."}
        return result

    def post_queued_event(self, device_id, event):
        payload = dict(event)
        payload["device_id"] = device_id
        return self._device_request("POST", API_FINGERPRINT_ENDPOINT, payload, retry_count=0, headers=self._device_headers())

    def sync_pending(self, device_id):
        return self.event_queue.flush(self, device_id)

    def _device_headers(self):
        headers = {"Content-Type": "application/json"}
        if DEVICE_TOKEN:
            headers["Authorization"] = "Device %s" % DEVICE_TOKEN
        return headers

    @staticmethod
    def _response_body(response):
        try:
            body = response.json() if hasattr(response, "json") else {}
        except Exception as exc:
            return {"success": False, "message": "Invalid JSON response: %s" % exc}
        return body if isinstance(body, dict) else {"success": False, "data": body}

    def _device_request(self, method, endpoint, payload=None, retry_count=None, headers=None):
        url = self.base_url + endpoint
        last_error = None
        attempts = self.retry_count if retry_count is None else retry_count
        for attempt in range(attempts + 1):
            response = None
            try:
                if method == "GET":
                    response = requests.get(
                        url,
                        headers=headers or self._device_headers(),
                        timeout=self.timeout,
                    )
                else:
                    response = requests.post(
                        url,
                        data=json.dumps(payload).encode("utf-8"),
                        headers=headers or self._device_headers(),
                        timeout=self.timeout,
                    )
                status_code = getattr(response, "status_code", getattr(response, "status", 500))
                body = self._response_body(response)
                if 200 <= status_code < 300 and body.get("success", True):
                    body.setdefault("http_status", status_code)
                    return body
                last_error = {
                    "success": False,
                    "status_code": status_code,
                    "response": body,
                }
                log("DEVICE API", "Server returned status %s" % status_code)
                if status_code in (400, 401, 403, 404, 409, 429):
                    break
            except Exception as exc:  # pragma: no cover - runtime dependent
                last_error = {"success": False, "error": str(exc)}
                log("DEVICE API", "Request failed: %s" % exc)
            finally:
                if response is not None and hasattr(response, "close"):
                    response.close()
            if attempt < attempts:
                time.sleep(1)
        return last_error or {"success": False, "message": "Unknown device API failure"}

    def poll_enrollment(self, device_id):
        endpoint = API_DEVICE_ENROLLMENT_PENDING.format(device_id=device_id)
        return self._device_request("GET", endpoint)

    def report_enrollment_status(
        self,
        device_id,
        enrollment_id,
        status,
        fingerprint_slot=None,
        error_code=None,
    ):
        endpoint = API_DEVICE_ENROLLMENT_RESULT.format(
            device_id=device_id,
            enrollment_id=enrollment_id,
        )
        payload = {"status": status}
        if fingerprint_slot is not None:
            payload["fingerprint_slot"] = fingerprint_slot
        if error_code is not None:
            payload["error_code"] = error_code
        return self._device_request("POST", endpoint, payload)
