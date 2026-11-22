"""Green and red status LEDs."""

from machine import Pin

from config import GREEN_LED_PIN, RED_LED_PIN


class StatusLed:
    def __init__(self):
        self.green = Pin(GREEN_LED_PIN, Pin.OUT)
        self.red = Pin(RED_LED_PIN, Pin.OUT)
        self.green.off()
        self.red.off()

    def green_on(self):
        self.green.on()

    def green_off(self):
        self.green.off()

    def red_on(self):
        self.red.on()

    def red_off(self):
        self.red.off()

    def set_status(self, green=True, red=False):
        self.green.value(1 if green else 0)
        self.red.value(1 if red else 0)
