import sys
import types
import unittest
from unittest.mock import patch

import fakes

micropython = types.ModuleType("micropython")
micropython.const = lambda value: value
sys.modules.setdefault("micropython", micropython)

from config import BLUE_LED_PIN, BUZZER_PIN, GREEN_LED_PIN, RED_LED_PIN
from hardware.buzzer import Buzzer
from hardware.status_led import StatusLed
import drivers.oled as oled_module
from drivers.oled import OledDisplay
from lib.font5x8 import FONT
from lib.ssd1306 import SSD1306_I2C


class FakeDisplay:
    def __init__(self):
        self.lines = []
        self.entries = []
        self.fill_count = 0
        self.show_count = 0

    def fill(self, _color):
        self.fill_count += 1

    def text(self, text, _x, _y):
        self.lines.append(text)
        self.entries.append((text, _x, _y))

    def show(self):
        self.show_count += 1


class DeviceHardwareStatusTests(unittest.TestCase):
    def test_ready_match_and_no_match_led_states_are_exclusive(self):
        leds = StatusLed()
        blue = fakes.FakePin.instances[BLUE_LED_PIN]
        green = fakes.FakePin.instances[GREEN_LED_PIN]
        red = fakes.FakePin.instances[RED_LED_PIN]

        leds.ready_status()
        self.assertEqual((blue.state, green.state, red.state), (1, 0, 0))

        leds.match_success()
        self.assertEqual((blue.state, green.state, red.state), (0, 1, 0))

        leds.match_failed()
        self.assertEqual((blue.state, green.state, red.state), (0, 0, 1))

        leds.api_error()
        self.assertEqual((blue.state, green.state, red.state), (0, 0, 0))

    def test_beep_once_and_twice_have_exact_pulse_counts_and_finish_off(self):
        buzzer = Buzzer()
        pin = fakes.FakePin.instances[BUZZER_PIN]

        with patch("hardware.buzzer.time.sleep"):
            pin.history = []
            buzzer.beep_once()
            self.assertEqual(pin.history, [1, 0])
            self.assertEqual(pin.state, 0)

            pin.history = []
            buzzer.beep_twice()
            self.assertEqual(pin.history, [1, 0, 1, 0])
            self.assertEqual(pin.state, 0)

    def test_buzzer_feedback_uses_audible_pulse_and_gap_durations(self):
        buzzer = Buzzer()
        with patch("hardware.buzzer.time.sleep") as sleep:
            buzzer.beep_once()
            self.assertEqual(sleep.call_args_list[-1].args, (0.18,))
            sleep.reset_mock()
            buzzer.beep_twice()

        self.assertEqual(
            [call.args for call in sleep.call_args_list],
            [(0.18,), (0.15,), (0.18,)],
        )

    def test_oled_initializes_on_configured_bus_at_compatible_speed_and_address(self):
        created = {}

        class RecordingI2C(fakes.FakeI2C):
            def __init__(self, *args, **kwargs):
                super().__init__(*args, **kwargs)
                created["i2c"] = self

        with patch.object(oled_module, "I2C", RecordingI2C):
            display = OledDisplay()

        self.assertEqual(created["i2c"].bus_id, 0)
        self.assertEqual(created["i2c"].freq, 100000)
        self.assertEqual(created["i2c"].sda.pin, 21)
        self.assertEqual(created["i2c"].scl.pin, 22)
        self.assertEqual(display.oled.addr, 0x3C)
        self.assertTrue(created["i2c"].writes)

    def test_oled_reports_missing_configured_i2c_address(self):
        class MissingOledI2C(fakes.FakeI2C):
            def scan(self):
                return []

        with patch.object(oled_module, "I2C", MissingOledI2C):
            with self.assertRaisesRegex(OSError, "SSD1306 not found at 0x3C"):
                OledDisplay()

    def test_ssd1306_sends_framebuffer_in_bounded_i2c_data_writes(self):
        i2c = fakes.FakeI2C(0)
        display = SSD1306_I2C(128, 64, i2c, addr=0x3C)
        display.buffer[:] = bytes(range(256)) * 4
        i2c.writes = []

        display.show()

        data_writes = [data for _address, data in i2c.writes if data[0] == 0x40]
        self.assertEqual(len(data_writes), 8)
        self.assertTrue(all(len(data) <= 129 for data in data_writes))
        self.assertEqual(b"".join(data[1:] for data in data_writes), bytes(display.buffer))
        self.assertTrue(all(address == 0x3C for address, _data in i2c.writes))

    def test_ssd1306_180_degree_rotation_uses_segment_and_com_scan_commands(self):
        i2c = fakes.FakeI2C(0)
        display = SSD1306_I2C(128, 64, i2c, addr=0x3C, rotate_180=True)

        commands = [data[1] for _address, data in i2c.writes if data[0] == 0x80]
        self.assertIn(0xA0, commands)
        self.assertIn(0xC0, commands)
        self.assertNotIn(0xA1, commands)
        self.assertNotIn(0xC8, commands)

        i2c.writes = []
        display.reset()
        reset_commands = [
            data[1] for _address, data in i2c.writes if data[0] == 0x80
        ]
        self.assertIn(0xA0, reset_commands)
        self.assertIn(0xC0, reset_commands)

    def test_ssd1306_glyph_pixels_follow_font_top_to_bottom_and_left_to_right(self):
        display = SSD1306_I2C(128, 64, fakes.FakeI2C(0), addr=0x3C)
        text = "ABC 123"
        display.text(text, 0, 0)

        for char_index, char in enumerate(text):
            glyph = FONT.get(ord(char), FONT[32])
            char_x = char_index * 6
            for glyph_x, column in enumerate(glyph):
                for glyph_y in range(8):
                    pixel = (
                        display.buffer[char_x + glyph_x]
                        >> (glyph_y % 8)
                    ) & 1
                    expected = (column >> glyph_y) & 1
                    self.assertEqual(
                        pixel,
                        expected,
                        "pixel mismatch for %r at (%d, %d)"
                        % (char, char_x + glyph_x, glyph_y),
                    )

    def test_oled_initialization_uses_standard_readable_scan_mapping(self):
        with patch.object(oled_module, "I2C", fakes.FakeI2C):
            display = OledDisplay()

        commands = [
            data[1]
            for _address, data in display.i2c.writes
            if data[0] == 0x80
        ]
        self.assertFalse(display.oled.rotate_180)
        self.assertIn(0xA1, commands)
        self.assertIn(0xC8, commands)
        self.assertNotIn(0xA0, commands)
        self.assertNotIn(0xC0, commands)

    def test_oled_initialization_enables_internal_charge_pump(self):
        with patch.object(oled_module, "I2C", fakes.FakeI2C):
            display = OledDisplay()

        commands = [
            data[1]
            for _address, data in display.i2c.writes
            if data[0] == 0x80
        ]
        charge_pump_index = commands.index(0x8D)
        self.assertEqual(commands[charge_pump_index + 1], 0x14)

    def test_oled_displays_requested_startup_and_dynamic_attendance_messages(self):
        display = OledDisplay.__new__(OledDisplay)
        display.width = 128
        display.height = 64
        display.oled = FakeDisplay()

        display.show_startup()
        self.assertEqual(
            display.oled.lines,
            ["LYRA TECH", "Fingerprint", "Initializing..."],
        )
        self.assertEqual((display.oled.fill_count, display.oled.show_count), (1, 1))

        display.oled.lines = []
        display.show_attendance_success("A very long employee display name", "CHECKED_OUT")
        self.assertEqual(
            display.oled.lines,
            ["MATCH SUCCESS", "A very long employee", "CHECKED OUT"],
        )
        self.assertEqual((display.oled.fill_count, display.oled.show_count), (2, 2))

    def test_orientation_sample_messages_keep_the_expected_text(self):
        display = OledDisplay.__new__(OledDisplay)
        display.width = 128
        display.height = 64
        display.oled = FakeDisplay()

        display.show_ready()
        self.assertEqual(display.oled.lines, ["PLACE FINGER"])

        display.oled.lines = []
        display._show_lines(["WELCOME", "CHECKED IN"])
        self.assertEqual(display.oled.lines, ["WELCOME", "CHECKED IN"])

    def test_centered_text_uses_font_metrics_and_clips_long_text(self):
        display = OledDisplay.__new__(OledDisplay)
        display.width = 128
        display.height = 64
        display.oled = FakeDisplay()

        display.draw_centered_text("PLACE FINGER", 100)
        self.assertEqual(display.oled.entries[-1], ("PLACE FINGER", 28, 56))

        display.draw_centered_text("X" * 30, -5)
        text, x, y = display.oled.entries[-1]
        self.assertEqual(len(text), 21)
        self.assertEqual(x, 1)
        self.assertEqual(y, 0)
        self.assertLessEqual(x + len(text) * 6 - 1, display.width)
        self.assertLessEqual(y + 8, display.height)

    def test_all_lines_are_centered_and_vertically_fit_without_overlap(self):
        display = OledDisplay.__new__(OledDisplay)
        display.width = 128
        display.height = 64
        display.oled = FakeDisplay()

        display._show_lines(["ABC 123", "PLACE FINGER", "WELCOME"])

        self.assertEqual(
            display.oled.entries,
            [
                ("ABC 123", 43, 18),
                ("PLACE FINGER", 28, 28),
                ("WELCOME", 43, 38),
            ],
        )
        self.assertTrue(all(y + 8 <= display.height for _text, _x, y in display.oled.entries))
        self.assertTrue(
            all(
                display.oled.entries[index][2] + 8
                <= display.oled.entries[index + 1][2]
                for index in range(len(display.oled.entries) - 1)
            )
        )

    def test_attendance_and_error_messages_use_centered_lines(self):
        display = OledDisplay.__new__(OledDisplay)
        display.width = 128
        display.height = 64
        display.oled = FakeDisplay()

        display.show_attendance_success("WELCOME", "CHECKED_IN")
        self.assertEqual(
            [entry[0] for entry in display.oled.entries],
            ["MATCH SUCCESS", "WELCOME", "CHECKED IN"],
        )
        self.assertTrue(all(entry[1] > 0 for entry in display.oled.entries))

        display.oled.entries = []
        display.show_attendance_success("WELCOME", "CHECKED_OUT")
        self.assertEqual(
            [entry[0] for entry in display.oled.entries],
            ["MATCH SUCCESS", "WELCOME", "CHECKED OUT"],
        )
        self.assertTrue(all(entry[1] > 0 for entry in display.oled.entries))

        display.oled.entries = []
        display.show_api_error()
        self.assertEqual(display.oled.entries[0][0], "API ERROR")
        self.assertGreater(display.oled.entries[0][1], 0)

    def test_orientation_test_pattern_renders_three_centered_verification_rows(self):
        display = OledDisplay.__new__(OledDisplay)
        display.width = 128
        display.height = 64
        display.oled = FakeDisplay()

        display.show_orientation_test_pattern()

        self.assertEqual(
            [entry[0] for entry in display.oled.entries],
            ["ABC 123", "PLACE FINGER"],
        )
        self.assertEqual([entry[1] for entry in display.oled.entries], [43, 28])
        self.assertEqual([entry[2] for entry in display.oled.entries], [23, 33])

    def test_standalone_hardware_test_starts_with_orientation_pattern(self):
        from hardware_test import test_oled

        with patch.object(oled_module, "I2C", fakes.FakeI2C):
            with patch.object(
                OledDisplay, "show_orientation_test_pattern"
            ) as pattern:
                display = test_oled()

        self.assertIsNotNone(display)
        pattern.assert_called_once_with()


if __name__ == "__main__":
    unittest.main()
