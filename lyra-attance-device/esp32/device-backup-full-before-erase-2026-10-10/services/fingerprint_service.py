"""Fingerprint capture and matching orchestration."""

import time

from config import (
    ENROLLMENT_STEP_TIMEOUT_SECONDS,
    ENROLLMENT_TEMPLATE_ID,
    MAX_TEMPLATE_COUNT,
    R307_TOUCH_IMAGE_CAPTURE_TIMEOUT_SECONDS,
    R307_TOUCH_IMAGE_MAX_ATTEMPTS,
    R307_TOUCH_IMAGE_RETRY_INTERVAL_SECONDS,
    R307_TOUCH_GPIO_WAIT_SECONDS,
    R307_TOUCH_PIN,
    R307_TOUCH_UART_FALLBACK_ENABLED,
    R307_TOUCH_UART_FALLBACK_POLL_INTERVAL_SECONDS,
    R307_TOUCH_UART_REMOVAL_CONFIRMATIONS,
)
from drivers.r307 import (
    R307,
    R307CommunicationError,
    R307FingerError,
    R307ImageError,
    R307InvalidPacketError,
    R307PacketError,
    R307TemplateError,
    R307TimeoutError,
)
from utils.logger import log


class EnrollmentError(Exception):
    def __init__(self, error_code, message):
        self.message = message
        self.error_code = error_code

    def __str__(self):
        return self.message


class FingerprintService:
    def __init__(self, sensor, touch_sensor=None):
        self.sensor = sensor
        self.touch_sensor = touch_sensor
        self.capture_aborted = False
        self._image_already_captured = False
        self._uart_fallback_active = False

    def wait_for_finger(self, on_wait=None, poll_interval_seconds=3):
        if self.touch_sensor is not None and on_wait is None:
            log(
                "READY",
                "Waiting %.1f s for stable GPIO%d idle, then a new HIGH touch"
                % (R307_TOUCH_GPIO_WAIT_SECONDS, R307_TOUCH_PIN),
            )
            if self.touch_sensor.wait_for_new_touch(
                R307_TOUCH_GPIO_WAIT_SECONDS
            ):
                log(
                    "FINGER",
                    "GPIO%d new touch confirmed; starting capture" % R307_TOUCH_PIN,
                )
                return True
            if not R307_TOUCH_UART_FALLBACK_ENABLED:
                return False
            return self._wait_for_finger_by_uart()

        polls_remaining = poll_interval_seconds * 10
        while True:
            if on_wait is not None and polls_remaining <= 0:
                command = on_wait()
                polls_remaining = poll_interval_seconds * 10
                if command is not None:
                    return command
            try:
                self.sensor.get_image()
                log("FINGER", "Finger detected")
                return True
            except R307FingerError:
                time.sleep(0.1)
                polls_remaining -= 1

    def _wait_for_finger_by_uart(self):
        self._uart_fallback_active = True
        self._image_already_captured = False
        log(
            "FINGER",
            "GPIO%d did not assert; using R307 GenImg polling fallback"
            % R307_TOUCH_PIN,
        )
        while True:
            try:
                log(
                    "FINGER",
                    "UART fallback GenImg poll; GPIO%d raw=%d"
                    % (R307_TOUCH_PIN, self.touch_sensor.read_raw()),
                )
                self.sensor.get_image(
                    progress_callback=self.touch_sensor.log_raw_state
                )
                self._image_already_captured = True
                log(
                    "FINGER",
                    "UART fallback captured image; continuing directly to Image2Tz"
                )
                return True
            except R307FingerError:
                time.sleep(R307_TOUCH_UART_FALLBACK_POLL_INTERVAL_SECONDS)

    def wait_for_finger_removed(self):
        if self.touch_sensor is not None:
            if self._uart_fallback_active:
                log(
                    "READY",
                    "Waiting for %d consecutive GenImg no-image responses as removal confirmation"
                    % R307_TOUCH_UART_REMOVAL_CONFIRMATIONS,
                )
                no_image_count = 0
                while no_image_count < R307_TOUCH_UART_REMOVAL_CONFIRMATIONS:
                    try:
                        self.sensor.get_image(
                            progress_callback=self.touch_sensor.log_raw_state
                        )
                        no_image_count = 0
                    except R307FingerError:
                        no_image_count += 1
                        log(
                            "READY",
                            "UART removal confirmation %d/%d"
                            % (
                                no_image_count,
                                R307_TOUCH_UART_REMOVAL_CONFIRMATIONS,
                            ),
                        )
                    time.sleep(R307_TOUCH_UART_FALLBACK_POLL_INTERVAL_SECONDS)
                self._uart_fallback_active = False
                self._image_already_captured = False
                log("READY", "Finger removal confirmed by R307 image polling")
                return True
            self.touch_sensor.wait_for_removal()
            log("READY", "Finger removed")
            return True

        while True:
            try:
                self.sensor.get_image()
                time.sleep(0.2)
            except R307FingerError:
                log("READY", "Finger removed")
                return True

    @staticmethod
    def _ticks_ms():
        ticks_ms = getattr(time, "ticks_ms", None)
        if ticks_ms is not None:
            return ticks_ms()
        return int(time.monotonic() * 1000)

    @staticmethod
    def _elapsed_ms(start_tick, current_tick):
        ticks_diff = getattr(time, "ticks_diff", None)
        if ticks_diff is not None:
            return ticks_diff(current_tick, start_tick)
        return current_tick - start_tick

    def _capture_touched_image(self, timeout_seconds):
        touch_sensor = self.touch_sensor
        if touch_sensor is None:
            raise RuntimeError("Touch sensor is required for touch-triggered capture")
        start_tick = self._ticks_ms()
        timeout_ms = int(timeout_seconds * 1000)
        attempt = 0
        while True:
            if not touch_sensor.is_touched():
                self.capture_aborted = True
                log(
                    "FINGER",
                    "Finger removed before GenImg attempt %d; capture stopped (GPIO%d raw=%d)"
                    % (attempt + 1, R307_TOUCH_PIN, touch_sensor.read_raw()),
                )
                return False
            if attempt >= R307_TOUCH_IMAGE_MAX_ATTEMPTS:
                elapsed_ms = self._elapsed_ms(start_tick, self._ticks_ms())
                log(
                    "FINGER",
                    "Capture retry limit reached after %d attempts and %d ms; GPIO%d raw=%d"
                    % (
                        attempt,
                        elapsed_ms,
                        R307_TOUCH_PIN,
                        touch_sensor.read_raw(),
                    ),
                )
                return False
            elapsed_ms = self._elapsed_ms(start_tick, self._ticks_ms())
            if elapsed_ms >= timeout_ms:
                log(
                    "FINGER",
                    "Capture timeout after %d ms and %d GenImg attempt(s); GPIO%d raw=%d"
                    % (elapsed_ms, attempt, R307_TOUCH_PIN, touch_sensor.read_raw()),
                )
                return False
            attempt += 1
            log(
                "FINGER",
                "GenImg attempt %d; elapsed=%d ms; GPIO%d raw=%d"
                % (
                    attempt,
                    elapsed_ms,
                    R307_TOUCH_PIN,
                    touch_sensor.read_raw(),
                ),
            )
            try:
                self.sensor.get_image(progress_callback=touch_sensor.log_raw_state)
                log(
                    "FINGER",
                    "Image capture succeeded on GenImg attempt %d after %d ms"
                    % (attempt, self._elapsed_ms(start_tick, self._ticks_ms())),
                )
                return True
            except R307FingerError as exc:
                log("FINGER", "GenImg returned no image (0x02): %s" % exc)
                if not touch_sensor.is_touched():
                    self.capture_aborted = True
                    log(
                        "FINGER",
                        "Finger removed after GenImg attempt %d; capture stopped (GPIO%d raw=%d)"
                        % (attempt, R307_TOUCH_PIN, touch_sensor.read_raw()),
                    )
                    return False
                elapsed_ms = self._elapsed_ms(start_tick, self._ticks_ms())
                remaining_ms = timeout_ms - elapsed_ms
                if remaining_ms <= 0:
                    log(
                        "FINGER",
                        "Capture timeout after %d ms and %d GenImg attempt(s); GPIO%d raw=%d"
                        % (elapsed_ms, attempt, R307_TOUCH_PIN, touch_sensor.read_raw()),
                    )
                    return False
                retry_delay = min(
                    R307_TOUCH_IMAGE_RETRY_INTERVAL_SECONDS,
                    remaining_ms / 1000,
                )
                if not touch_sensor.wait_while_touched(retry_delay):
                    self.capture_aborted = True
                    log(
                        "FINGER",
                        "Finger removed during retry delay after GenImg attempt %d (GPIO%d raw=%d)"
                        % (attempt, R307_TOUCH_PIN, touch_sensor.read_raw()),
                    )
                    return False

    def capture_fingerprint(self):
        self.capture_aborted = False
        if self._image_already_captured:
            self._image_already_captured = False
            captured = True
            log("FINGER", "Using image already captured by UART fallback")
        elif self.touch_sensor is not None and not self._uart_fallback_active:
            if not self._capture_touched_image(
                R307_TOUCH_IMAGE_CAPTURE_TIMEOUT_SECONDS
            ):
                return False
            captured = True
        else:
            captured = self.sensor.get_image()
        if not captured:
            return False
        converted = self.sensor.image_to_template(buffer_id=1)
        log("FINGER", "Image conversion result=%s" % converted)
        if converted is not True:
            log("FINGER", "Image conversion did not confirm success; skipping search")
            return False
        return True

    def convert_fingerprint(self):
        return self.sensor.image_to_template(buffer_id=1)

    def search_fingerprint(self):
        result = self.sensor.search(
            buffer_id=1,
            start_page=0,
            page_num=MAX_TEMPLATE_COUNT,
        )
        if result is None:
            log("FINGER", "No match found")
            return None
        fingerprint_id = result.get("fingerprint_id")
        score = result.get("score")
        log("FINGER", "Match found: id=%s score=%s" % (fingerprint_id, score))
        return fingerprint_id

    def enroll_fingerprint(self, template_id):
        self.sensor.create_model()
        self.sensor.store_model(template_id)
        log("FINGER", "Enrollment stored at template ID %s" % template_id)
        return True

    def _wait_for_finger(self, display, prompt, timeout_seconds):
        step = prompt.replace("Place finger ", "").replace("Same finger ", "")
        log("ENROLL", "Waiting for finger %s" % step)
        display.show_enrollment_prompt(prompt)
        log("R307", "GetImage")
        if self.touch_sensor is not None:
            if not self.touch_sensor.wait_for_touch(timeout_seconds):
                raise EnrollmentError("SENSOR_TIMEOUT", "Timed out waiting for a finger")
            if not self._capture_touched_image(
                min(timeout_seconds, R307_TOUCH_IMAGE_CAPTURE_TIMEOUT_SECONDS)
            ):
                self.touch_sensor.wait_for_removal(timeout_seconds)
                raise EnrollmentError(
                    "IMAGE_CAPTURE_FAILED",
                    "Touch ended before the sensor captured a fingerprint image",
                )
            log("ENROLL", "GetImage succeeded")
            return

        remaining_tenths = timeout_seconds * 10
        while remaining_tenths > 0:
            try:
                self.sensor.get_image()
                log("ENROLL", "GetImage succeeded")
                return
            except R307FingerError:
                time.sleep(0.1)
                remaining_tenths -= 1
        raise EnrollmentError("SENSOR_TIMEOUT", "Timed out waiting for a finger")

    def _wait_for_finger_removed(self, display, timeout_seconds):
        log("ENROLL", "Waiting for finger removal")
        display.show_enrollment_remove_finger()
        if self.touch_sensor is not None:
            if not self.touch_sensor.wait_for_removal(timeout_seconds):
                raise EnrollmentError(
                    "SENSOR_TIMEOUT", "Timed out waiting for the finger to be removed"
                )
            log("ENROLL", "Finger removed")
            return

        remaining_tenths = timeout_seconds * 10
        while remaining_tenths > 0:
            try:
                self.sensor.get_image()
                time.sleep(0.1)
                remaining_tenths -= 1
            except R307FingerError:
                log("ENROLL", "Finger removed")
                return
        raise EnrollmentError("SENSOR_TIMEOUT", "Timed out waiting for the finger to be removed")

    @staticmethod
    def _report(api_client, device_id, enrollment_id, status, fingerprint_slot=None):
        response = api_client.report_enrollment_status(
            device_id,
            enrollment_id,
            status,
            fingerprint_slot=fingerprint_slot,
        )
        if not response.get("success"):
            raise EnrollmentError("DEVICE_API_ERROR", "Could not report enrollment progress")
        data = response.get("data")
        if not isinstance(data, dict) or data.get("status") != status:
            raise EnrollmentError("DEVICE_API_ERROR", "Server did not confirm enrollment progress")
        if fingerprint_slot is not None and data.get("fingerprint_slot") != fingerprint_slot:
            raise EnrollmentError("SLOT_VERIFICATION_FAILED", "Server confirmed a different fingerprint slot")
        return data

    def enroll_from_command(self, command, display, api_client, device_id):
        enrollment_id = command.get("enrollment_id")
        if not enrollment_id or command.get("action") != "ENROLL_FINGERPRINT":
            raise EnrollmentError("UNKNOWN", "Invalid enrollment command")

        timeout_seconds = ENROLLMENT_STEP_TIMEOUT_SECONDS
        try:
            self._wait_for_finger(display, "Place finger 1/3", timeout_seconds)
            log("R307", "Image2Tz buffer 1")
            self.sensor.image_to_template(buffer_id=1)
            log("ENROLL", "Image2Tz succeeded: buffer 1")

            self._wait_for_finger_removed(display, timeout_seconds)
            self._report(
                api_client,
                device_id,
                enrollment_id,
                "WAITING_FOR_SECOND_SCAN",
            )

            self._wait_for_finger(display, "Same finger 2/3", timeout_seconds)
            log("R307", "Image2Tz buffer 2")
            self.sensor.image_to_template(buffer_id=2)
            log("ENROLL", "Image2Tz succeeded: buffer 2")
            self._report(api_client, device_id, enrollment_id, "PROCESSING")

            log("R307", "CreateTemplate")
            self.sensor.create_model()
            log("ENROLL", "CreateTemplate succeeded")
            duplicate = self.sensor.search(
                buffer_id=1,
                start_page=0,
                page_num=MAX_TEMPLATE_COUNT,
            )
            if duplicate is not None:
                raise EnrollmentError(
                    "DUPLICATE_FINGERPRINT",
                    "Finger already exists in sensor slot %s" % duplicate["fingerprint_id"],
                )
            log("ENROLL", "Duplicate search found no existing match")
            slot = self.sensor.find_free_template_slot(
                MAX_TEMPLATE_COUNT,
                start_page=ENROLLMENT_TEMPLATE_ID,
                buffer_id=2,
            )
            log("R307", "StoreTemplate slot %s" % slot)
            self.sensor.store_model(slot, buffer_id=1)
            log("ENROLL", "StoreTemplate acknowledged for actual slot %s" % slot)

            self._wait_for_finger_removed(display, timeout_seconds)
            self._wait_for_finger(display, "Place finger 3/3", timeout_seconds)
            log("R307", "Image2Tz verification buffer 1")
            self.sensor.image_to_template(buffer_id=1)
            log("ENROLL", "Image2Tz succeeded: verification buffer 1")
            log("R307", "Verification search")
            verification = self.sensor.search(
                buffer_id=1,
                start_page=0,
                page_num=MAX_TEMPLATE_COUNT,
            )
            if verification is None or verification["fingerprint_id"] != slot:
                raise EnrollmentError(
                    "SLOT_VERIFICATION_FAILED",
                    "Sensor search did not confirm the newly stored slot",
                )

            self._report(
                api_client,
                device_id,
                enrollment_id,
                "SUCCESS",
                fingerprint_slot=slot,
            )
            display.show_enrollment_success(slot)
            log("ENROLL", "Third scan verified actual slot %s" % slot)
            return slot
        except EnrollmentError:
            raise
        except R307TimeoutError as exc:
            raise EnrollmentError("SENSOR_TIMEOUT", str(exc))
        except R307ImageError as exc:
            raise EnrollmentError("IMAGE_CAPTURE_FAILED", str(exc))
        except R307CommunicationError as exc:
            raise EnrollmentError("SENSOR_COMMUNICATION_ERROR", str(exc))
        except R307InvalidPacketError as exc:
            raise EnrollmentError("SENSOR_COMMUNICATION_ERROR", str(exc))
        except R307TemplateError as exc:
            message = str(exc)
            normalized_message = message.lower()
            if "template store is full" in normalized_message:
                code = "SENSOR_FULL"
            elif "image conversion failed" in normalized_message:
                code = "POOR_IMAGE"
            elif "model generation failed" in normalized_message:
                code = "TEMPLATE_CREATE_FAILED"
            elif "storage failed" in normalized_message:
                code = "STORAGE_FAILED"
            elif "template load failed" in normalized_message:
                code = "SENSOR_TEMPLATE_READ_ERROR"
            else:
                code = "UNKNOWN"
            raise EnrollmentError(code, message)

    def delete_fingerprint(self, template_id):
        self.sensor.delete_template(template_id)
        return True
