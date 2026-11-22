"""Debounced digital touch-output input from the R307 fingerprint module."""

import time

from machine import Pin

from config import (
    R307_TOUCH_ACTIVE_LEVEL,
    R307_TOUCH_DEBOUNCE_SAMPLES,
    R307_TOUCH_LOG_INTERVAL_SECONDS,
    R307_TOUCH_PIN,
    R307_TOUCH_SAMPLE_INTERVAL_SECONDS,
)
from utils.logger import log


class TouchSensor:
    def __init__(self, pin=None):
        if R307_TOUCH_ACTIVE_LEVEL not in (0, 1):
            raise ValueError("R307_TOUCH_ACTIVE_LEVEL must be 0 or 1")
        self.pin = pin if pin is not None else Pin(R307_TOUCH_PIN, Pin.IN)
        self._last_logged_level = None
        self._last_log_tick = None
        log(
            "TOUCH",
            "GPIO%d configured input; active level=%d; raw at boot=%d"
            % (R307_TOUCH_PIN, R307_TOUCH_ACTIVE_LEVEL, self.read_raw()),
        )

    def _wait_for_level(self, level, timeout_seconds=None):
        stable_samples = 0
        elapsed_seconds = 0
        self.log_raw_state(force=True, periodic=False)
        while timeout_seconds is None or elapsed_seconds < timeout_seconds:
            raw_level = self.log_raw_state()
            if raw_level == level:
                stable_samples += 1
                if stable_samples >= R307_TOUCH_DEBOUNCE_SAMPLES:
                    log(
                        "TOUCH",
                        "GPIO%d stable level=%d (%s)"
                        % (
                            R307_TOUCH_PIN,
                            raw_level,
                            "touched" if level == R307_TOUCH_ACTIVE_LEVEL else "idle",
                        ),
                    )
                    return True
            else:
                stable_samples = 0
            time.sleep(R307_TOUCH_SAMPLE_INTERVAL_SECONDS)
            elapsed_seconds += R307_TOUCH_SAMPLE_INTERVAL_SECONDS
        return False

    def wait_for_touch(self, timeout_seconds=None):
        return self._wait_for_level(R307_TOUCH_ACTIVE_LEVEL, timeout_seconds)

    def wait_for_removal(self, timeout_seconds=None):
        return self._wait_for_level(1 - R307_TOUCH_ACTIVE_LEVEL, timeout_seconds)

    def wait_for_new_touch(self, timeout_seconds=None):
        log("READY", "Waiting for stable GPIO%d idle level" % R307_TOUCH_PIN)
        if not self.wait_for_removal(timeout_seconds):
            return False
        log("READY", "GPIO%d idle confirmed; waiting for a new touch" % R307_TOUCH_PIN)
        if not self.wait_for_touch(timeout_seconds):
            return False
        log("FINGER", "New GPIO%d touch event confirmed" % R307_TOUCH_PIN)
        return True

    def read_raw(self):
        return self.pin.value()

    def log_raw_state(self, force=False, periodic=True):
        raw_level = self.read_raw()
        tick = time.ticks_ms() if hasattr(time, "ticks_ms") else int(time.monotonic() * 1000)
        changed = raw_level != self._last_logged_level
        interval_ms = int(R307_TOUCH_LOG_INTERVAL_SECONDS * 1000)
        elapsed_ms = (
            interval_ms
            if self._last_log_tick is None
            else (
                time.ticks_diff(tick, self._last_log_tick)
                if hasattr(time, "ticks_diff")
                else tick - self._last_log_tick
            )
        )
        if force or changed or (periodic and elapsed_ms >= interval_ms):
            if changed and self._last_logged_level is not None:
                log(
                    "TOUCH",
                    "GPIO%d raw changed %d->%d"
                    % (R307_TOUCH_PIN, self._last_logged_level, raw_level),
                )
            log("TOUCH", "GPIO%d raw=%d" % (R307_TOUCH_PIN, raw_level))
            self._last_logged_level = raw_level
            self._last_log_tick = tick
        return raw_level

    def is_touched(self):
        raw_level = self.log_raw_state()
        return raw_level == R307_TOUCH_ACTIVE_LEVEL

    def wait_while_touched(self, duration_seconds):
        elapsed_seconds = 0
        sample_interval = min(R307_TOUCH_SAMPLE_INTERVAL_SECONDS, duration_seconds)
        while elapsed_seconds < duration_seconds:
            if not self.is_touched():
                return False
            time.sleep(sample_interval)
            elapsed_seconds += sample_interval
        return self.is_touched()
