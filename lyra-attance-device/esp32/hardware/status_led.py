"""Active-high blue, green, and red status LEDs."""

from machine import Pin

from config import BLUE_LED_PIN, GREEN_LED_PIN, RED_LED_PIN


class StatusLed:
    def __init__(self):
        self.green = Pin(GREEN_LED_PIN, Pin.OUT)
        self.blue = Pin(BLUE_LED_PIN, Pin.OUT)
        self.red = Pin(RED_LED_PIN, Pin.OUT)
        self.all_leds_off()

    def all_leds_off(self):
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
        self.all_leds_off()
        self.blue.on()

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
