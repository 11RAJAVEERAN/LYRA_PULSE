"""Read-only network diagnostics for the configured Django attendance API."""

import socket

from config import API_BASE_URL
from utils.logger import log

ATTENDANCE_ENDPOINT = "/api/v1/attendance/"
DEFAULT_TIMEOUT_SECONDS = 2


def diagnose_attendance_connectivity(
    base_url=API_BASE_URL,
    timeout_seconds=DEFAULT_TIMEOUT_SECONDS,
):
    """Test TCP and an unauthenticated GET without invoking production API code."""
    result = {
        "tcp_connected": False,
        "http_status": None,
        "error": None,
    }
    sock = None
    try:
        if not base_url.startswith("http://"):
            raise ValueError("Diagnostic supports only the configured http:// URL")

        authority = base_url[len("http://"):].split("/", 1)[0]
        host, separator, port_text = authority.rpartition(":")
        if not separator:
            host = authority
            port = 80
        else:
            port = int(port_text)
        if not host:
            raise ValueError("API base URL has no host")

        log(
            "API DIAGNOSTIC",
            "Resolving host=%s port=%d timeout=%ss"
            % (host, port, timeout_seconds),
        )
        address_info = socket.getaddrinfo(
            host,
            port,
            0,
            socket.SOCK_STREAM,
        )[0]
        family, socktype, proto, _canonname, address = address_info
        sock = socket.socket(family, socktype, proto)
        sock.settimeout(timeout_seconds)
        sock.connect(address)
        result["tcp_connected"] = True
        log("API DIAGNOSTIC", "TCP connection established")

        request = (
            "GET %s HTTP/1.1\r\n"
            "Host: %s:%d\r\n"
            "Accept: */*\r\n"
            "Connection: close\r\n"
            "\r\n"
        ) % (ATTENDANCE_ENDPOINT, host, port)
        request = request.encode("ascii")
        sent = 0
        while sent < len(request):
            written = sock.send(request[sent:])
            if written <= 0:
                raise OSError("HTTP request send made no progress")
            sent += written

        response = bytearray()
        while b"\r\n" not in response and len(response) < 512:
            chunk = sock.recv(min(128, 512 - len(response)))
            if not chunk:
                break
            response.extend(chunk)
        status_line = bytes(response).split(b"\r\n", 1)[0]
        parts = status_line.split()
        if len(parts) < 2 or not parts[0].startswith(b"HTTP/"):
            raise OSError("Invalid or missing HTTP status line: %r" % status_line)
        result["http_status"] = int(parts[1])
        log(
            "API DIAGNOSTIC",
            "Unauthenticated GET %s returned HTTP %d"
            % (ATTENDANCE_ENDPOINT, result["http_status"]),
        )
    except Exception as exc:
        result["error"] = "%s: %s" % (exc.__class__.__name__, exc)
        log("API DIAGNOSTIC ERROR", result["error"])
    finally:
        if sock is not None:
            try:
                sock.close()
                log("API DIAGNOSTIC", "Socket closed")
            except Exception as exc:
                close_error = "Socket close failed: %s: %s" % (
                    exc.__class__.__name__,
                    exc,
                )
                result["error"] = (
                    "%s; %s" % (result["error"], close_error)
                    if result["error"]
                    else close_error
                )
                log("API DIAGNOSTIC ERROR", close_error)
    return result
