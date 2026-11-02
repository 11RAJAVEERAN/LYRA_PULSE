"""Debounced touch detection for the configured R307 touch output."""

import time

from machine import Pin

from config import (
    R307_TOUCH_ACTIVE_LEVEL,
    R307_TOUCH_DEBOUNCE_SAMPLES,
    R307_TOUCH_PIN,
    R307_TOUCH_SAMPLE_INTERVAL_SECONDS,
)
from utils.logger import log


class TouchSensor:
    def __init__(self, pin=None, active_level=R307_TOUCH_ACTIVE_LEVEL):
        if active_level not in (None, 0, 1):
            raise ValueError("Touch active level must be None, 0, or 1")
        if pin is None:
            pull = Pin.PULL_UP if active_level == 0 else None
            self.pin = Pin(R307_TOUCH_PIN, Pin.IN, pull)
        else:
            self.pin = pin
        self.active_level = active_level
        self.stable_level = self.pin.value()
        self.candidate_level = self.stable_level
        self.candidate_samples = 0
        self.initial_active_pending = (
            active_level is not None and self.stable_level == active_level
        )
        self.initial_active_samples = 0
        active = (
            active_level is not None
            and self.stable_level == active_level
        )
        log(
            "TOUCH",
            "GPIO%d raw=%d active_level=%s active=%s monitoring started"
            % (
                R307_TOUCH_PIN,
                self.stable_level,
                "either edge (unverified)"
                if active_level is None
                else active_level,
                "yes" if active else "no",
            ),
        )

    def is_active(self):
        return (
            self.active_level is not None
            and self.current_level() == self.active_level
        )

    def current_level(self):
        return self.pin.value()

    def is_released_debounced(self):
        if self.active_level is None:
            return False
        for _ in range(R307_TOUCH_DEBOUNCE_SAMPLES):
            if self.is_active():
                return False
            time.sleep(R307_TOUCH_SAMPLE_INTERVAL_SECONDS)
        return True

    def poll_touch_edge(self):
        if self.initial_active_pending:
            if not self.is_active():
                self.initial_active_pending = False
                self.initial_active_samples = 0
                return False
            self.initial_active_samples += 1
            if self.initial_active_samples < R307_TOUCH_DEBOUNCE_SAMPLES:
                return False
            self.initial_active_pending = False
            self.initial_active_samples = 0
            return True

        raw_level = self.current_level()
        if raw_level == self.stable_level:
            self.candidate_level = raw_level
            self.candidate_samples = 0
            return False

        if raw_level != self.candidate_level:
            self.candidate_level = raw_level
            self.candidate_samples = 1
        else:
            self.candidate_samples += 1

        if self.candidate_samples < R307_TOUCH_DEBOUNCE_SAMPLES:
            return False

        previous_level = self.stable_level
        self.stable_level = self.candidate_level
        self.candidate_samples = 0
        if self.active_level is not None and self.stable_level != self.active_level:
            return False
        log(
            "TOUCH",
            "GPIO%d raw=%d active=%s debounced edge=%d->%d; requesting image confirmation"
            % (
                R307_TOUCH_PIN,
                self.stable_level,
                "yes" if self.stable_level == self.active_level else "no",
                previous_level,
                self.stable_level,
            ),
        )
        return True

    def wait_for_release(self, timeout_seconds=None, on_wait=None):
        inactive_samples = 0
        started = time.time()
        samples_since_callback = 0
        while inactive_samples < R307_TOUCH_DEBOUNCE_SAMPLES:
            if self.is_active():
                inactive_samples = 0
            else:
                inactive_samples += 1
            samples_since_callback += 1
            if on_wait is not None and samples_since_callback >= 10:
                on_wait()
                samples_since_callback = 0
            if (
                timeout_seconds is not None
                and time.time() - started >= timeout_seconds
            ):
                return False
            time.sleep(R307_TOUCH_SAMPLE_INTERVAL_SECONDS)
        self.reset_baseline()
        return True

    def reset_baseline(self):
        self.stable_level = self.pin.value()
        self.candidate_level = self.stable_level
        self.candidate_samples = 0
        self.initial_active_pending = False
        self.initial_active_samples = 0
