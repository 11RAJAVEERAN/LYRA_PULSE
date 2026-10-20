"""SSD1306 OLED UI for the attendance terminal."""

from machine import I2C, Pin

from config import OLED_I2C_ADDRESS, OLED_SCL_PIN, OLED_SDA_PIN
from lib.ssd1306 import SSD1306_I2C


class OledDisplay:
    def __init__(self, width=128, height=64):
        self.width = width
        self.height = height
        self.i2c = I2C(0, sda=Pin(OLED_SDA_PIN), scl=Pin(OLED_SCL_PIN), freq=400000)
        self.oled = SSD1306_I2C(width, height, self.i2c, addr=OLED_I2C_ADDRESS)
        self.clear()

    def clear(self):
        self.oled.fill(0)
        self.oled.show()

    def _show_lines(self, lines, title=None):
        self.oled.fill(0)
        if title:
            self.oled.text(title, 0, 0)
        for index, text in enumerate(lines):
            y = 16 + (index * 10)
            self.oled.text(text, 0, y)
        self.oled.show()

    def show_startup(self):
        self._show_lines(["LYRA PULSE", "Fingerprint", "Device"], title="")

    def show_wifi_connecting(self):
        self._show_lines(["WiFi", "Connecting..."]) 

    def show_wifi_connected(self):
        self._show_lines(["WiFi", "Connected"]) 

    def show_ready(self):
        self._show_lines(["LYRA PULSE", "Fingerprint READY", "Place Finger"]) 

    def show_finger_detected(self):
        self._show_lines(["Finger", "Detected"]) 

    def show_processing(self):
        self._show_lines(["Processing...", "Please wait"]) 

    def show_searching(self):
        self._show_lines(["Searching", "Template Store"]) 

    def show_matched(self, name="Employee"):
        self._show_lines(["Match Found", name]) 

    def show_attendance_success(self, name="Employee"):
        self._show_lines(["Welcome", name, "Attendance", "Success"]) 

    def show_not_found(self):
        self._show_lines(["Fingerprint", "Not Found"]) 

    def show_network_error(self):
        self._show_lines(["Network Error", "Try Again"]) 

    def show_device_error(self):
        self._show_lines(["Device Error", "Check sensor"]) 

    def show_enrollment(self):
        self._show_lines(["Enrollment", "Mode"]) 

    def show_enrollment_success(self):
        self._show_lines(["Enrollment", "Success"]) 

    def show_enrollment_failed(self):
        self._show_lines(["Enrollment", "Failed"]) 
