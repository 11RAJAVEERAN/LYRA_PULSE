import contextlib
import io
import unittest
from unittest.mock import patch

import fakes
import r307_uart_diagnostic as diagnostic
from drivers.r307 import (
    R307,
    R307CommunicationError,
    R307InvalidPacketError,
    R307TimeoutError,
)


class SensorResult:
    def __init__(self, error=None):
        self.error = error
        self.begin_calls = 0

    def begin(self):
        self.begin_calls += 1
        if self.error is not None:
            raise self.error
        return True


class R307DiagnosticTests(unittest.TestCase):
    def test_diagnostics_disable_packet_debug_logging(self):
        output = io.StringIO()
        with (
            contextlib.redirect_stdout(output),
            patch("r307_uart_diagnostic.R307") as driver,
        ):
            self.assertTrue(diagnostic.run_sensor_diagnostic())

        driver.assert_called_once_with(debug=False)
        self.assertNotIn("TX packet", output.getvalue())

    def test_sensor_diagnostic_reports_zero_bytes_without_claiming_success(self):
        sensor = SensorResult(R307TimeoutError("timeout", received_bytes=0))
        output = io.StringIO()

        with contextlib.redirect_stdout(output):
            result = diagnostic.run_sensor_diagnostic(sensor)

        self.assertFalse(result)
        self.assertEqual(sensor.begin_calls, 1)
        self.assertIn("zero response bytes", output.getvalue())
        self.assertNotIn("TEST PASS", output.getvalue())

    def test_sensor_diagnostic_reports_partial_bytes_and_malformed_packets(self):
        partial = SensorResult(
            R307TimeoutError(
                "partial timeout",
                received_bytes=2,
                partial_data=b"\xEF\x01",
            )
        )
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertFalse(diagnostic.run_sensor_diagnostic(partial))
        self.assertIn("partial response (2 bytes): EF01", output.getvalue())

        malformed = SensorResult(
            R307InvalidPacketError("Invalid packet header")
        )
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            self.assertFalse(diagnostic.run_sensor_diagnostic(malformed))
        self.assertIn("malformed or invalid response", output.getvalue())

    def test_loopback_refuses_to_write_without_explicit_disconnect_confirmation(self):
        class NoWriteSensor:
            def __init__(self):
                self.called = False

            def uart_loopback_test(self, **_kwargs):
                self.called = True

        sensor = NoWriteSensor()
        output = io.StringIO()
        with (
            contextlib.redirect_stdout(output),
            patch(
                "r307_uart_diagnostic.R307_LOOPBACK_CONFIRMED_DISCONNECTED",
                False,
            ),
        ):
            self.assertFalse(diagnostic.run_loopback_diagnostic(sensor))

        self.assertFalse(sensor.called)
        self.assertIn("LOOPBACK REFUSED", output.getvalue())
        self.assertIn("disconnect the sensor", output.getvalue())

    def test_loopback_requires_exact_uart_echo(self):
        sensor = R307(debug=False)
        sensor.uart_loopback_test = lambda timeout_ms: True
        output = io.StringIO()

        with (
            contextlib.redirect_stdout(output),
            patch(
                "r307_uart_diagnostic.R307_LOOPBACK_CONFIRMED_DISCONNECTED",
                True,
            ),
        ):
            self.assertTrue(diagnostic.run_loopback_diagnostic(sensor))

        self.assertIn("UART LOOPBACK PASS", output.getvalue())


if __name__ == "__main__":
    unittest.main()
