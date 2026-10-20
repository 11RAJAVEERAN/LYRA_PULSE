"""Safe R307 touch/capture diagnostic; does not call attendance APIs or store templates."""

import time

from config import (
    MAX_TEMPLATE_COUNT,
    R307_TOUCH_IMAGE_CAPTURE_TIMEOUT_SECONDS,
    R307_TOUCH_IMAGE_MAX_ATTEMPTS,
    R307_TOUCH_IMAGE_RETRY_INTERVAL_SECONDS,
)
from drivers.r307 import R307, R307FingerError, R307PacketError
from hardware.touch_sensor import TouchSensor
from utils.logger import log


def main():
    touch = TouchSensor()
    sensor = R307(debug=True)
    try:
        sensor.begin()
        log("DIAG", "R307 UART password verification succeeded")
    except R307PacketError as exc:
        log("DIAG ERROR", "R307 UART communication failed: %s" % exc)
        return False

    while True:
        log("DIAG", "Idle: GPIO18 raw=%d; waiting for stable touch" % touch.read_raw())
        touch.wait_for_touch()
        log("DIAG", "Touch confirmed; attempting image capture")

        captured = False
        start_tick = time.ticks_ms() if hasattr(time, "ticks_ms") else int(time.monotonic() * 1000)
        attempt = 0
        while True:
            now_tick = time.ticks_ms() if hasattr(time, "ticks_ms") else int(time.monotonic() * 1000)
            elapsed_ms = (
                time.ticks_diff(now_tick, start_tick)
                if hasattr(time, "ticks_diff")
                else now_tick - start_tick
            )
            if elapsed_ms >= R307_TOUCH_IMAGE_CAPTURE_TIMEOUT_SECONDS * 1000:
                log(
                    "DIAG ERROR",
                    "Capture timeout after %d ms and %d GenImg attempt(s)"
                    % (elapsed_ms, attempt),
                )
                break
            if attempt >= R307_TOUCH_IMAGE_MAX_ATTEMPTS:
                log(
                    "DIAG ERROR",
                    "Capture retry limit reached after %d attempts and %d ms"
                    % (attempt, elapsed_ms),
                )
                break
            if not touch.is_touched():
                log("DIAG", "Finger removed; stopping capture attempts")
                break
            attempt += 1
            log(
                "DIAG",
                "GenImg attempt %d; elapsed=%d ms; GPIO18 raw=%d"
                % (attempt, elapsed_ms, touch.read_raw()),
            )
            try:
                sensor.get_image(progress_callback=touch.log_raw_state)
                captured = True
                break
            except R307FingerError as exc:
                log("DIAG", "GenImg returned no image (0x02): %s" % exc)
                if not touch.is_touched():
                    log("DIAG", "Finger removed after GenImg response")
                    break
                remaining_seconds = (
                    R307_TOUCH_IMAGE_CAPTURE_TIMEOUT_SECONDS
                    - elapsed_ms / 1000
                )
                if remaining_seconds <= 0 or not touch.wait_while_touched(
                    min(R307_TOUCH_IMAGE_RETRY_INTERVAL_SECONDS, remaining_seconds)
                ):
                    if remaining_seconds > 0:
                        log("DIAG", "Finger removed during retry delay")
                    break
            except R307PacketError as exc:
                log("DIAG ERROR", "R307 packet/communication error: %s" % exc)
                break

        if captured:
            try:
                converted = sensor.image_to_template(buffer_id=1)
                log("DIAG", "Image conversion result=%s" % converted)
                if converted is not True:
                    log("DIAG ERROR", "Image conversion did not confirm success; skipping search")
                    converted = False
                if not converted:
                    match = None
                else:
                    match = sensor.search(
                        buffer_id=1,
                        start_page=0,
                        page_num=MAX_TEMPLATE_COUNT,
                    )
                if converted and match is None:
                    log("DIAG", "Search result: fingerprint not found")
                elif converted:
                    log(
                        "DIAG",
                        "Search result: slot=%s score=%s"
                        % (match["fingerprint_id"], match["score"]),
                    )
            except R307PacketError as exc:
                log("DIAG ERROR", "Conversion/search failed: %s" % exc)
        else:
            log("DIAG", "Capture failed; skipped conversion and search")

        log("DIAG", "Waiting for stable finger removal")
        touch.wait_for_removal()
        log("DIAG", "Finger removed; ready for next touch")


if __name__ == "__main__":
    main()
