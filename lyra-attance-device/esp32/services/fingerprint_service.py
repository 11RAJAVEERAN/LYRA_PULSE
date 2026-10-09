"""Fingerprint capture and matching orchestration."""

import time

from config import (
    ENROLLMENT_STEP_TIMEOUT_SECONDS,
    ENROLLMENT_TEMPLATE_ID,
    MAX_TEMPLATE_COUNT,
)
from drivers.r307 import (
    R307,
    R307CommunicationError,
    R307FingerError,
    R307ImageError,
    R307InvalidPacketError,
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
    def __init__(self, sensor):
        self.sensor = sensor

    def wait_for_finger(self, on_wait=None, poll_interval_seconds=3):
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

    def wait_for_finger_removed(self):
        while True:
            try:
                self.sensor.get_image()
                time.sleep(0.2)
            except R307FingerError:
                log("READY", "Finger removed")
                return True

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
