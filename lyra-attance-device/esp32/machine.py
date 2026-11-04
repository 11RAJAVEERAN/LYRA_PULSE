"""Compatibility shim for running the firmware in a CPython environment.

This is only used for local debugging and does not affect genuine ESP32
MicroPython execution, where the real built-in `machine` module is available.
"""

import time


class Pin:
    OUT = 1
    IN = 0

    def __init__(self, pin_id, mode=-1):
        self.pin_id = pin_id
        self.mode = mode

    def __call__(self, *args, **kwargs):
        return self

    def on(self):
        return True

    def off(self):
        return False

    def value(self, val=None):
        if val is None:
            return 0
        return val


class UART:
    def __init__(self, uart_id, baudrate=115200):
        self.uart_id = uart_id
        self.baudrate = baudrate
        self._buffer = bytearray()

    def init(self, **kwargs):
        self.kwargs = kwargs
        return True

    def read(self, nbytes):
        if not self._buffer:
            return b""
        chunk = self._buffer[:nbytes]
        del self._buffer[:nbytes]
        return bytes(chunk)

    def write(self, data):
        self._buffer.extend(data)
        return len(data)


class I2C:
    def __init__(self, bus_id, sda=None, scl=None, freq=400000):
        self.bus_id = bus_id
        self.sda = sda
        self.scl = scl
        self.freq = freq

    def writeto(self, address, data):
        return len(data)
