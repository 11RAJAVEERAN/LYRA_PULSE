"""R307 / R307S fingerprint sensor driver with packet parsing and validation."""

import struct

try:
    import utime as time
except ImportError:  # pragma: no cover - CPython local compatibility
    import time as _time

    class _CompatTime:
        @staticmethod
        def ticks_ms():
            return int(_time.time() * 1000)

        @staticmethod
        def ticks_add(ticks, delta):
            return ticks + delta

        @staticmethod
        def ticks_diff(end, start):
            return end - start

        @staticmethod
        def sleep_ms(ms):
            _time.sleep(ms / 1000)

    time = _CompatTime()

from machine import UART, Pin

from config import R307_PASSWORD, UART_BAUDRATE, UART_ID, UART_RX_PIN, UART_TX_PIN


class R307PacketError(Exception):
    """Base exception for malformed or invalid R307 packet interactions."""


class R307TimeoutError(R307PacketError):
    """Raised when the sensor does not respond within the configured timeout."""


class R307CommunicationError(R307PacketError):
    """Raised for UART or packet-level communication issues."""


class R307InvalidPacketError(R307PacketError):
    """Raised when a response packet is malformed or fails checksum validation."""


class R307FingerError(R307PacketError):
    """Raised when the finger is absent or image acquisition fails."""


class R307TemplateError(R307PacketError):
    """Raised when a template operation fails."""


class R307:
    """MicroPython-friendly R307 driver.

    The driver follows the R307 UART packet format:
      - Header: 2 bytes (0xEF01)
      - Address: 1 byte (0xFF)
      - Packet identifier: 1 byte
      - Length: 2 bytes (little-endian)
      - Payload: length bytes
      - Checksum: 2 bytes
    """

    HEADER = b"\xEF\x01"
    ADDRESS = b"\xFF"
    PID_COMMAND = 0x01
    PID_DATA = 0x02
    PID_ACK = 0x07
    PID_END = 0x08
    PID_ERROR = 0x01

    STATUS_OK = 0x00
    STATUS_NO_FINGER = 0x01
    STATUS_IMAGE_OK = 0x00
    STATUS_IMAGE_FAIL = 0x01
    STATUS_IMAGE_CONVERT_OK = 0x00
    STATUS_IMAGE_CONVERT_FAIL = 0x01
    STATUS_MATCH_FOUND = 0x00
    STATUS_MATCH_NOT_FOUND = 0x01
    STATUS_TIMEOUT = 0x08
    STATUS_INVALID_PACKET = 0x0E
    STATUS_COMM_ERROR = 0x0F
    STATUS_TEMPLATE_ERROR = 0x10

    # Common command IDs as defined by the R307 protocol.
    CMD_VERIFY_PASSWORD = 0x0007
    CMD_GET_IMAGE = 0x0001
    CMD_IMG2TZ = 0x0002
    CMD_SEARCH = 0x0004
    CMD_REG_MODEL = 0x0005
    CMD_STORE_MODEL = 0x0006
    CMD_LOAD_MODEL = 0x0007
    CMD_UP_CHAR = 0x0008
    CMD_DOWN_CHAR = 0x0009
    CMD_EMPTY_DATABASE = 0x000D
    CMD_DELETE_MODEL = 0x000C
    CMD_GET_TEMPLATE_COUNT = 0x001D
    CMD_READ_SYS_PARAM = 0x002B

    def __init__(self, uart_id=UART_ID, baudrate=UART_BAUDRATE, tx_pin=UART_TX_PIN, rx_pin=UART_RX_PIN):
        self.uart = UART(uart_id, baudrate)
        self.uart.init(baudrate=baudrate, bits=8, parity=None, stop=1, tx=Pin(tx_pin, Pin.OUT), rx=Pin(rx_pin, Pin.IN))
        self.timeout_ms = 1500
        self.password = R307_PASSWORD

    def begin(self):
        self.uart.init(baudrate=UART_BAUDRATE, bits=8, parity=None, stop=1)
        self.verify_password(self.password)
        return True

    def _checksum(self, frame):
        """Checksum is the 16-bit sum of all bytes in the frame excluding the checksum itself."""
        total = 0
        for value in frame:
            total += value
        return total & 0xFFFF

    def _read_exact(self, size, timeout_ms=None):
        deadline = time.ticks_add(time.ticks_ms(), timeout_ms or self.timeout_ms)
        data = bytearray()
        while len(data) < size:
            chunk = self.uart.read(size - len(data))
            if chunk is None:
                chunk = b""
            if chunk:
                data.extend(chunk)
            if time.ticks_diff(deadline, time.ticks_ms()) <= 0:
                raise R307TimeoutError("Timed out while reading R307 response")
            time.sleep_ms(5)
        return bytes(data)

    def _read_packet(self):
        """Read and validate a full packet from the sensor."""
        try:
            header = self._read_exact(2)
        except R307TimeoutError:
            raise
        if header != self.HEADER:
            raise R307InvalidPacketError("Invalid R307 header: %s" % header)

        address = self._read_exact(1)
        if len(address) != 1 or address != self.ADDRESS:
            raise R307InvalidPacketError("Invalid R307 address: %s" % address)

        packet_id = self._read_exact(1)
        if len(packet_id) != 1:
            raise R307InvalidPacketError("Missing packet identifier")

        length_bytes = self._read_exact(2)
        length = struct.unpack("<H", length_bytes)[0]
        payload = self._read_exact(length)

        received_checksum = self._read_exact(2)
        calc_checksum = struct.pack("<H", self._checksum(self.HEADER + self.ADDRESS + packet_id + length_bytes + payload))

        if received_checksum != calc_checksum:
            raise R307InvalidPacketError("Checksum mismatch in R307 packet")

        return {"packet_id": packet_id[0], "length": length, "payload": payload, "checksum": received_checksum}

    def _send_packet(self, command_id, payload=b""):
        frame = bytearray()
        frame.extend(self.HEADER)
        frame.extend(self.ADDRESS)
        frame.extend(b"\x01")
        length = 2 + len(payload)
        frame.extend(struct.pack("<H", length))
        frame.extend(struct.pack("<H", command_id))
        if payload:
            frame.extend(payload)
        frame.extend(struct.pack("<H", self._checksum(frame[2:])))
        self.uart.write(frame)

    def _execute_command(self, command_id, payload=b"", expect_response=True):
        self._send_packet(command_id, payload)
        if not expect_response:
            return True
        packet = self._read_packet()
        return packet

    def verify_password(self, password):
        payload = struct.pack("<I", password & 0xFFFFFFFF)
        response = self._execute_command(self.CMD_VERIFY_PASSWORD, payload)
        status = response["payload"][0]
        if status != self.STATUS_OK:
            raise R307CommunicationError("R307 password verification failed")
        return True

    def get_image(self):
        response = self._execute_command(self.CMD_GET_IMAGE)
        status = response["payload"][0]
        if status == self.STATUS_NO_FINGER:
            raise R307FingerError("No finger placed on sensor")
        if status != self.STATUS_IMAGE_OK:
            raise R307FingerError("Image acquisition failed")
        return True

    def image_to_template(self, buffer_id=1):
        payload = bytes([buffer_id])
        response = self._execute_command(self.CMD_IMG2TZ, payload)
        status = response["payload"][0]
        if status != self.STATUS_IMAGE_CONVERT_OK:
            raise R307TemplateError("Fingerprint image conversion failed")
        return True

    def search(self, buffer_id=1, start_page=0, page_num=100):
        payload = bytearray()
        payload.append(buffer_id)
        payload.extend(struct.pack("<H", start_page))
        payload.extend(struct.pack("<H", page_num))
        response = self._execute_command(self.CMD_SEARCH, bytes(payload))
        if len(response["payload"]) < 5:
            raise R307TemplateError("Search response too short")
        status = response["payload"][0]
        if status == self.STATUS_MATCH_NOT_FOUND:
            return None
        if status != self.STATUS_MATCH_FOUND:
            raise R307TemplateError("Search failed: %s" % status)
        match_id = int.from_bytes(response["payload"][1:3], "little")
        score = int.from_bytes(response["payload"][3:5], "little")
        return {"fingerprint_id": match_id, "score": score}

    def get_template_count(self):
        response = self._execute_command(self.CMD_GET_TEMPLATE_COUNT)
        if len(response["payload"]) < 2:
            raise R307TemplateError("Template count payload missing")
        return int.from_bytes(response["payload"][0:2], "little")

    def create_model(self):
        response = self._execute_command(self.CMD_REG_MODEL)
        status = response["payload"][0]
        if status != self.STATUS_OK:
            raise R307TemplateError("Model generation failed")
        return True

    def store_model(self, template_id):
        payload = struct.pack("<H", template_id)
        response = self._execute_command(self.CMD_STORE_MODEL, payload)
        status = response["payload"][0]
        if status != self.STATUS_OK:
            raise R307TemplateError("Model storage failed")
        return True

    def delete_template(self, template_id):
        payload = struct.pack("<H", template_id)
        response = self._execute_command(self.CMD_DELETE_MODEL, payload)
        status = response["payload"][0]
        if status != self.STATUS_OK:
            raise R307TemplateError("Template deletion failed")
        return True

    def empty_database(self):
        response = self._execute_command(self.CMD_EMPTY_DATABASE)
        status = response["payload"][0]
        if status != self.STATUS_OK:
            raise R307TemplateError("Database empty operation failed")
        return True

    def read_syspara(self):
        response = self._execute_command(self.CMD_READ_SYS_PARAM)
        return response["payload"]
