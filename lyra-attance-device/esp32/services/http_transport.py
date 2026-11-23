"""Small, explicit HTTP/1.1 transport for MicroPython device requests."""

import json
import socket


MAX_HEADER_BYTES = 8192
MAX_RESPONSE_BYTES = 65536
RECV_SIZE = 512


class HTTPResponse:
    def __init__(self, status, reason, headers, body):
        self.status = status
        self.status_code = status
        self.reason = reason
        self.headers = headers
        self._body = body

    def json(self):
        return json.loads(self._body.decode("utf-8"))

    def close(self):
        # The socket is closed after the full response is read.
        return None


class _SocketReader:
    def __init__(self, sock):
        self.sock = sock
        self.buffer = bytearray()

    def _receive(self):
        chunk = self.sock.recv(RECV_SIZE)
        if not chunk:
            return False
        self.buffer.extend(chunk)
        return True

    def read_until(self, marker, limit):
        while True:
            index = bytes(self.buffer).find(marker)
            if index >= 0:
                value = bytes(self.buffer[:index])
                del self.buffer[:index + len(marker)]
                return value
            if len(self.buffer) > limit:
                raise OSError("HTTP response header or line exceeds limit")
            if not self._receive():
                raise OSError("Connection closed before HTTP response was complete")

    def read_exact(self, count):
        if count < 0 or count > MAX_RESPONSE_BYTES:
            raise OSError("HTTP response body exceeds limit")
        while len(self.buffer) < count:
            if not self._receive():
                raise OSError("Connection closed during HTTP response body")
        value = bytes(self.buffer[:count])
        del self.buffer[:count]
        return value

    def read_to_eof(self, initial_size=0):
        result = bytearray(self.buffer)
        self.buffer = bytearray()
        if initial_size + len(result) > MAX_RESPONSE_BYTES:
            raise OSError("HTTP response body exceeds limit")
        while True:
            chunk = self.sock.recv(RECV_SIZE)
            if not chunk:
                return bytes(result)
            result.extend(chunk)
            if initial_size + len(result) > MAX_RESPONSE_BYTES:
                raise OSError("HTTP response body exceeds limit")


def _parse_url(url):
    if not isinstance(url, str) or "://" not in url:
        raise ValueError("HTTP URL must include a scheme and host")
    scheme, remainder = url.split("://", 1)
    scheme = scheme.lower()
    if scheme not in ("http", "https"):
        raise ValueError("Unsupported HTTP URL scheme: %s" % scheme)

    separators = [position for position in (remainder.find("/"), remainder.find("?")) if position >= 0]
    path_start = min(separators) if separators else -1
    if path_start < 0:
        authority = remainder
        target = "/"
    else:
        authority = remainder[:path_start]
        target = remainder[path_start:]
    if "#" in authority:
        raise ValueError("Invalid HTTP URL authority")
    if "@" in authority:
        authority = authority.rsplit("@", 1)[1]
    if not authority:
        raise ValueError("HTTP URL has no host")

    explicit_port = False
    if authority.startswith("["):
        end = authority.find("]")
        if end < 0:
            raise ValueError("Invalid IPv6 host in HTTP URL")
        host = authority[1:end]
        tail = authority[end + 1:]
        if tail:
            if not tail.startswith(":"):
                raise ValueError("Invalid port in HTTP URL")
            port = int(tail[1:])
            explicit_port = True
        else:
            port = 443 if scheme == "https" else 80
    elif authority.count(":") == 1:
        host, port_text = authority.rsplit(":", 1)
        port = int(port_text)
        explicit_port = True
    elif authority.count(":") > 1:
        raise ValueError("IPv6 hosts in HTTP URLs must use brackets")
    else:
        host = authority
        port = 443 if scheme == "https" else 80
    if not host or port < 1 or port > 65535:
        raise ValueError("Invalid HTTP URL host or port")

    target = target.split("#", 1)[0]
    if not target:
        target = "/"
    elif target.startswith("?"):
        target = "/" + target
    host_header = "[%s]" % host if ":" in host else host
    if explicit_port or port not in (80, 443):
        host_header += ":%d" % port
    return scheme, host, port, target, host_header


def _header_map(headers):
    result = {}
    for key, value in (headers or {}).items():
        name = str(key).strip()
        text = str(value).strip()
        if not name or "\r" in name or "\n" in name or ":" in name:
            raise ValueError("Invalid HTTP header name")
        if "\r" in text or "\n" in text:
            raise ValueError("Invalid HTTP header value")
        result[name.lower()] = (name, text)
    return result


def _read_response(reader, method):
    header_block = reader.read_until(b"\r\n\r\n", MAX_HEADER_BYTES)
    lines = header_block.split(b"\r\n")
    if not lines or not lines[0]:
        raise OSError("HTTP response did not contain a status line")
    status_parts = lines[0].split(None, 2)
    if len(status_parts) < 2 or not status_parts[0].startswith(b"HTTP/"):
        raise OSError("Invalid HTTP status line: %r" % lines[0])
    try:
        status = int(status_parts[1])
    except ValueError:
        raise OSError("Invalid HTTP status code: %r" % lines[0])
    reason = status_parts[2].decode("utf-8") if len(status_parts) > 2 else ""

    response_headers = {}
    for line in lines[1:]:
        if not line:
            continue
        if b":" not in line:
            raise OSError("Invalid HTTP response header")
        name, value = line.split(b":", 1)
        name = name.decode("utf-8").strip().lower()
        value = value.decode("utf-8").strip()
        if name in response_headers:
            response_headers[name] += ", " + value
        else:
            response_headers[name] = value

    body = b""
    transfer_encoding = response_headers.get("transfer-encoding", "").lower()
    if method != "HEAD" and status not in (204, 304) and not (100 <= status < 200):
        if "chunked" in transfer_encoding:
            chunks = bytearray()
            while True:
                size_line = reader.read_until(b"\r\n", 128)
                size_text = size_line.split(b";", 1)[0].strip()
                try:
                    size = int(size_text, 16)
                except ValueError:
                    raise OSError("Invalid chunk size in HTTP response")
                if size == 0:
                    while reader.read_until(b"\r\n", MAX_HEADER_BYTES):
                        pass
                    break
                chunks.extend(reader.read_exact(size))
                if reader.read_exact(2) != b"\r\n":
                    raise OSError("Invalid chunk terminator in HTTP response")
                if len(chunks) > MAX_RESPONSE_BYTES:
                    raise OSError("HTTP response body exceeds limit")
            body = bytes(chunks)
        elif "content-length" in response_headers:
            try:
                body_length = int(response_headers["content-length"])
            except ValueError:
                raise OSError("Invalid HTTP Content-Length")
            if body_length < 0 or body_length > MAX_RESPONSE_BYTES:
                raise OSError("HTTP response body exceeds limit")
            body = reader.read_exact(body_length)
        else:
            body = reader.read_to_eof()
    return HTTPResponse(status, reason, response_headers, body)


def _send_all(sock, payload):
    sent = 0
    while sent < len(payload):
        count = sock.send(payload[sent:])
        if count is None or count <= 0:
            raise OSError("Socket send made no progress")
        sent += count


def request(method, url, data=None, headers=None, timeout=10, requests_impl=None):
    """Send one HTTP request and return a response with a fully buffered body.

    HTTPS is delegated to the existing urequests implementation so its TLS
    behavior and certificate handling remain unchanged.
    """
    method = str(method).upper()
    scheme, host, port, target, host_header = _parse_url(url)
    if scheme == "https":
        if requests_impl is None:
            import urequests as requests_impl
        if method == "GET":
            return requests_impl.get(url, headers=headers or {}, timeout=timeout)
        return requests_impl.post(url, data=data, headers=headers or {}, timeout=timeout)

    if method not in ("GET", "POST", "PUT", "PATCH", "DELETE", "HEAD"):
        raise ValueError("Unsupported HTTP method: %s" % method)
    if data is None:
        body = b""
    elif isinstance(data, bytes):
        body = data
    else:
        body = str(data).encode("utf-8")

    fields = _header_map(headers)
    if "host" not in fields:
        fields["host"] = ("Host", host_header)
    if "connection" not in fields:
        fields["connection"] = ("Connection", "close")
    if data is not None and "content-length" not in fields:
        fields["content-length"] = ("Content-Length", str(len(body)))

    request_bytes = bytearray()
    request_bytes.extend(("%s %s HTTP/1.1\r\n" % (method, target)).encode("ascii"))
    for _lower_name, field in fields.items():
        request_bytes.extend(("%s: %s\r\n" % field).encode("utf-8"))
    request_bytes.extend(b"\r\n")
    request_bytes.extend(body)

    sock = None
    stage = "DNS lookup"
    try:
        address_info = socket.getaddrinfo(host, port, 0, socket.SOCK_STREAM)
        last_error = None
        stage = "TCP connect"
        for family, socktype, proto, _canonname, address in address_info:
            candidate = None
            try:
                candidate = socket.socket(family, socktype, proto)
                candidate.settimeout(timeout)
                candidate.connect(address)
                sock = candidate
                break
            except Exception as exc:
                last_error = exc
                if candidate is not None:
                    try:
                        candidate.close()
                    except Exception:
                        pass
        if sock is None:
            raise OSError("TCP connect failed: %s" % last_error)

        stage = "HTTP request send"
        _send_all(sock, request_bytes)
        stage = "HTTP response read"
        response = _read_response(_SocketReader(sock), method)
        return response
    except Exception as exc:
        if stage == "DNS lookup":
            raise OSError("HTTP DNS lookup failed: %s" % exc)
        if stage == "TCP connect":
            raise OSError("HTTP TCP connection failed: %s" % exc)
        if stage == "HTTP request send":
            raise OSError("HTTP request send failed: %s" % exc)
        raise OSError("HTTP response read failed: %s" % exc)
    finally:
        if sock is not None:
            try:
                sock.close()
            except Exception:
                pass
