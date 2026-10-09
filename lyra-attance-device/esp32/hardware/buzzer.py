"""Simple active buzzer controller."""

import time

from machine import Pin

from config import BUZZER_PIN


class Buzzer:
    def __init__(self):
        self.pin = Pin(BUZZER_PIN, Pin.OUT)
        self.pin.off()

    def _beep(self, duration=0.18):
        try:
            self.pin.on()
            time.sleep(duration)
        finally:
            self.pin.off()

    def off(self):
        self.pin.off()

    def beep_once(self):
        self._beep()

    def beep_twice(self):
        self._beep()
        time.sleep(0.15)
        self._beep()

    def startup_beep(self):
        self._beep(0.08)
        time.sleep(0.05)
        self._beep(0.08)

    def success_beep(self):
        self._beep(0.12)
        time.sleep(0.05)
        self._beep(0.12)

    def error_beep(self):
        self._beep(0.25)
        time.sleep(0.08)
        self._beep(0.25)

    def not_found_beep(self):
        self._beep(0.15)

    def enrollment_beep(self):
        self._beep(0.08)
        time.sleep(0.03)
        self._beep(0.08)
