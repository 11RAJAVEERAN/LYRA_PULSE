"""Bounded R307 sensor, UART loopback, and GPIO18 diagnostics.

Select R307_DIAGNOSTIC_MODE in config.py: "sensor", "loopback", or "touch".
This utility never starts attendance polling or modifies sensor templates.
"""

try:
    import utime as time
except ImportError:  # pragma: no cover - host test compatibility
    import time as _time

    class _CompatTime:
        @staticmethod
        def ticks_ms():
            return int(_time.time() * 1000)

        @staticmethod
        def ticks_diff(end, start):
            return end - start

        @staticmethod
        def sleep_ms(milliseconds):
            _time.sleep(milliseconds / 1000)

    time = _CompatTime()

from config import (
    R307_ADDRESS,
    R307_DIAGNOSTIC_MODE,
    R307_LOOPBACK_CONFIRMED_DISCONNECTED,
    R307_PASSWORD,
    R307_TOUCH_ACTIVE_LEVEL,
    R307_TOUCH_PIN,
    UART_BAUDRATE,
    UART_ID,
    UART_RX_PIN,
    UART_TX_PIN,
)
from drivers.r307 import (
    R307,
    R307CommunicationError,
    R307InvalidPacketError,
    R307PacketError,
    R307TimeoutError,
)
from machine import Pin


TOUCH_TEST_DURATION_SECONDS = 15
UART_LOOPBACK_TIMEOUT_MS = 500


def log(message):
    print("[%d] [DIAGNOSTIC] %s" % (time.ticks_ms(), message))


def to_hex(data):
    return "".join("%02X" % value for value in data)


def report_configuration():
    log(
        "UART%d baud=%d 8N1 TX=GPIO%d RX=GPIO%d sensor_address=0x%08X"
        % (
            UART_ID,
            UART_BAUDRATE,
            UART_TX_PIN,
            UART_RX_PIN,
            R307_ADDRESS & 0xFFFFFFFF,
        )
    )
    log("R307 password configured: yes (value redacted)")
    log(
        "GPIO%d touch active level: %s"
        % (
            R307_TOUCH_PIN,
            "unverified/either edge"
            if R307_TOUCH_ACTIVE_LEVEL is None
            else R307_TOUCH_ACTIVE_LEVEL,
        )
    )


def run_sensor_diagnostic(sensor=None):
    """Send one VerifyPassword via the production driver and classify response."""
    if sensor is None:
        sensor = R307(debug=False)
    try:
        sensor.begin()
    except R307TimeoutError as exc:
        if exc.received_bytes == 0:
            log("SENSOR TEST FAIL: zero response bytes received before timeout")
        else:
            log(
                "SENSOR TEST FAIL: partial response (%d bytes): %s"
                % (exc.received_bytes, to_hex(exc.partial_data))
            )
        return False
    except R307InvalidPacketError as exc:
        log("SENSOR TEST FAIL: malformed or invalid response: %s" % exc)
        return False
    except R307CommunicationError as exc:
        message = str(exc)
        if "password verification rejected:" in message:
            log("SENSOR TEST: valid ACK received but password rejected: %s" % message)
        else:
            log("SENSOR TEST FAIL: UART/communication error: %s" % message)
        return False
    except R307PacketError as exc:
        log(
            "SENSOR TEST FAIL: sensor command error (%s): %s"
            % (exc.__class__.__name__, exc)
        )
        return False

    log("SENSOR TEST PASS: valid VerifyPassword ACK accepted by sensor")
    return True


def run_loopback_diagnostic(sensor=None):
    log(
        "WARNING: disconnect the sensor from GPIO17/GPIO16, then jumper GPIO17 "
        "to GPIO16 before selecting loopback mode."
    )
    if not R307_LOOPBACK_CONFIRMED_DISCONNECTED:
        log(
            "LOOPBACK REFUSED: set R307_LOOPBACK_CONFIRMED_DISCONNECTED=True "
            "only after physically disconnecting the sensor."
        )
        return False
    if sensor is None:
        sensor = R307(debug=False)
    try:
        passed = sensor.uart_loopback_test(timeout_ms=UART_LOOPBACK_TIMEOUT_MS)
    except R307PacketError as exc:
        log(
            "UART LOOPBACK FAIL: %s: %s"
            % (exc.__class__.__name__, exc)
        )
        return False
    if not passed:
        log("UART LOOPBACK FAIL: TX/RX echo was not confirmed")
        return False
    log("UART LOOPBACK PASS: ESP32 local UART TX/RX echo confirmed")
    return True


def run_touch_diagnostic():
    pin = Pin(R307_TOUCH_PIN, Pin.IN)
    previous = pin.value()
    log(
        "TOUCH TEST START: GPIO%d initial raw=%d; touch/release during %ds window"
        % (R307_TOUCH_PIN, previous, TOUCH_TEST_DURATION_SECONDS)
    )
    if R307_TOUCH_ACTIVE_LEVEL is None:
        log("TOUCH POLARITY: not configured; raw levels will be reported without interpretation")
    else:
        log(
            "TOUCH POLARITY: configured active level=%d; verify against physical touch"
            % R307_TOUCH_ACTIVE_LEVEL
        )

    deadline = time.ticks_add(
        time.ticks_ms(),
        TOUCH_TEST_DURATION_SECONDS * 1000,
    )
    transitions = 0
    while time.ticks_diff(deadline, time.ticks_ms()) > 0:
        current = pin.value()
        if current != previous:
            transitions += 1
            state = (
                "active"
                if R307_TOUCH_ACTIVE_LEVEL is not None
                and current == R307_TOUCH_ACTIVE_LEVEL
                else "inactive"
                if R307_TOUCH_ACTIVE_LEVEL is not None
                else "unclassified"
            )
            log(
                "GPIO%d raw transition=%d->%d (%s)"
                % (R307_TOUCH_PIN, previous, current, state)
            )
            previous = current
        time.sleep_ms(10)
    log(
        "TOUCH TEST END: transitions=%d final raw=%d; no polarity inferred from transitions alone"
        % (transitions, previous)
    )
    return True


def main():
    report_configuration()
    if R307_DIAGNOSTIC_MODE == "sensor":
        return run_sensor_diagnostic()
    if R307_DIAGNOSTIC_MODE == "loopback":
        return run_loopback_diagnostic()
    if R307_DIAGNOSTIC_MODE == "touch":
        return run_touch_diagnostic()
    raise ValueError(
        "Unsupported R307_DIAGNOSTIC_MODE: %s" % R307_DIAGNOSTIC_MODE
    )


if __name__ == "__main__":
    main()
