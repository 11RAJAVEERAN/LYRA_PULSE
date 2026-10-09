import struct
import unittest

import fakes

from drivers.r307 import R307, R307FingerError, R307InvalidPacketError, R307TemplateError


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

    def test_search_status_nine_is_not_found_even_in_status_only_ack(self):
        self.queue_ack(b"\x09")

        self.assertIsNone(self.sensor.search(page_num=1000))

    def test_get_image_status_two_means_no_finger(self):
        self.queue_ack(b"\x02")

        with self.assertRaises(R307FingerError):
            self.sensor.get_image()

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
