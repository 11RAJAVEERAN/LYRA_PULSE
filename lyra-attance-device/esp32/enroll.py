"""Run a two-scan R307 enrollment, store it, then search the captured finger."""

import time

from config import (
    ENROLLMENT_STEP_TIMEOUT_SECONDS,
    ENROLLMENT_TEMPLATE_ID,
    MAX_TEMPLATE_COUNT,
)
from drivers.oled import OledDisplay
from drivers.r307 import R307, R307FingerError
from utils.logger import log


def _deadline(timeout_seconds):
    return time.ticks_add(time.ticks_ms(), timeout_seconds * 1000)


def _remaining(deadline):
    return time.ticks_diff(deadline, time.ticks_ms())


def _show(display, lines):
    display._show_lines(lines)


def _wait_for_finger(sensor, display, message):
    _show(display, message)
    print("ENROLL: %s" % " ".join(message))
    deadline = _deadline(ENROLLMENT_STEP_TIMEOUT_SECONDS)
    while _remaining(deadline) > 0:
        try:
            sensor.get_image()
            return
        except R307FingerError:
            time.sleep(0.1)
    raise RuntimeError("Timed out waiting for a fingerprint image")


def _wait_for_finger_removed(sensor, display):
    _show(display, ["Remove finger"])
    print("ENROLL: Remove finger")
    deadline = _deadline(ENROLLMENT_STEP_TIMEOUT_SECONDS)
    while _remaining(deadline) > 0:
        try:
            sensor.get_image()
            time.sleep(0.2)
        except R307FingerError:
            log("ENROLL", "Finger removed")
            return
    raise RuntimeError("Timed out waiting for finger removal")


def _enroll(sensor, display, template_id):
    _wait_for_finger(sensor, display, ["Place finger", "First scan"])
    if sensor.image_to_template(buffer_id=1) is not True:
        raise RuntimeError("First image conversion was not confirmed")
    log("ENROLL", "First image converted to buffer 1")

    _wait_for_finger_removed(sensor, display)
    _wait_for_finger(sensor, display, ["Place same finger", "Second scan"])
    if sensor.image_to_template(buffer_id=2) is not True:
        raise RuntimeError("Second image conversion was not confirmed")
    log("ENROLL", "Second image converted to buffer 2")

    _show(display, ["Creating template", "Please wait"])
    if sensor.create_model() is not True:
        raise RuntimeError("Template creation was not confirmed")
    log("ENROLL", "Template created by sensor")

    _show(display, ["Storing template", "ID: %s" % template_id])
    if sensor.store_model(template_id) is not True:
        raise RuntimeError("Template storage was not confirmed")
    log("ENROLL", "Sensor confirmed storage at ID %s" % template_id)


def main():
    template_id = ENROLLMENT_TEMPLATE_ID
    if not isinstance(template_id, int) or template_id < 0 or template_id >= MAX_TEMPLATE_COUNT:
        raise ValueError(
            "ENROLLMENT_TEMPLATE_ID must be between 0 and %s"
            % (MAX_TEMPLATE_COUNT - 1)
        )

    display = OledDisplay()
    sensor = R307()
    display.show_enrollment()

    try:
        sensor.begin()
        log("R307", "Sensor initialized for enrollment")
        _enroll(sensor, display, template_id)
    except Exception as exc:
        log("ENROLL", "Enrollment failed: %s" % exc)
        display.show_enrollment_failed()
        print("ENROLL: FAIL - %s" % exc)
        return False

    log("ENROLL", "Enrollment stored at ID %s" % template_id)
    print("ENROLL: STORED ID=%s (sensor acknowledged)" % template_id)
    display.show_enrollment_success()
    time.sleep(1)

    _show(display, ["Searching finger", "ID: %s" % template_id])
    log("FINGER", "Searching template store after enrollment")
    try:
        result = sensor.search(buffer_id=1, start_page=0, page_num=MAX_TEMPLATE_COUNT)
    except Exception as exc:
        log("FINGER", "Post-enrollment search failed: %s" % exc)
        _show(display, ["Search Failed", "Template stored"])
        print("SEARCH: FAIL - %s" % exc)
        return False

    if result is None:
        _show(display, ["Fingerprint", "Not Found"])
        log("FINGER", "Fingerprint not found after enrollment")
        print("SEARCH: FINGERPRINT NOT FOUND")
        return False

    matched_id = result["fingerprint_id"]
    score = result["score"]
    _show(display, ["Match Found", "ID: %s" % matched_id, "Score: %s" % score])
    log("FINGER", "Match found: id=%s score=%s" % (matched_id, score))
    print("SEARCH: MATCH ID=%s SCORE=%s" % (matched_id, score))
    return True


if __name__ == "__main__":
    main()
