"""Active-high blue, green, and red status LEDs."""

import time

from machine import Pin

from config import BLUE_LED_PIN, GREEN_LED_PIN, RED_LED_PIN


class StatusLed:
    def __init__(self):
        self.green = Pin(GREEN_LED_PIN, Pin.OUT)
        self.blue = Pin(BLUE_LED_PIN, Pin.OUT)
        self.red = Pin(RED_LED_PIN, Pin.OUT)
        self._enrollment_blinking = False
        self._enrollment_next_toggle_ms = 0
        self.all_leds_off()

    @staticmethod
    def _ticks_ms():
        if hasattr(time, "ticks_ms"):
            return time.ticks_ms()
        return int(time.time() * 1000)

    @staticmethod
    def _ticks_diff(end, start):
        if hasattr(time, "ticks_diff"):
            return time.ticks_diff(end, start)
        return end - start

    @staticmethod
    def _ticks_add(ticks, delta):
        if hasattr(time, "ticks_add"):
            return time.ticks_add(ticks, delta)
        return ticks + delta

    def all_leds_off(self):
        self._enrollment_blinking = False
        self.green.off()
        self.blue.off()
        self.red.off()

    def green_on(self):
        self.green.on()

    def green_off(self):
        self.green.off()

    def red_on(self):
        self.red.on()

    def red_off(self):
        self.red.off()

    def ready_status(self):
        self._enrollment_blinking = False
        self.all_leds_off()
        self.blue.on()

    def enrollment_blink_start(self):
        self.all_leds_off()
        self._enrollment_blinking = True
        self._enrollment_next_toggle_ms = self._ticks_ms()
        self.enrollment_blink_tick()

    def enrollment_blink_tick(self):
        if not self._enrollment_blinking:
            return
        now = self._ticks_ms()
        if self._ticks_diff(now, self._enrollment_next_toggle_ms) >= 0:
            self.blue.value(0 if self.blue.value() else 1)
            self._enrollment_next_toggle_ms = self._ticks_add(now, 350)

    def enrollment_success(self):
        self.all_leds_off()
        self.green.on()

    def enrollment_failure(self):
        self.all_leds_off()
        self.red.on()

    def match_success(self):
        self.all_leds_off()
        self.green.on()

    def match_failed(self):
        self.all_leds_off()
        self.red.on()

    def sensor_error(self):
        self.all_leds_off()

    def api_error(self):
        self.all_leds_off()

    def set_status(self, green=True, red=False):
        self.blue.off()
        self.green.value(1 if green else 0)
        self.red.value(1 if red else 0)
