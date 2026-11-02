import unittest

from services import api_diagnostic


class FakeSocket:
    def __init__(self, response=b"HTTP/1.1 401 Unauthorized\r\n\r\n"):
        self.response = response
        self.request = b""
        self.timeout = None
        self.connected_to = None
        self.closed = False
        self.connect_error = None
        self.recv_error = None
        self.send_limit = None

    def settimeout(self, timeout):
        self.timeout = timeout

    def connect(self, address):
        self.connected_to = address
        if self.connect_error:
            raise self.connect_error

    def send(self, payload):
        written = min(len(payload), self.send_limit or len(payload))
        self.request += payload[:written]
        return written

    def recv(self, _size):
        if self.recv_error:
            raise self.recv_error
        response = self.response
        self.response = b""
        return response

    def close(self):
        self.closed = True


class FakeSocketModule:
    SOCK_STREAM = 1

    def __init__(self, fake_socket):
        self.fake_socket = fake_socket
        self.resolved = None

    def getaddrinfo(self, host, port, _family, socktype):
        self.resolved = (host, port, socktype)
        return [(2, socktype, 6, "", (host, port))]

    def socket(self, _family, _socktype, _proto):
        return self.fake_socket


class AttendanceApiDiagnosticTests(unittest.TestCase):
    def setUp(self):
        self.previous_socket = api_diagnostic.socket
        self.previous_log = api_diagnostic.log
        self.logs = []

    def tearDown(self):
        api_diagnostic.socket = self.previous_socket
        api_diagnostic.log = self.previous_log

    def install_socket(self, fake_socket):
        fake_module = FakeSocketModule(fake_socket)
        api_diagnostic.socket = fake_module
        api_diagnostic.log = lambda category, message: self.logs.append(
            (category, message)
        )
        return fake_module

    def test_sends_only_unauthenticated_get_and_closes_socket(self):
        fake_socket = FakeSocket()
        fake_socket.send_limit = 7
        fake_module = self.install_socket(fake_socket)

        result = api_diagnostic.diagnose_attendance_connectivity(
            "http://192.168.1.11:8000",
            timeout_seconds=1,
        )

        self.assertTrue(result["tcp_connected"])
        self.assertEqual(result["http_status"], 401)
        self.assertIsNone(result["error"])
        self.assertEqual(
            fake_module.resolved,
            ("192.168.1.11", 8000, fake_module.SOCK_STREAM),
        )
        self.assertEqual(fake_socket.connected_to, ("192.168.1.11", 8000))
        self.assertEqual(fake_socket.timeout, 1)
        self.assertTrue(fake_socket.closed)
        self.assertIn(b"GET /api/v1/attendance/ HTTP/1.1", fake_socket.request)
        self.assertIn(b"Connection: close", fake_socket.request)
        self.assertNotIn(b"Authorization:", fake_socket.request)
        self.assertNotIn(b"POST ", fake_socket.request)
        self.assertTrue(any("HTTP 401" in message for _, message in self.logs))

    def test_tcp_connection_error_is_reported_and_socket_closed(self):
        fake_socket = FakeSocket()
        fake_socket.connect_error = OSError("connection refused")
        self.install_socket(fake_socket)

        result = api_diagnostic.diagnose_attendance_connectivity(
            "http://192.168.1.11:8000",
            timeout_seconds=1,
        )

        self.assertFalse(result["tcp_connected"])
        self.assertIsNone(result["http_status"])
        self.assertIn("connection refused", result["error"])
        self.assertTrue(fake_socket.closed)
        self.assertEqual(fake_socket.request, b"")

    def test_http_timeout_is_reported_and_socket_closed(self):
        fake_socket = FakeSocket()
        fake_socket.recv_error = OSError("response timed out")
        self.install_socket(fake_socket)

        result = api_diagnostic.diagnose_attendance_connectivity(
            "http://192.168.1.11:8000",
            timeout_seconds=1,
        )

        self.assertTrue(result["tcp_connected"])
        self.assertIsNone(result["http_status"])
        self.assertIn("response timed out", result["error"])
        self.assertTrue(fake_socket.closed)
        self.assertNotIn(b"Authorization:", fake_socket.request)

    def test_https_is_rejected_without_opening_a_socket(self):
        fake_socket = FakeSocket()
        fake_module = self.install_socket(fake_socket)

        result = api_diagnostic.diagnose_attendance_connectivity(
            "https://192.168.1.11:8000",
            timeout_seconds=1,
        )

        self.assertFalse(result["tcp_connected"])
        self.assertIn("http://", result["error"])
        self.assertIsNone(fake_module.resolved)
        self.assertFalse(fake_socket.closed)


if __name__ == "__main__":
    unittest.main()
