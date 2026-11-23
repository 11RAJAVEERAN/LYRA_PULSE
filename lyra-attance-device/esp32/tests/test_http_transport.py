import unittest
from unittest.mock import patch

from services import http_transport


class FakeSocket:
    def __init__(self, response):
        self.response = bytearray(response)
        self.sent = bytearray()
        self.closed = False
        self.timeout = None

    def settimeout(self, timeout):
        self.timeout = timeout

    def connect(self, address):
        self.address = address

    def send(self, payload):
        count = min(5, len(payload))
        self.sent.extend(payload[:count])
        return count

    def recv(self, count):
        if not self.response:
            return b""
        count = min(count, 7, len(self.response))
        result = bytes(self.response[:count])
        del self.response[:count]
        return result

    def close(self):
        self.closed = True


class ReadFailureSocket(FakeSocket):
    def recv(self, count):
        raise OSError("simulated read failure")


class NoSliceDeleteBytearray(bytearray):
    """Approximate the MicroPython bytearray limitation seen on the device."""

    def __delitem__(self, key):
        raise TypeError("'bytearray' object doesn't support item deletion")


class HTTPTransportTests(unittest.TestCase):
    def run_with_socket(self, response, method, url, data=None, headers=None):
        fake = FakeSocket(response)
        with (
            patch.object(
                http_transport.socket,
                "getaddrinfo",
                return_value=[(2, 1, 6, "", ("192.168.1.105", 8000))],
            ),
            patch.object(http_transport.socket, "socket", return_value=fake),
        ):
            result = http_transport.request(
                method,
                url,
                data=data,
                headers=headers,
                timeout=3,
            )
        return result, fake

    def test_post_sends_all_bytes_and_reads_fragmented_content_length_response(self):
        response_body = b'{"success":true,"data":{"status":"SUCCESS"}}'
        response = (
            b"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
            + b"Content-Length: " + str(len(response_body)).encode("ascii")
            + b"\r\nConnection: close\r\n\r\n" + response_body
        )
        result, fake = self.run_with_socket(
            response,
            "POST",
            "http://192.168.1.105:8000/api/v1/devices/ESP32/heartbeat/",
            data=b"{}",
            headers={"Content-Type": "application/json", "Authorization": "Device token"},
        )

        request = bytes(fake.sent)
        self.assertTrue(request.startswith(b"POST /api/v1/devices/ESP32/heartbeat/ HTTP/1.1\r\n"))
        self.assertIn(b"Host: 192.168.1.105:8000\r\n", request)
        self.assertIn(b"Content-Length: 2\r\n", request)
        self.assertIn(b"Authorization: Device token\r\n", request)
        self.assertTrue(request.endswith(b"\r\n\r\n{}"))
        self.assertEqual(result.status_code, 200)
        self.assertEqual(result.json()["data"]["status"], "SUCCESS")
        self.assertTrue(fake.closed)

    def test_get_reads_chunked_response_and_trailers(self):
        response = (
            b"HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n"
            b"Connection: close\r\n\r\n"
            b"9\r\n{\"success\r\n"
            b"7\r\n\":true}\r\n"
            b"0\r\nX-Trace: done\r\n\r\n"
        )
        result, fake = self.run_with_socket(
            response,
            "GET",
            "http://192.168.1.105:8000/api/v1/devices/ESP32/enrollment/pending/",
        )

        request = bytes(fake.sent)
        self.assertTrue(request.startswith(b"GET /api/v1/devices/ESP32/enrollment/pending/ HTTP/1.1\r\n"))
        self.assertEqual(result.json(), {"success": True})
        self.assertTrue(fake.closed)

    def test_get_reads_fragmented_content_length_without_bytearray_deletion(self):
        response_body = (
            b'{"success":true,"data":{"employee_id":123,"status":"WAITING_FOR_FINGER",'
            b'"details":"' + (b"x" * 1024) + b'"}}'
        )
        response = (
            b"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n"
            + b"Content-Length: " + str(len(response_body)).encode("ascii")
            + b"\r\nConnection: close\r\n\r\n" + response_body
        )
        fake = FakeSocket(response)
        with (
            patch.object(http_transport, "bytearray", NoSliceDeleteBytearray, create=True),
            patch.object(
                http_transport.socket,
                "getaddrinfo",
                return_value=[(2, 1, 6, "", ("192.168.1.105", 8000))],
            ),
            patch.object(http_transport.socket, "socket", return_value=fake),
        ):
            result = http_transport.request(
                "GET",
                "http://192.168.1.105:8000/api/v1/devices/ESP32/enrollment/pending/",
                timeout=3,
            )

        self.assertEqual(result.json(), {
            "success": True,
            "data": {
                "employee_id": 123,
                "status": "WAITING_FOR_FINGER",
                "details": "x" * 1024,
            },
        })
        self.assertTrue(fake.closed)

    def test_socket_is_closed_when_response_read_fails(self):
        fake = ReadFailureSocket(b"")
        with (
            patch.object(
                http_transport.socket,
                "getaddrinfo",
                return_value=[(2, 1, 6, "", ("192.168.1.105", 8000))],
            ),
            patch.object(http_transport.socket, "socket", return_value=fake),
        ):
            with self.assertRaisesRegex(OSError, "HTTP response read failed"):
                http_transport.request(
                    "GET",
                    "http://192.168.1.105:8000/api/v1/devices/ESP32/enrollment/pending/",
                    timeout=3,
                )
        self.assertTrue(fake.closed)


if __name__ == "__main__":
    unittest.main()
