"""Read-only GPIO18 transition diagnostic; configures no internal pull resistor."""

import time

from machine import Pin

from config import R307_TOUCH_PIN
from utils.logger import log


def main():
    pin = Pin(R307_TOUCH_PIN, Pin.IN)
    previous = pin.value()
    log("GPIO TEST", "GPIO%d initial raw=%d; touch and release to observe changes" % (
        R307_TOUCH_PIN,
        previous,
    ))
    last_report_tick = time.ticks_ms()

    while True:
        current = pin.value()
        tick = time.ticks_ms()
        if current != previous:
            log(
                "GPIO TEST",
                "GPIO%d transition %d->%d" % (R307_TOUCH_PIN, previous, current),
            )
            previous = current
            last_report_tick = tick
        elif time.ticks_diff(tick, last_report_tick) >= 1000:
            log("GPIO TEST", "GPIO%d steady raw=%d" % (R307_TOUCH_PIN, current))
            last_report_tick = tick
        time.sleep_ms(50)


if __name__ == "__main__":
    main()
