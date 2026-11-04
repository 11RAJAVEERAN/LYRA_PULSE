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

from config import (
    R307_DEBUG,
    R307_PASSWORD,
    UART_BAUDRATE,
    UART_ID,
    UART_RX_PIN,
    UART_TX_PIN,
)


class R307PacketError(Exception):
    """Base exception for malformed or invalid R307 packet interactions."""


class R307TimeoutError(R307PacketError):
    """Raised when the sensor does not respond within the configured timeout."""


class R307CommunicationError(R307PacketError):
    """Raised for UART or packet-level communication issues."""


class R307InvalidPacketError(R307PacketError):
    """Raised when a response packet is malformed or fails checksum validation."""


class R307FingerError(R307PacketError):
    """Raised when the finger is absent from the sensor."""


class R307ImageError(R307PacketError):
    """Raised when the sensor cannot acquire a usable image."""


class R307TemplateError(R307PacketError):
    """Raised when a template operation fails."""


class R307:
    """MicroPython-friendly R307 driver.

    The driver follows the R307 UART packet format:
      - Header: 2 bytes (0xEF01)
    - Address: 4 bytes (default 0xFFFFFFFF)
      - Packet identifier: 1 byte
    - Length: 2 bytes (big-endian, including checksum)
    - Contents: command/confirmation code and parameters
    - Checksum: 2 bytes (big-endian)
    """

    HEADER = b"\xEF\x01"
    ADDRESS = b"\xFF\xFF\xFF\xFF"
    PID_COMMAND = 0x01
    PID_DATA = 0x02
    PID_ACK = 0x07
    PID_END = 0x08
    PID_ERROR = 0x01

    STATUS_OK = 0x00
    STATUS_NO_FINGER = 0x02
    STATUS_IMAGE_OK = 0x00
    STATUS_IMAGE_FAIL = 0x01
    STATUS_IMAGE_CONVERT_OK = 0x00
    STATUS_IMAGE_CONVERT_FAIL = 0x01
    STATUS_MATCH_FOUND = 0x00
    # R307 confirmation code for a search with no matching template.
    STATUS_MATCH_NOT_FOUND = 0x09
    STATUS_TIMEOUT = 0x08
    STATUS_INVALID_PACKET = 0x0E
    STATUS_COMM_ERROR = 0x0F
    STATUS_TEMPLATE_ERROR = 0x10

    # Common command IDs as defined by the R307 protocol.
    CMD_VERIFY_PASSWORD = 0x13
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
    CMD_READ_INDEX_TABLE = 0x001F
    CMD_READ_SYS_PARAM = 0x0F

    INDEX_PAGE_SIZE = 256
    INDEX_TABLE_BYTE_COUNT = INDEX_PAGE_SIZE // 8
    INDEX_TABLE_RESPONSE_SIZE = INDEX_TABLE_BYTE_COUNT + 1

    def __init__(
        self,
        uart_id=UART_ID,
        baudrate=UART_BAUDRATE,
        tx_pin=UART_TX_PIN,
        rx_pin=UART_RX_PIN,
        debug=R307_DEBUG,
    ):
        self.debug = debug
        self._command_active = False
        self._active_command_id = None
        self._previous_command_timed_out = False
        self.uart_id = uart_id
        self.baudrate = baudrate
        self.tx_pin = tx_pin
        self.rx_pin = rx_pin
        self.uart = None
        self.timeout_ms = 1500
        self.password = R307_PASSWORD
        try:
            self._initialize_uart()
        except R307CommunicationError as exc:
            self._log("UART initialization failed: %s" % exc)

    def _initialize_uart(self):
        try:
            uart = UART(self.uart_id, self.baudrate)
            uart.init(
                baudrate=self.baudrate,
                bits=8,
                parity=None,
                stop=1,
                tx=Pin(self.tx_pin, Pin.OUT),
                rx=Pin(self.rx_pin, Pin.IN),
            )
        except OSError as exc:
            self.uart = None
            raise R307CommunicationError("UART init failed: %s" % exc)
        self.uart = uart
        self._log(
            "UART initialized: id=%d baud=%d TX=GPIO%d RX=GPIO%d"
            % (self.uart_id, self.baudrate, self.tx_pin, self.rx_pin)
        )

    def begin(self):
        self.verify_password(self.password)
        return True

    def _hex(self, data):
        return "".join("%02X" % value for value in data)

    def _log(self, message):
        print("[%d] [R307] %s" % (time.ticks_ms(), message))

    def _checksum(self, frame):
        """Checksum is the 16-bit sum of all bytes in the frame excluding the checksum itself."""
        total = 0
        for value in frame:
            total += value
        return total & 0xFFFF

    def _log_uart_pending(self, stage, command_id):
        uart_any = getattr(self.uart, "any", None)
        if uart_any is None:
            if self.debug:
                self._log(
                    "UART any() unavailable at %s for command 0x%02X"
                    % (stage, command_id)
                )
            return
        try:
            pending = uart_any()
        except OSError as exc:
            raise R307CommunicationError(
                "UART any() failed at %s: %s" % (stage, exc)
            )
        if self.debug:
            self._log(
                "UART any() %s command=0x%02X pending=%d"
                % (stage, command_id, pending)
            )

    def _read_exact(self, size, timeout_ms=None, captured=None):
        timeout_ms = timeout_ms or self.timeout_ms
        started = time.ticks_ms()
        deadline = time.ticks_add(started, timeout_ms)
        data = bytearray()
        while len(data) < size:
            try:
                chunk = self.uart.read(size - len(data))
            except OSError as exc:
                raise R307CommunicationError("UART read failed: %s" % exc)
            if chunk is None:
                chunk = b""
            if chunk:
                data.extend(chunk)
                if captured is not None:
                    captured.extend(chunk)
                if self.debug:
                    elapsed = time.ticks_diff(time.ticks_ms(), started)
                    self._log(
                        "RX chunk (%d/%d bytes, %dms): %s"
                        % (len(data), size, elapsed, self._hex(chunk))
                    )
            if time.ticks_diff(deadline, time.ticks_ms()) <= 0:
                elapsed = time.ticks_diff(time.ticks_ms(), started)
                packet_bytes = captured if captured is not None else data
                raise R307TimeoutError(
                    "Timed out reading response field: expected=%d received=%d "
                    "after=%dms; field_rx=%s; packet_rx=%s"
                    % (
                        size,
                        len(data),
                        elapsed,
                        self._hex(data),
                        self._hex(packet_bytes),
                    )
                )
            time.sleep_ms(5)
        return bytes(data)

    def _read_packet(self):
        """Read and validate a full packet from the sensor."""
        received = bytearray()
        started = time.ticks_ms()
        try:
            header = self._read_exact(2, captured=received)
            if header != self.HEADER:
                raise R307InvalidPacketError("Invalid R307 header: %s" % header)

            address = self._read_exact(4, captured=received)
            if len(address) != 4 or address != self.ADDRESS:
                raise R307InvalidPacketError("Invalid R307 address: %s" % address)

            packet_id = self._read_exact(1, captured=received)
            length_bytes = self._read_exact(2, captured=received)
            length = struct.unpack(">H", length_bytes)[0]
            if length < 2:
                raise R307InvalidPacketError("Invalid R307 packet length: %s" % length)

            payload = self._read_exact(length - 2, captured=received)
            received_checksum = self._read_exact(2, captured=received)
            calc_checksum = struct.pack(">H", self._checksum(packet_id + length_bytes + payload))
            if received_checksum != calc_checksum:
                raise R307InvalidPacketError(
                    "Checksum mismatch: received=%s expected=%s"
                    % (self._hex(received_checksum), self._hex(calc_checksum))
                )

            packet = {
                "packet_id": packet_id[0],
                "length": length,
                "payload": payload,
                "checksum": received_checksum,
            }
        except R307TimeoutError:
            if self.debug:
                self._log(
                    "RX incomplete: expected packet field not complete; "
                    "received=%d bytes after %dms: %s"
                    % (
                        len(received),
                        time.ticks_diff(time.ticks_ms(), started),
                        self._hex(received),
                    )
                )
            raise
        except R307PacketError:
            if self.debug:
                self._log(
                    "RX malformed/invalid packet (%d bytes): %s"
                    % (len(received), self._hex(received))
                )
            raise

        if self.debug:
            self._log(
                "RX packet actual=%d bytes declared=%d bytes (%dms): %s"
                % (
                    len(received),
                    length + 9,
                    time.ticks_diff(time.ticks_ms(), started),
                    self._hex(received),
                )
            )
        return packet

    def _consume_late_response(self):
        """Consume a complete late packet before the next command, if present."""
        if not self._previous_command_timed_out:
            return

        uart_any = getattr(self.uart, "any", None)
        if uart_any is None:
            self._previous_command_timed_out = False
            return

        deadline = time.ticks_add(time.ticks_ms(), 250)
        while time.ticks_diff(deadline, time.ticks_ms()) > 0:
            try:
                available = uart_any()
            except OSError as exc:
                raise R307CommunicationError("UART availability check failed: %s" % exc)
            if available:
                try:
                    packet = self._read_packet()
                except R307PacketError as exc:
                    self._log(
                        "Late response after timeout was incomplete/invalid: %s"
                        % exc.__class__.__name__
                    )
                else:
                    confirmation = (
                        packet["payload"][0] if packet["payload"] else None
                    )
                    self._log(
                        "Consumed late packet from previous command: pid=0x%02X "
                        "confirmation=%s"
                        % (
                            packet["packet_id"],
                            "missing" if confirmation is None else "0x%02X" % confirmation,
                        )
                    )
                break
            time.sleep_ms(5)

        self._previous_command_timed_out = False

    def _send_packet(self, command_id, payload=b""):
        frame = bytearray()
        frame.extend(self.HEADER)
        frame.extend(self.ADDRESS)
        frame.extend(b"\x01")
        command = bytes([command_id]) + payload
        length = len(command) + 2
        frame.extend(struct.pack(">H", length))
        frame.extend(command)
        frame.extend(struct.pack(">H", self._checksum(frame[6:])))
        if self.debug:
            self._log("TX packet (%d bytes): %s" % (len(frame), self._hex(frame)))
        try:
            self.uart.write(frame)
        except OSError as exc:
            raise R307CommunicationError("UART write failed: %s" % exc)

    def _execute_command(self, command_id, payload=b"", expect_response=True):
        if self._command_active:
            message = "Concurrent UART access rejected: active=0x%02X requested=0x%02X" % (
                self._active_command_id,
                command_id,
            )
            self._log(message)
            raise R307CommunicationError(message)

        self._command_active = True
        self._active_command_id = command_id
        command_started = time.ticks_ms()
        try:
            if self.uart is None:
                self._initialize_uart()
            self._consume_late_response()
            if self.debug:
                self._log("Command 0x%02X started" % command_id)
            self._log_uart_pending("before TX", command_id)
            self._send_packet(command_id, payload)
            self._log_uart_pending("after TX", command_id)
            if not expect_response:
                return True
            if self.debug:
                self._log(
                    "Waiting up to %dms for command 0x%02X response"
                    % (self.timeout_ms, command_id)
                )
            packet = self._read_packet()
            if packet["packet_id"] != self.PID_ACK:
                self._log(
                    "Unexpected response packet ID=0x%02X for command 0x%02X"
                    % (packet["packet_id"], command_id)
                )
                raise R307InvalidPacketError(
                    "Unexpected R307 packet ID: %s" % packet["packet_id"]
                )
            confirmation = packet["payload"][0] if packet["payload"] else None
            if self.debug:
                self._log(
                    "ACK packet_id=0x%02X confirmation=%s checksum=valid"
                    % (
                        packet["packet_id"],
                        "missing" if confirmation is None else "0x%02X" % confirmation,
                    )
                )
            self._log_uart_pending("after RX", command_id)
            return packet
        except R307TimeoutError as exc:
            self._previous_command_timed_out = True
            self._log(
                "Command 0x%02X timed out after %dms: %s"
                % (
                    command_id,
                    time.ticks_diff(time.ticks_ms(), command_started),
                    exc,
                )
            )
            raise
        except R307InvalidPacketError as exc:
            self._log(
                "Command 0x%02X invalid response after %dms: %s"
                % (
                    command_id,
                    time.ticks_diff(time.ticks_ms(), command_started),
                    exc,
                )
            )
            raise
        finally:
            if self.debug:
                self._log("Command 0x%02X transaction complete" % command_id)
            self._active_command_id = None
            self._command_active = False

    def verify_password(self, password):
        payload = struct.pack(">I", password & 0xFFFFFFFF)
        response = self._execute_command(self.CMD_VERIFY_PASSWORD, payload)
        status = response["payload"][0]
        if status != self.STATUS_OK:
            raise R307CommunicationError("R307 password verification failed")
        return True

    def get_image(self):
        response = self._execute_command(self.CMD_GET_IMAGE)
        if not response["payload"]:
            raise R307InvalidPacketError("Image response did not include a status code")
        status = response["payload"][0]
        if status == self.STATUS_NO_FINGER:
            raise R307FingerError("No finger placed on sensor")
        if status != self.STATUS_IMAGE_OK:
            raise R307ImageError("Image acquisition failed: %s" % status)
        return True

    def image_to_template(self, buffer_id=1):
        if buffer_id not in (1, 2):
            raise ValueError("Character buffer must be 1 or 2")
        payload = bytes([buffer_id])
        response = self._execute_command(self.CMD_IMG2TZ, payload)
        if not response["payload"]:
            raise R307InvalidPacketError("Image conversion response did not include a status code")
        status = response["payload"][0]
        if status != self.STATUS_IMAGE_CONVERT_OK:
            raise R307TemplateError("Fingerprint image conversion failed")
        return True

    def search(self, buffer_id=1, start_page=0, page_num=100):
        payload = bytearray()
        payload.append(buffer_id)
        payload.extend(struct.pack(">H", start_page))
        payload.extend(struct.pack(">H", page_num))
        response = self._execute_command(self.CMD_SEARCH, bytes(payload))
        if not response["payload"]:
            raise R307TemplateError("Search response too short")
        status = response["payload"][0]
        if status == self.STATUS_MATCH_NOT_FOUND:
            return None
        if len(response["payload"]) < 5:
            raise R307TemplateError("Search response too short")
        if status != self.STATUS_MATCH_FOUND:
            raise R307TemplateError("Search failed: %s" % status)
        match_id = int.from_bytes(response["payload"][1:3], "big")
        score = int.from_bytes(response["payload"][3:5], "big")
        return {"fingerprint_id": match_id, "score": score}

    def get_template_count(self):
        response = self._execute_command(self.CMD_GET_TEMPLATE_COUNT)
        if len(response["payload"]) < 2:
            raise R307TemplateError("Template count payload missing")
        return int.from_bytes(response["payload"][0:2], "big")

    def create_model(self):
        response = self._execute_command(self.CMD_REG_MODEL)
        if not response["payload"]:
            raise R307InvalidPacketError("Model-generation response did not include a status code")
        status = response["payload"][0]
        if status != self.STATUS_OK:
            raise R307TemplateError("Model generation failed: %s" % status)
        return True

    def load_template(self, template_id, buffer_id=1):
        if buffer_id not in (1, 2):
            raise ValueError("Character buffer must be 1 or 2")
        payload = bytes([buffer_id]) + struct.pack(">H", template_id)
        response = self._execute_command(self.CMD_LOAD_MODEL, payload)
        if not response["payload"]:
            raise R307InvalidPacketError("Load-template response did not include a status code")
        status = response["payload"][0]
        if status != self.STATUS_OK:
            raise R307TemplateError(
                "Template load failed at slot %s: %s" % (template_id, status)
            )
        return True

    def get_template_capacity(self):
        parameters = self.read_syspara()
        if len(parameters) < 7:
            raise R307InvalidPacketError("System-parameter response is too short")
        status = parameters[0]
        if status != self.STATUS_OK:
            raise R307TemplateError("System-parameter read failed: %s" % status)
        capacity = int.from_bytes(parameters[5:7], "big")
        if capacity <= 0:
            raise R307TemplateError("Sensor reported invalid template capacity: %s" % capacity)
        return capacity

    def read_index_table(self, page, template_capacity=None):
        if template_capacity is None:
            template_capacity = self.get_template_capacity()
        if template_capacity <= 0:
            raise R307TemplateError("Sensor reported invalid template capacity: %s" % template_capacity)
        page_count = (template_capacity + self.INDEX_PAGE_SIZE - 1) // self.INDEX_PAGE_SIZE
        if page < 0 or page >= page_count:
            raise R307TemplateError("Template index page is outside sensor capacity: %s" % page)

        response = self._execute_command(
            self.CMD_READ_INDEX_TABLE,
            bytes([page]),
        )
        payload = response["payload"]
        if len(payload) != self.INDEX_TABLE_RESPONSE_SIZE:
            raise R307InvalidPacketError(
                "Index-table response must contain a status byte and %s bitmap bytes"
                % self.INDEX_TABLE_BYTE_COUNT
            )
        status = payload[0]
        if status != self.STATUS_OK:
            raise R307TemplateError("Index-table read failed for page %s: %s" % (page, status))
        return payload[1:]

    def is_template_slot_occupied(self, template_id, template_capacity=None):
        if template_capacity is None:
            template_capacity = self.get_template_capacity()
        if template_id < 0 or template_id >= template_capacity:
            raise R307TemplateError(
                "Template slot %s is outside sensor capacity %s"
                % (template_id, template_capacity)
            )
        page = template_id // self.INDEX_PAGE_SIZE
        bitmap = self.read_index_table(page, template_capacity=template_capacity)
        page_index = template_id % self.INDEX_PAGE_SIZE
        return bool(bitmap[page_index // 8] & (1 << (page_index % 8)))

    def find_free_template_slot(self, max_template_count, start_page=0, buffer_id=2):
        if max_template_count <= 0:
            raise ValueError("Maximum template count must be positive")
        if start_page < 0:
            raise ValueError("Starting template slot cannot be negative")
        if buffer_id not in (1, 2):
            raise ValueError("Character buffer must be 1 or 2")

        capacity = self.get_template_capacity()
        limit = min(max_template_count, capacity)
        bitmaps = {}
        for slot_range in (range(start_page, limit), range(0, min(start_page, limit))):
            for template_id in slot_range:
                page = template_id // self.INDEX_PAGE_SIZE
                if page not in bitmaps:
                    bitmaps[page] = self.read_index_table(
                        page,
                        template_capacity=capacity,
                    )
                page_index = template_id % self.INDEX_PAGE_SIZE
                occupied = bitmaps[page][page_index // 8] & (1 << (page_index % 8))
                if not occupied:
                    return template_id
        raise R307TemplateError("Sensor template store is full")

    def store_model(self, template_id, buffer_id=1):
        if buffer_id not in (1, 2):
            raise ValueError("Character buffer must be 1 or 2")
        capacity = self.get_template_capacity()
        if template_id < 0 or template_id >= capacity:
            raise R307TemplateError(
                "Template slot %s is outside sensor capacity %s"
                % (template_id, capacity)
            )
        if self.is_template_slot_occupied(template_id, template_capacity=capacity):
            raise R307TemplateError("Refusing to overwrite occupied template slot %s" % template_id)

        payload = bytes([buffer_id]) + struct.pack(">H", template_id)
        response = self._execute_command(self.CMD_STORE_MODEL, payload)
        if not response["payload"]:
            raise R307InvalidPacketError("Store-template response did not include a status code")
        status = response["payload"][0]
        if status != self.STATUS_OK:
            raise R307TemplateError("Model storage failed")
        if not self.is_template_slot_occupied(template_id, template_capacity=capacity):
            raise R307TemplateError(
                "Stored template was not present in index table at slot %s" % template_id
            )
        return True

    def delete_template(self, template_id):
        payload = struct.pack(">H", template_id)
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
