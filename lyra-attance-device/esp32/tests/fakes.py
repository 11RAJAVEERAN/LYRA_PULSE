import sys
import types


class FakePin:
    OUT = 1
    IN = 0

    def __init__(self, pin, mode=None):
        self.pin = pin
        self.mode = mode


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


machine = types.ModuleType("machine")
machine.Pin = FakePin
machine.UART = FakeUART
sys.modules["machine"] = machine
