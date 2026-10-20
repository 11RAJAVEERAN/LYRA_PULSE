"""Read-only GPIO18 touch signal diagnostic; does not configure a pull resistor."""

try:
    import utime as time
except ImportError:  # pragma: no cover - host compatibility
    import time as _time

    class _CompatTime:
        @staticmethod
        def sleep_ms(milliseconds):
            _time.sleep(milliseconds / 1000)

        @staticmethod
        def ticks_ms():
            return int(_time.time() * 1000)

        @staticmethod
        def ticks_diff(end, start):
            return end - start

    time = _CompatTime()

from machine import Pin

from config import R307_TOUCH_PIN


SAMPLE_INTERVAL_MS = 10
DEBOUNCE_SAMPLES = 3
TEST_DURATION_SECONDS = 30


def main():
    pin = Pin(R307_TOUCH_PIN, Pin.IN)
    stable_value = pin.value()
    candidate_value = stable_value
    candidate_count = 0
    deadline = time.ticks_ms() + TEST_DURATION_SECONDS * 1000
    print(
        "[%d] [GPIO TEST] GPIO%d initial raw=%d; touch/release for %ds"
        % (time.ticks_ms(), R307_TOUCH_PIN, stable_value, TEST_DURATION_SECONDS)
    )

    while time.ticks_diff(deadline, time.ticks_ms()) > 0:
        raw_value = pin.value()
        if raw_value != candidate_value:
            candidate_value = raw_value
            candidate_count = 1
            print(
                "[%d] [GPIO TEST] GPIO%d raw transition=%d"
                % (time.ticks_ms(), R307_TOUCH_PIN, raw_value)
            )
        else:
            candidate_count += 1

        if candidate_count >= DEBOUNCE_SAMPLES and stable_value != candidate_value:
            stable_value = candidate_value
            print(
                "[%d] [GPIO TEST] GPIO%d debounced raw=%d"
                % (time.ticks_ms(), R307_TOUCH_PIN, stable_value)
            )
        time.sleep_ms(SAMPLE_INTERVAL_MS)
    print(
        "[%d] [GPIO TEST] Complete; final raw=%d (polarity not inferred)"
        % (time.ticks_ms(), stable_value)
    )


if __name__ == "__main__":
    main()
