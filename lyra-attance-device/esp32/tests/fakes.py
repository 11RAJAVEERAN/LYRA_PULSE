import sys
import types


class FakePin:
    OUT = 1
    IN = 0
    instances = {}

    def __init__(self, pin, mode=None):
        self.pin = pin
        self.mode = mode
        self.state = 0
        self.history = []
        FakePin.instances[pin] = self

    def on(self):
        self.state = 1
        self.history.append(1)

    def off(self):
        self.state = 0
        self.history.append(0)

    def value(self, value=None):
        if value is None:
            return self.state
        self.state = value
        self.history.append(value)


class FakeUART:
    latest = None

    def __init__(self, uart_id, baudrate):
        self.writes = []
        self.response = bytearray()
        FakeUART.latest = self

    def init(self, **kwargs):
        return None

    def write(self, data):
        self.writes.append(bytes(data))
        return len(data)

    def read(self, size):
        chunk = self.response[:size]
        del self.response[:size]
        return bytes(chunk) or None


class FakeI2C:
    def __init__(self, bus_id, sda=None, scl=None, freq=None):
        self.bus_id = bus_id
        self.sda = sda
        self.scl = scl
        self.freq = freq
        self.writes = []

    def scan(self):
        return [0x3C]

    def writeto(self, address, data):
        self.writes.append((address, bytes(data)))
        return len(data)


machine = types.ModuleType("machine")
machine.Pin = FakePin
machine.UART = FakeUART
machine.I2C = FakeI2C
sys.modules["machine"] = machine
