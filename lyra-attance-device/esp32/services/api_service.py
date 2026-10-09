"""HTTP client for posting attendance events to the configured Django backend."""

import json
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


class AttendanceAPIClient:
    def __init__(self, base_url=API_BASE_URL, timeout=API_TIMEOUT, retry_count=API_RETRY_COUNT):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self.retry_count = retry_count

    def _endpoint(self):
        return self.base_url + API_FINGERPRINT_ENDPOINT

    def send_attendance(self, device_id, fingerprint_slot):
        payload = {
            "device_id": device_id,
            "fingerprint_slot": fingerprint_slot,
        }
        headers = {"Content-Type": "application/json"}
        if DEVICE_TOKEN:
            headers["Authorization"] = "Bearer %s" % DEVICE_TOKEN

        headers = self._device_headers()
        last_error = None
        for attempt in range(self.retry_count + 1):
            try:
                log("API", "Submitting attendance event (attempt %s)" % (attempt + 1))
                response = requests.post(
                    self._endpoint(),
                    data=json.dumps(payload).encode("utf-8"),
                    headers=headers,
                    timeout=self.timeout,
                )
                status_code = getattr(response, "status_code", getattr(response, "status", 500))

                if status_code in (200, 201):
                    data = response.json() if hasattr(response, "json") else {}
                    if isinstance(data, dict):
                        return data
                    return {"success": True, "data": data}

                body = response.json() if hasattr(response, "json") else {}
                err = {"success": False, "status_code": status_code, "response": body}
                last_error = err
                log("API", "Server returned status %s" % status_code)

                if status_code in (400, 401, 403, 404, 409, 429):
                    break

            except Exception as exc:  # pragma: no cover - runtime dependent
                last_error = {"success": False, "error": str(exc)}
                log("API", "Request failed: %s" % exc)

            time.sleep(1)

        if last_error is not None:
            return last_error
        return {"success": False, "message": "Unknown API failure"}

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

    def _device_request(self, method, endpoint, payload=None):
        url = self.base_url + endpoint
        last_error = None
        for attempt in range(self.retry_count + 1):
            response = None
            try:
                if method == "GET":
                    response = requests.get(url, headers=self._device_headers(), timeout=self.timeout)
                else:
                    response = requests.post(
                        url,
                        data=json.dumps(payload).encode("utf-8"),
                        headers=self._device_headers(),
                        timeout=self.timeout,
                    )
                status_code = getattr(response, "status_code", getattr(response, "status", 500))
                body = self._response_body(response)
                if 200 <= status_code < 300 and body.get("success", True):
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
            if attempt < self.retry_count:
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
