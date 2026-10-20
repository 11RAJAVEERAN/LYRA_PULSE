"""Fingerprint capture and matching orchestration."""

import time

from config import (
    ENROLLMENT_STEP_TIMEOUT_SECONDS,
    ENROLLMENT_TEMPLATE_ID,
    MAX_TEMPLATE_COUNT,
    R307_FINGER_REMOVAL_COOLDOWN_SECONDS,
    R307_FINGER_REMOVAL_TIMEOUT_SECONDS,
    R307_DETECTION_MODE,
    R307_UART_FALLBACK_ENABLED,
    R307_UART_FALLBACK_INTERVAL_SECONDS,
    R307_TOUCH_CAPTURE_MAX_ATTEMPTS,
    R307_TOUCH_CAPTURE_RETRY_INTERVAL_SECONDS,
    R307_TOUCH_CAPTURE_TIMEOUT_SECONDS,
    R307_TOUCH_SAMPLE_INTERVAL_SECONDS,
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


def _ticks_ms():
    if hasattr(time, "ticks_ms"):
        return time.ticks_ms()
    return int(time.time() * 1000)


def _ticks_diff(end, start):
    if hasattr(time, "ticks_diff"):
        return time.ticks_diff(end, start)
    return end - start


def _ticks_add(ticks, delta):
    if hasattr(time, "ticks_add"):
        return time.ticks_add(ticks, delta)
    return ticks + delta


class EnrollmentError(Exception):
    def __init__(self, error_code, message):
        self.message = message
        self.error_code = error_code

    def __str__(self):
        return self.message


class FingerprintService:
    FINGER_REMOVAL_CONFIRMATIONS = 3

    def __init__(self, sensor, touch_sensor=None):
        self.sensor = sensor
        self.touch_sensor = touch_sensor
        self._recovery_delay_seconds = 2
        self._sensor_available = True
        self._fallback_errors = 0
        self._awaiting_removal = False
        self._removal_rearm_deadline = None

    def _retry_sensor_initialization(self, phase):
        log(
            "SENSOR",
            "Sensor unavailable during %s; retrying VerifyPassword after %ds"
            % (phase, self._recovery_delay_seconds),
        )
        time.sleep(self._recovery_delay_seconds)
        try:
            self.sensor.begin()
        except R307PacketError as recovery_error:
            log(
                "SENSOR",
                "Sensor reinitialization failed during %s (%s: %s); "
                "next retry in %ds"
                % (
                    phase,
                    recovery_error.__class__.__name__,
                    recovery_error,
                    min(self._recovery_delay_seconds * 2, 30),
                ),
            )
            self._recovery_delay_seconds = min(
                self._recovery_delay_seconds * 2,
                30,
            )
            return False

        self._sensor_available = True
        self._recovery_delay_seconds = 2
        log("SENSOR", "Sensor communication recovered during %s" % phase)
        return True

    def _recover_from_poll_error(self, error, consecutive_errors, phase):
        if consecutive_errors == 1 or consecutive_errors % 3 == 0:
            log(
                "SENSOR",
                "Temporary %s during %s; retry=%d: %s"
                % (
                    error.__class__.__name__,
                    phase,
                    consecutive_errors,
                    error,
                ),
            )

        if consecutive_errors % 3 == 0:
            self._sensor_available = False
            self._retry_sensor_initialization(phase)
            return 0

        retry_delay = min(0.25 * (2 ** min(consecutive_errors - 1, 4)), 4)
        time.sleep(retry_delay)
        return consecutive_errors

    def wait_for_finger(
        self,
        on_wait=None,
        poll_interval_seconds=3,
        detection_mode=R307_DETECTION_MODE,
        uart_fallback_enabled=R307_UART_FALLBACK_ENABLED,
    ):
        if self.touch_sensor is None and detection_mode != "uart_fallback":
            raise RuntimeError("A touch sensor is required to wait for a finger")
        if detection_mode not in ("gpio_only", "hybrid", "uart_fallback"):
            raise ValueError("Unsupported fingerprint detection mode: %s" % detection_mode)
        if detection_mode == "uart_fallback" and not uart_fallback_enabled:
            raise ValueError("uart_fallback mode requires UART fallback to be enabled")

        polls_per_callback = max(
            1,
            int(poll_interval_seconds / R307_TOUCH_SAMPLE_INTERVAL_SECONDS),
        )
        polls_remaining = polls_per_callback
        fallback_enabled = (
            uart_fallback_enabled
            and detection_mode in ("hybrid", "uart_fallback")
        )
        fallback_interval_seconds = max(
            2.0,
            R307_UART_FALLBACK_INTERVAL_SECONDS,
        )
        polls_per_fallback = max(
            1,
            int(
                fallback_interval_seconds
                / R307_TOUCH_SAMPLE_INTERVAL_SECONDS
            ),
        )
        fallback_polls_remaining = polls_per_fallback
        log(
            "SCAN",
            "Detection mode=%s UART fallback=%s interval=%.1fs"
            % (
                detection_mode,
                "enabled" if fallback_enabled else "disabled",
                fallback_interval_seconds,
            ),
        )
        log("SCAN", "state=READY_WAITING_FOR_TOUCH")
        while True:
            if self._awaiting_removal:
                if not self.wait_for_finger_removed():
                    return False
            if self._removal_rearm_deadline is not None:
                remaining_ms = _ticks_diff(
                    self._removal_rearm_deadline,
                    _ticks_ms(),
                )
                if remaining_ms > 0:
                    time.sleep(min(remaining_ms / 1000.0, 0.25))
                    continue
                self._removal_rearm_deadline = None
                log(
                    "SCAN",
                    "Removal recovery cooldown ended; scanner rearmed by timeout policy",
                )

            if not self._sensor_available:
                self._retry_sensor_initialization("WAITING_FOR_TOUCH")
                continue

            touch_edge = (
                detection_mode != "uart_fallback"
                and self.touch_sensor.poll_touch_edge()
            )
            fallback_due = fallback_enabled and fallback_polls_remaining <= 0
            if touch_edge or fallback_due:
                if touch_edge:
                    self._awaiting_removal = True
                    log("SCAN", "GPIO18 touch edge; confirming image with GetImage")
                    log("SCAN", "state=CAPTURING_IMAGE")
                    if self._capture_after_touch():
                        log("FINGER", "GetImage confirmed a captured image")
                        return True

                    log("SCAN", "Capture window expired; waiting for removal before rearming")
                    if not self.wait_for_finger_removed():
                        return False
                    polls_remaining = polls_per_callback
                    fallback_polls_remaining = polls_per_fallback
                else:
                    if self._poll_uart_fallback():
                        log("FINGER", "UART fallback confirmed a captured image")
                        return True
                    fallback_polls_remaining = polls_per_fallback

            if on_wait is not None and polls_remaining <= 0:
                command = on_wait()
                polls_remaining = polls_per_callback
                if command is not None:
                    return command

            time.sleep(R307_TOUCH_SAMPLE_INTERVAL_SECONDS)
            polls_remaining -= 1
            fallback_polls_remaining -= 1

    def _poll_uart_fallback(self):
        try:
            self.sensor.get_image()
            self._recovery_delay_seconds = 2
            self._sensor_available = True
            self._fallback_errors = 0
            self._awaiting_removal = True
            return True
        except R307FingerError:
            self._fallback_errors = 0
            return False
        except R307ImageError as exc:
            self._fallback_errors = 0
            log("SENSOR", "UART fallback image status error: %s" % exc)
            return False
        except R307PacketError as exc:
            log(
                "SENSOR",
                "UART fallback communication error (%s): %s"
                % (exc.__class__.__name__, exc),
            )
            self._fallback_errors += 1
            self._fallback_errors = self._recover_from_poll_error(
                exc,
                self._fallback_errors,
                "UART_FALLBACK",
            )
            return False

    def _capture_after_touch(self):
        consecutive_errors = 0
        capture_started = _ticks_ms()
        for attempt in range(1, R307_TOUCH_CAPTURE_MAX_ATTEMPTS + 1):
            if (
                _ticks_diff(_ticks_ms(), capture_started)
                >= R307_TOUCH_CAPTURE_TIMEOUT_SECONDS * 1000
            ):
                break
            if not self._sensor_available:
                self._retry_sensor_initialization("CAPTURING_IMAGE")
                time.sleep(R307_TOUCH_CAPTURE_RETRY_INTERVAL_SECONDS)
                continue

            try:
                self.sensor.get_image()
                self._recovery_delay_seconds = 2
                self._sensor_available = True
                self._awaiting_removal = True
                return True
            except R307FingerError:
                consecutive_errors = 0
                self._recovery_delay_seconds = 2
                self._sensor_available = True
                if attempt == 1 or attempt % 10 == 0:
                    log(
                        "SCAN",
                        "GetImage reports no usable image (0x02); attempt %d/%d"
                        % (attempt, R307_TOUCH_CAPTURE_MAX_ATTEMPTS),
                    )
            except R307ImageError as exc:
                consecutive_errors = 0
                log("SENSOR", "GetImage image status error; retrying: %s" % exc)
            except R307PacketError as exc:
                consecutive_errors += 1
                consecutive_errors = self._recover_from_poll_error(
                    exc,
                    consecutive_errors,
                    "CAPTURING_IMAGE",
                )

            time.sleep(R307_TOUCH_CAPTURE_RETRY_INTERVAL_SECONDS)

        log(
            "SENSOR",
            "No confirmed image within %ds or %d GetImage attempts"
            % (
                R307_TOUCH_CAPTURE_TIMEOUT_SECONDS,
                R307_TOUCH_CAPTURE_MAX_ATTEMPTS,
            ),
        )
        return False

    def wait_for_finger_removed(self):
        consecutive_errors = 0
        consecutive_no_finger = 0
        started = _ticks_ms()
        log("SCAN", "state=WAITING_FOR_REMOVAL")
        while True:
            if (
                _ticks_diff(_ticks_ms(), started)
                >= R307_FINGER_REMOVAL_TIMEOUT_SECONDS * 1000
            ):
                log(
                    "SENSOR",
                    "Finger removal was not confirmed within %ds; applying "
                    "bounded cooldown before scanner rearm"
                    % R307_FINGER_REMOVAL_TIMEOUT_SECONDS,
                )
                self._awaiting_removal = False
                self._removal_rearm_deadline = _ticks_add(
                    started,
                    (
                        R307_FINGER_REMOVAL_TIMEOUT_SECONDS
                        + R307_FINGER_REMOVAL_COOLDOWN_SECONDS
                    )
                    * 1000,
                )
                if self.touch_sensor is not None:
                    self.touch_sensor.reset_baseline()
                return False
            if not self._sensor_available:
                self._retry_sensor_initialization("WAITING_FOR_REMOVAL")
                continue
            try:
                self.sensor.get_image()
                consecutive_errors = 0
                consecutive_no_finger = 0
                self._recovery_delay_seconds = 2
                self._sensor_available = True
                time.sleep(0.2)
            except R307FingerError:
                consecutive_errors = 0
                consecutive_no_finger += 1
                if consecutive_no_finger >= self.FINGER_REMOVAL_CONFIRMATIONS:
                    log(
                        "READY",
                        "Finger removal confirmed after %d consecutive GetImage no-finger responses"
                        % consecutive_no_finger,
                    )
                    if self.touch_sensor is not None:
                        self.touch_sensor.reset_baseline()
                    self._awaiting_removal = False
                    return True
                time.sleep(0.1)
            except R307PacketError as exc:
                consecutive_errors += 1
                consecutive_no_finger = 0
                consecutive_errors = self._recover_from_poll_error(
                    exc,
                    consecutive_errors,
                    "WAITING_FOR_REMOVAL",
                )

    def capture_fingerprint(self):
        return self.sensor.image_to_template(buffer_id=1)

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
        remaining_tenths = timeout_seconds * 10
        while remaining_tenths > 0:
            try:
                self.sensor.get_image()
                self._awaiting_removal = True
                log("ENROLL", "GetImage succeeded")
                return
            except R307FingerError:
                time.sleep(0.1)
                remaining_tenths -= 1
        raise EnrollmentError("SENSOR_TIMEOUT", "Timed out waiting for a finger")

    def _wait_for_finger_removed(self, display, timeout_seconds):
        log("ENROLL", "Waiting for finger removal")
        display.show_enrollment_remove_finger()
        remaining_tenths = timeout_seconds * 10
        while remaining_tenths > 0:
            try:
                self.sensor.get_image()
                time.sleep(0.1)
                remaining_tenths -= 1
            except R307FingerError:
                log("ENROLL", "Finger removed")
                self._awaiting_removal = False
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
