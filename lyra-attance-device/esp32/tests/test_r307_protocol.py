import contextlib
import io
import struct
import unittest
from unittest.mock import patch

import fakes

from drivers.r307 import (
    R307,
    R307CommunicationError,
    R307FingerError,
    R307InvalidPacketError,
    R307TemplateError,
    R307TimeoutError,
)
from config import (
    R307_UART_READ_TIMEOUT_MS,
    UART_BAUDRATE,
    UART_ID,
    UART_RX_PIN,
    UART_TX_PIN,
)


def ack_packet(payload):
    packet_id = b"\x07"
    length = struct.pack(">H", len(payload) + 2)
    checksum = sum(packet_id + length + payload) & 0xFFFF
    return (
        b"\xEF\x01"
        + b"\xFF\xFF\xFF\xFF"
        + packet_id
        + length
        + payload
        + struct.pack(">H", checksum)
    )


class R307EnrollmentProtocolTests(unittest.TestCase):
    def setUp(self):
        self.sensor = R307()
        self.uart = self.sensor.uart

    def queue_ack(self, payload):
        self.uart.response.extend(ack_packet(payload))

    def queue_capacity(self, capacity):
        parameters = bytearray(17)
        parameters[0] = R307.STATUS_OK
        parameters[5:7] = struct.pack(">H", capacity)
        self.queue_ack(bytes(parameters))

    def queue_index_table(self, occupied_slots=(), page=0):
        bitmap = bytearray(R307.INDEX_TABLE_BYTE_COUNT)
        for slot in occupied_slots:
            if slot // R307.INDEX_PAGE_SIZE == page:
                page_index = slot % R307.INDEX_PAGE_SIZE
                bitmap[page_index // 8] |= 1 << (page_index % 8)
        self.queue_ack(bytes([R307.STATUS_OK]) + bytes(bitmap))

    def command_contents(self, packet):
        contents_length = struct.unpack(">H", packet[7:9])[0] - 2
        return packet[9:9 + contents_length]

    def test_uart_init_preserves_configured_pins_and_bounded_read_timeouts(self):
        self.assertEqual(self.uart.uart_id, UART_ID)
        self.assertEqual(self.uart.baudrate, UART_BAUDRATE)
        self.assertEqual(self.uart.init_args["baudrate"], UART_BAUDRATE)
        self.assertEqual(self.uart.init_args["tx"].pin, UART_TX_PIN)
        self.assertEqual(self.uart.init_args["rx"].pin, UART_RX_PIN)
        self.assertEqual(
            self.uart.init_args["timeout"],
            R307_UART_READ_TIMEOUT_MS,
        )
        self.assertEqual(
            self.uart.init_args["timeout_char"],
            R307_UART_READ_TIMEOUT_MS,
        )

    def test_verify_password_command_matches_expected_protocol_frame(self):
        self.queue_ack(b"\x00")

        self.assertTrue(self.sensor.verify_password(0))

        self.assertEqual(
            self.uart.writes[-1],
            bytes.fromhex("EF01FFFFFFFF0100071300000000001B"),
        )

    def test_search_status_nine_is_not_found_even_in_status_only_ack(self):
        self.queue_ack(b"\x09")

        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertIsNone(self.sensor.search(page_num=1000))

        self.assertIn("Search confirmation=0x09", output.getvalue())
        self.assertIn("fingerprint not found", output.getvalue())

    def test_get_image_status_two_means_no_finger(self):
        self.queue_ack(b"\x02")

        with self.assertRaises(R307FingerError):
            self.sensor.get_image()

    def test_get_image_collects_fragmented_uart_response(self):
        self.queue_ack(b"\x00")
        original_read = self.uart.read

        def read_in_fragments(size):
            return original_read(min(size, 2))

        self.uart.read = read_in_fragments

        self.assertTrue(self.sensor.get_image())
        self.assertEqual(self.uart.response, bytearray())

    def test_debug_logs_uart_availability_tx_rx_and_ack_confirmation(self):
        self.queue_ack(b"\x02")
        output = io.StringIO()

        with contextlib.redirect_stdout(output):
            with self.assertRaises(R307FingerError):
                self.sensor.get_image()

        logs = output.getvalue()
        self.assertIn("TX packet", logs)
        self.assertIn("UART any() before TX", logs)
        self.assertIn("UART any() after TX", logs)
        self.assertIn("RX chunk", logs)
        self.assertIn("confirmation=0x02", logs)
    def test_partial_uart_response_is_reported_on_timeout(self):
        self.uart.response.extend(b"\xEF\x01")
        self.sensor.timeout_ms = 10

        with self.assertRaises(R307TimeoutError) as error:
            self.sensor._read_exact(4, captured=bytearray())

        self.assertIn("expected=4 received=2", str(error.exception))
        self.assertEqual(error.exception.received_bytes, 2)
        self.assertEqual(error.exception.partial_data, b"\xEF\x01")

    def test_zero_byte_uart_timeout_is_explicitly_classified(self):
        self.sensor.timeout_ms = 10

        with self.assertRaises(R307TimeoutError) as error:
            self.sensor._read_packet()

        self.assertEqual(error.exception.received_bytes, 0)
        self.assertEqual(error.exception.partial_data, b"")

    def test_reader_resynchronizes_after_leading_noise_before_valid_packet(self):
        self.queue_ack(b"\x00")
        self.uart.response[:0] = b"\x00\xA5"

        self.assertTrue(self.sensor.verify_password(0))
        self.assertEqual(self.uart.response, bytearray())

    def test_reader_rejects_complete_packet_with_wrong_address(self):
        packet = bytearray(ack_packet(b"\x00"))
        packet[5] = 0xFE
        packet[-2:] = struct.pack(">H", sum(packet[6:-2]) & 0xFFFF)
        self.uart.response.extend(packet)

        with self.assertRaisesRegex(R307InvalidPacketError, "Invalid R307 address"):
            self.sensor._read_packet()

    def test_reader_rejects_complete_packet_with_bad_checksum(self):
        packet = bytearray(ack_packet(b"\x00"))
        packet[-1] ^= 0x01
        self.uart.response.extend(packet)

        with self.assertRaisesRegex(R307InvalidPacketError, "Checksum mismatch"):
            self.sensor._read_packet()

    def test_uart_loopback_requires_exact_echo_before_success(self):
        def echo(data):
            self.uart.response.extend(data)
            return len(data)

        self.uart.write = echo

        self.assertTrue(self.sensor.uart_loopback_test(timeout_ms=50))
        self.assertFalse(self.sensor._command_active)

    def test_uart_loopback_mismatch_is_a_failure_and_releases_lock(self):
        self.uart.write = lambda data: len(data)

        with self.assertRaisesRegex(R307CommunicationError, "loopback mismatch/timeout"):
            self.sensor.uart_loopback_test(timeout_ms=10)

        self.assertFalse(self.sensor._command_active)

    def test_rejects_concurrent_command_without_writing_uart(self):
        self.sensor._command_active = True
        self.sensor._active_command_id = R307.CMD_GET_IMAGE

        with self.assertRaisesRegex(
            R307CommunicationError,
            "Concurrent UART access rejected",
        ):
            self.sensor.get_image()

        self.assertEqual(self.uart.writes, [])

    def test_uart_read_oserror_is_normalized_to_communication_error(self):
        def fail_read(_size):
            raise OSError("UART unavailable")

        self.uart.read = fail_read
        with self.assertRaisesRegex(R307CommunicationError, "UART read failed"):
            self.sensor.get_image()

    def test_late_response_is_consumed_as_previous_packet_before_next_command(self):
        self.sensor.timeout_ms = 10
        self.sensor._previous_command_timed_out = True
        self.uart.response.extend(ack_packet(b"\x02"))

        with patch.object(
            self.sensor,
            "_read_packet",
            wraps=self.sensor._read_packet,
        ) as read_packet:
            with self.assertRaises(R307TimeoutError):
                self.sensor.get_image()

        self.assertEqual(self.uart.response, bytearray())
        self.assertTrue(self.sensor._previous_command_timed_out)
        self.assertEqual(read_packet.call_count, 2)
        self.assertEqual(len(self.uart.writes), 1)

    def test_store_command_includes_buffer_and_two_byte_slot(self):
        self.queue_capacity(256)
        self.queue_index_table()
        self.queue_ack(b"\x00")
        self.queue_index_table((1,))

        self.assertTrue(self.sensor.store_model(1, buffer_id=1))
        store_packet = next(
            packet for packet in self.uart.writes
            if self.command_contents(packet)[0] == R307.CMD_STORE_MODEL
        )
        contents = self.command_contents(store_packet)
        self.assertEqual(contents, b"\x06\x01\x00\x01")

    def test_free_slot_is_found_from_clear_index_table_bit(self):
        self.queue_capacity(256)
        self.queue_index_table((0, 1))

        self.assertEqual(self.sensor.find_free_template_slot(3, start_page=1), 2)
        self.assertEqual(self.command_contents(self.uart.writes[-1]), b"\x1F\x00")

    def test_free_slot_search_uses_capacity_and_index_table_pages(self):
        self.queue_capacity(300)
        self.queue_index_table(range(256), page=0)
        self.queue_index_table(page=1)

        self.assertEqual(self.sensor.find_free_template_slot(1000, start_page=255), 256)
        self.assertEqual(self.command_contents(self.uart.writes[-2]), b"\x1F\x00")
        self.assertEqual(self.command_contents(self.uart.writes[-1]), b"\x1F\x01")

    def test_index_table_detects_occupied_and_empty_slots(self):
        self.queue_index_table((7,))
        self.queue_index_table((7,))

        self.assertTrue(self.sensor.is_template_slot_occupied(7, template_capacity=256))
        self.assertFalse(self.sensor.is_template_slot_occupied(8, template_capacity=256))

    def test_index_table_rejects_invalid_page_and_out_of_range_slot(self):
        with self.assertRaisesRegex(R307TemplateError, "outside sensor capacity"):
            self.sensor.read_index_table(1, template_capacity=256)
        with self.assertRaisesRegex(R307TemplateError, "outside sensor capacity"):
            self.sensor.is_template_slot_occupied(256, template_capacity=256)

    def test_index_table_rejects_malformed_response_length(self):
        self.queue_ack(b"\x00" + bytes(R307.INDEX_TABLE_BYTE_COUNT - 1))

        with self.assertRaisesRegex(R307InvalidPacketError, "Index-table response"):
            self.sensor.read_index_table(0, template_capacity=256)

    def test_index_table_response_checksum_is_validated(self):
        packet = bytearray(
            ack_packet(bytes([R307.STATUS_OK]) + bytes(R307.INDEX_TABLE_BYTE_COUNT))
        )
        packet[-1] ^= 0x01
        self.uart.response.extend(packet)

        with self.assertRaisesRegex(R307InvalidPacketError, "Checksum mismatch"):
            self.sensor.read_index_table(0, template_capacity=256)

    def test_store_refuses_occupied_slot_before_sending_store_command(self):
        self.queue_capacity(256)
        self.queue_index_table((1,))

        with self.assertRaisesRegex(R307TemplateError, "Refusing to overwrite"):
            self.sensor.store_model(1)

        self.assertFalse(
            any(self.command_contents(packet)[0] == R307.CMD_STORE_MODEL for packet in self.uart.writes)
        )

    def test_store_requires_post_store_index_table_confirmation(self):
        self.queue_capacity(256)
        self.queue_index_table()
        self.queue_ack(b"\x00")
        self.queue_index_table()

        with self.assertRaisesRegex(R307TemplateError, "was not present in index table"):
            self.sensor.store_model(1)

    def test_free_slot_search_reports_full_sensor(self):
        self.queue_capacity(2)
        self.queue_index_table((0, 1))

        with self.assertRaisesRegex(R307TemplateError, "template store is full"):
            self.sensor.find_free_template_slot(2, start_page=1)

    def test_load_template_statuses_zero_b_and_zero_c_are_not_free_slots(self):
        for status in (0x0B, 0x0C):
            with self.subTest(status=status):
                self.queue_ack(bytes([status]))
                with self.assertRaisesRegex(R307TemplateError, "Template load failed"):
                    self.sensor.load_template(1, buffer_id=2)

    def test_create_model_includes_sensor_failure_status(self):
        self.queue_ack(b"\x0A")

        with self.assertRaisesRegex(R307TemplateError, "Model generation failed: 10"):
            self.sensor.create_model()

    def test_create_model_rejects_empty_status_response(self):
        self.queue_ack(b"")

        with self.assertRaises(R307InvalidPacketError):
            self.sensor.create_model()


if __name__ == "__main__":
    unittest.main()
