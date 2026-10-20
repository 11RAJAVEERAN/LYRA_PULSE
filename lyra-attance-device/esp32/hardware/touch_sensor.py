"""Debounced, polarity-neutral edge detection for the R307 touch output."""

from machine import Pin

from config import (
    R307_TOUCH_ACTIVE_LEVEL,
    R307_TOUCH_DEBOUNCE_SAMPLES,
    R307_TOUCH_PIN,
)
from utils.logger import log


class TouchSensor:
    def __init__(self, pin=None, active_level=R307_TOUCH_ACTIVE_LEVEL):
        if active_level not in (None, 0, 1):
            raise ValueError("Touch active level must be None, 0, or 1")
        self.pin = pin if pin is not None else Pin(R307_TOUCH_PIN, Pin.IN)
        self.active_level = active_level
        self.stable_level = self.pin.value()
        self.candidate_level = self.stable_level
        self.candidate_samples = 0
        self.initial_active_pending = (
            active_level is not None and self.stable_level == active_level
        )
        log(
            "TOUCH",
            "GPIO%d monitoring started; baseline=%d active_level=%s"
            % (
                R307_TOUCH_PIN,
                self.stable_level,
                "either edge (unverified)"
                if active_level is None
                else active_level,
            ),
        )

    def poll_touch_edge(self):
        if self.initial_active_pending:
            self.initial_active_pending = False
            return True

        raw_level = self.pin.value()
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
            "GPIO%d debounced edge=%d->%d; requesting image confirmation"
            % (R307_TOUCH_PIN, previous_level, self.stable_level),
        )
        return True

    def reset_baseline(self):
        self.stable_level = self.pin.value()
        self.candidate_level = self.stable_level
        self.candidate_samples = 0
        self.initial_active_pending = False
