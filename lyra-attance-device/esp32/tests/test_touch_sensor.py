import unittest
from unittest.mock import patch

import fakes

from config import R307_TOUCH_DEBOUNCE_SAMPLES, R307_TOUCH_PIN
from hardware.touch_sensor import TouchSensor


class TouchSensorTests(unittest.TestCase):
    def test_detects_debounced_edges_in_either_direction_without_polarity(self):
        pin = fakes.FakePin(R307_TOUCH_PIN, fakes.FakePin.IN)
        touch = TouchSensor(pin, active_level=None)

        pin.value(1)
        for _ in range(R307_TOUCH_DEBOUNCE_SAMPLES - 1):
            self.assertFalse(touch.poll_touch_edge())
        self.assertTrue(touch.poll_touch_edge())
        self.assertFalse(touch.poll_touch_edge())

        pin.value(0)
        for _ in range(R307_TOUCH_DEBOUNCE_SAMPLES - 1):
            self.assertFalse(touch.poll_touch_edge())
        self.assertTrue(touch.poll_touch_edge())
        self.assertFalse(touch.poll_touch_edge())

    def test_reset_baseline_discards_transitions_observed_during_other_work(self):
        pin = fakes.FakePin(R307_TOUCH_PIN, fakes.FakePin.IN)
        touch = TouchSensor(pin)
        pin.value(1)

        touch.reset_baseline()

        for _ in range(5):
            self.assertFalse(touch.poll_touch_edge())

    def test_active_high_polarity_ignores_falling_edge_and_triggers_rising_edge(self):
        pin = fakes.FakePin(R307_TOUCH_PIN, fakes.FakePin.IN)
        touch = TouchSensor(pin, active_level=1)

        pin.value(1)
        for _ in range(R307_TOUCH_DEBOUNCE_SAMPLES):
            result = touch.poll_touch_edge()
        self.assertTrue(result)

        pin.value(0)
        for _ in range(R307_TOUCH_DEBOUNCE_SAMPLES):
            result = touch.poll_touch_edge()
        self.assertFalse(result)

    def test_active_low_polarity_triggers_only_on_falling_edge(self):
        pin = fakes.FakePin(R307_TOUCH_PIN, fakes.FakePin.IN)
        pin.value(1)
        touch = TouchSensor(pin, active_level=0)

        pin.value(0)
        for _ in range(R307_TOUCH_DEBOUNCE_SAMPLES):
            result = touch.poll_touch_edge()
        self.assertTrue(result)

        pin.value(1)
        for _ in range(R307_TOUCH_DEBOUNCE_SAMPLES):
            result = touch.poll_touch_edge()
        self.assertFalse(result)

    def test_initially_active_touch_must_still_pass_debounce(self):
        pin = fakes.FakePin(R307_TOUCH_PIN, fakes.FakePin.IN)
        touch = TouchSensor(pin, active_level=0)

        for _ in range(R307_TOUCH_DEBOUNCE_SAMPLES - 1):
            self.assertFalse(touch.poll_touch_edge())
        self.assertTrue(touch.poll_touch_edge())

    def test_configured_active_low_touch_uses_internal_pullup(self):
        from machine import Pin

        TouchSensor()
        pin = fakes.FakePin.instances[R307_TOUCH_PIN]
        self.assertEqual(pin.pull, Pin.PULL_UP)

    def test_release_requires_all_debounce_samples_inactive(self):
        pin = fakes.FakePin(R307_TOUCH_PIN, fakes.FakePin.IN)
        touch = TouchSensor(pin, active_level=0)
        levels = iter([1, 1, 0])
        pin.value = lambda value=None: next(levels)

        with patch("hardware.touch_sensor.time.sleep"):
            self.assertFalse(touch.is_released_debounced())

    def test_invalid_active_level_is_rejected(self):
        pin = fakes.FakePin(R307_TOUCH_PIN, fakes.FakePin.IN)
        with self.assertRaises(ValueError):
            TouchSensor(pin, active_level=2)


if __name__ == "__main__":
    unittest.main()
