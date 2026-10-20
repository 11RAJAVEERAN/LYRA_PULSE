"""SSD1306 OLED UI for the attendance terminal."""

from machine import I2C, Pin

from config import OLED_I2C_ADDRESS, OLED_SCL_PIN, OLED_SDA_PIN
from lib.ssd1306 import (
    FONT_CHAR_SPACING,
    FONT_HEIGHT,
    FONT_WIDTH,
    SSD1306_I2C,
)
from utils.logger import log

_LINE_SPACING = 2


class OledDisplay:
    def __init__(self, width=128, height=64):
        self.width = width
        self.height = height
        self.i2c = I2C(0, sda=Pin(OLED_SDA_PIN), scl=Pin(OLED_SCL_PIN), freq=100000)
        addresses = self.i2c.scan()
        log("OLED", "I2C scan: %s" % addresses)
        if OLED_I2C_ADDRESS not in addresses:
            raise OSError(
                "SSD1306 not found at 0x%02X (I2C scan: %s)"
                % (OLED_I2C_ADDRESS, addresses)
            )
        self.oled = SSD1306_I2C(
            width,
            height,
            self.i2c,
            addr=OLED_I2C_ADDRESS,
            rotate_180=False,
        )
        self.clear()

    def draw_centered_text(self, text, y):
        text = str(text)
        max_chars = (self.width + FONT_CHAR_SPACING) // (
            FONT_WIDTH + FONT_CHAR_SPACING
        )
        text = text[:max_chars]
        text_width = max(
            0,
            (len(text) * (FONT_WIDTH + FONT_CHAR_SPACING))
            - FONT_CHAR_SPACING,
        )
        x = max(0, (self.width - text_width) // 2)
        y = max(0, min(int(y), self.height - FONT_HEIGHT))
        self.oled.text(text, x, y)

    def clear(self):
        self.oled.fill(0)
        self.oled.show()

    def _show_lines(self, lines, title=None):
        self.oled.fill(0)
        display_lines = []
        if title:
            display_lines.append(title)
        display_lines.extend(lines)

        line_height = FONT_HEIGHT + _LINE_SPACING
        max_lines = max(1, (self.height + _LINE_SPACING) // line_height)
        display_lines = display_lines[:max_lines]
        block_height = (
            len(display_lines) * FONT_HEIGHT
            + max(0, len(display_lines) - 1) * _LINE_SPACING
        )
        first_y = max(0, (self.height - block_height) // 2)
        for index, text in enumerate(display_lines):
            self.draw_centered_text(text, first_y + index * line_height)
        self.oled.show()

    def show_startup(self):
        self._show_lines(["LYRA TECH", "Fingerprint", "Initializing..."])

    def show_wifi_connecting(self):
        self._show_lines(["WiFi", "Connecting..."])

    def show_wifi_connected(self):
        self._show_lines(["WiFi", "Connected"])

    def show_ready(self):
        self._show_lines(["LYRA TECH", "READY", "Place finger"])

    def show_welcome(self):
        self._show_lines(["WELCOME"])

    def show_orientation_test_pattern(self):
        self._show_lines(["ABC 123", "PLACE FINGER"])

    def show_waiting_for_enrollment(self):
        self._show_lines(["LYRA PULSE", "Waiting for", "Enrollment"])

    def show_finger_detected(self):
        self._show_lines(["Finger", "Detected"])

    def show_processing(self):
        self._show_lines(["Checking Finger..."])

    def show_searching(self):
        self._show_lines(["Searching", "Template Store"])

    def show_matched(self, name):
        self._show_lines(["Match Found", name])

    def show_attendance_success(self, name, attendance_status=None):
        self.show_match_success(name, attendance_status)

    def show_match_success(self, name, attendance_status=None):
        lines = ["MATCH SUCCESS", name[:21].rstrip(), "Welcome!"]
        if attendance_status == "CHECKED_IN":
            lines.append("CHECKED IN")
        elif attendance_status == "CHECKED_OUT":
            lines.append("CHECKED OUT")
        self._show_lines(lines)

    def show_not_found(self):
        self._show_lines(["NO MATCH", "Access denied", "Try again"])

    def show_sensor_error(self):
        self._show_lines(["SENSOR ERROR"])

    def show_api_error(self):
        self._show_lines(["API ERROR"])

    def show_network_error(self):
        self._show_lines(["Network Error", "Try Again"])

    def show_device_error(self):
        self.show_sensor_error()

    def show_enrollment(self):
        self._show_lines(["Enrollment", "Mode"])

    def show_enrollment_failed(self):
        self._show_lines(["Enrollment", "Failed"])

    def show_enrollment_prompt(self, prompt):
        self._show_lines([prompt], title="ENROLLMENT")

    def show_enrollment_remove_finger(self):
        self._show_lines(["Remove finger"], title="ENROLLMENT")

    def show_enrollment_success(self, slot):
        self._show_lines(["Stored ID %s" % slot], title="ENROLLMENT OK")
