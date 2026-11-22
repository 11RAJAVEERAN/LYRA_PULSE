"""Main state-machine entry point for the Lyra Pulse attendance device."""

import time

from config import FINGERPRINT_COOLDOWN, FINGER_REMOVAL_SETTLE_SECONDS, FINGER_SLOT
from drivers.oled import OledDisplay
from drivers.r307 import R307, R307PacketError
from hardware.buzzer import Buzzer
from hardware.status_led import StatusLed
from hardware.touch_sensor import TouchSensor
from services.api_service import AttendanceAPIClient
from services.fingerprint_service import EnrollmentError, FingerprintService
from services.wifi_service import WiFiService
from utils.device_id import get_device_id
from utils.logger import log


def poll_enrollment_command(api_client, device_id):
    log("DEVICE", "Polling enrollment...")
    response = api_client.poll_enrollment(device_id)
    if not response.get("success"):
        log("DEVICE", "Enrollment poll failed (HTTP %s)" % response.get("status_code", "network error"))
        return None
    command = response.get("data")
    if isinstance(command, dict) and command.get("action") == "ENROLL_FINGERPRINT":
        log("ENROLL", "Enrollment found")
        log("ENROLL", "enrollment_id=%s" % command.get("enrollment_id"))
        log("ENROLL", "employee_id=%s" % command.get("employee_id"))
        log("ENROLL", "finger=%s" % command.get("finger"))
        return command
    log("DEVICE", "No pending enrollment")
    return None


def run_enrollment(command, device_id, api_client, fingerprint_service, oled, buzzer, led):
    oled.show_enrollment()
    led.green_off()
    try:
        fingerprint_service.enroll_from_command(command, oled, api_client, device_id)
        buzzer.success_beep()
        led.green_on()
    except EnrollmentError as exc:
        log("ENROLL", "Enrollment failed (%s): %s" % (exc.error_code, exc))
        response = api_client.report_enrollment_status(
            device_id,
            command.get("enrollment_id"),
            "FAILED",
            error_code=exc.error_code,
        )
        if not response.get("success"):
            log("ENROLL", "Could not record enrollment failure with the server")
        oled.show_enrollment_failed()
        buzzer.error_beep()
        led.red_on()
        time.sleep(1.5)
        led.red_off()
        led.green_on()


def show_feedback(oled, method_name, *args):
    try:
        getattr(oled, method_name)(*args)
    except Exception as exc:
        log("OLED ERROR", "%s failed: %s" % (method_name, exc))


def run_attendance_scan(device_id, api_client, fingerprint_service, oled, buzzer, led):
    finger_detected = False
    buzzer.off()
    led.ready_status()
    oled.show_ready()
    log("READY", "Ready state restored after finger removal")
    try:
        fingerprint_service.wait_for_finger()
        finger_detected = True
        capture_succeeded = fingerprint_service.capture_fingerprint()
        if capture_succeeded is False:
            if getattr(fingerprint_service, "capture_aborted", False):
                log("FINGER", "Touch removed before image capture; returning to ready")
                return
            log("FINGER", "Capture failed; no database search will be attempted")
            led.sensor_error()
            oled.show_image_capture_failed()
            return
        fingerprint_slot = fingerprint_service.search_fingerprint()
        if fingerprint_slot != FINGER_SLOT:
            if fingerprint_slot is not None:
                log(
                    "FINGER",
                    "Matched unauthorized slot %s; authorized slot is %s"
                    % (fingerprint_slot, FINGER_SLOT),
                )
            led.match_failed()
            buzzer.beep_twice()
            show_feedback(oled, "show_not_found")
            time.sleep(0.5)
            return

        log("API", "Authorized fingerprint slot %s; submitting attendance" % fingerprint_slot)
        response = api_client.send_attendance(device_id, fingerprint_slot)
        if not response.get("success"):
            details = response.get("error")
            if details is None:
                api_response = response.get("response")
                if isinstance(api_response, dict):
                    details = api_response.get("message") or api_response.get("errors")
            log(
                "API ERROR",
                "HTTP %s: %s"
                % (response.get("status_code", "unknown"), details or "request failed"),
            )
            led.api_error()
            oled.show_api_error()
            time.sleep(0.5)
            return

        data = response.get("data")
        if not isinstance(data, dict) or data.get("status") not in (
            "CHECKED_IN",
            "CHECKED_OUT",
        ):
            log("API ERROR", "Server returned an invalid attendance response")
            led.api_error()
            oled.show_api_error()
            time.sleep(0.5)
            return

        employee = data.get("employee")
        name = employee.get("name") if isinstance(employee, dict) else None
        if not isinstance(name, str) or not name.strip():
            log("API ERROR", "Attendance response did not include an employee name")
            led.api_error()
            oled.show_api_error()
            time.sleep(0.5)
            return
        name = name.strip()
        attendance_status = data["status"]
        log(
            "API",
            "HTTP %s resolved slot %s to %s: %s"
            % (
                response.get("http_status", "success"),
                fingerprint_slot,
                name,
                attendance_status,
            ),
        )
        led.match_success()
        buzzer.beep_once()
        show_feedback(
            oled,
            "show_attendance_success",
            name,
            attendance_status,
        )
        time.sleep(0.75)
    except R307PacketError as exc:
        log("SENSOR ERROR", str(exc))
        led.sensor_error()
        oled.show_sensor_error()
        buzzer.off()
        time.sleep(0.5)
    except Exception as exc:
        log("API ERROR", str(exc))
        led.api_error()
        oled.show_api_error()
        time.sleep(0.5)
    finally:
        if finger_detected:
            try:
                fingerprint_service.wait_for_finger_removed()
                time.sleep(FINGER_REMOVAL_SETTLE_SECONDS)
            except R307PacketError as exc:
                log("SENSOR ERROR", "Finger-removal check failed: %s" % exc)
        buzzer.off()
        led.ready_status()
        oled.show_ready()


def main():
    log("BOOT", "Lyra Pulse device starting")

    device_id = get_device_id()
    oled = OledDisplay()
    buzzer = Buzzer()
    led = StatusLed()
    touch_sensor = TouchSensor()
    wifi = WiFiService()
    r307 = R307(debug=True)
    api_client = AttendanceAPIClient()
    fingerprint_service = FingerprintService(r307, touch_sensor)

    oled.show_startup()
    buzzer.off()
    led.ready_status()

    sensor_ready = False
    try:
        r307.begin()
        sensor_ready = True
        log("R307", "Sensor initialized")
        led.ready_status()
        oled.show_ready()
    except R307PacketError as exc:  # pragma: no cover - hardware may not be attached during test
        log("SENSOR ERROR", "R307 init failed: %s" % exc)
        led.sensor_error()
        oled.show_sensor_error()
        time.sleep(1)

    if not wifi.ensure_connected():
        oled.show_api_error()
        led.ready_status()
        log("WIFI ERROR", "Connection failed; device will retry")

    while True:
        try:
            if not wifi.is_connected():
                oled.show_wifi_connecting()
                wifi.ensure_connected()
                if wifi.is_connected():
                    oled.show_wifi_connected()
                    time.sleep(1)
                else:
                    oled.show_api_error()
                    led.ready_status()
                    time.sleep(1)
                    continue

            if not sensor_ready:
                try:
                    r307.begin()
                    sensor_ready = True
                    log("R307", "Sensor initialized")
                except R307PacketError as exc:
                    log("SENSOR ERROR", "R307 initialization retry failed: %s" % exc)
                    led.sensor_error()
                    oled.show_sensor_error()
                    time.sleep(1)
                    continue

            led.ready_status()
            oled.show_ready()

            enrollment_command = poll_enrollment_command(api_client, device_id)
            if isinstance(enrollment_command, dict):
                run_enrollment(
                    enrollment_command,
                    device_id,
                    api_client,
                    fingerprint_service,
                    oled,
                    buzzer,
                    led,
                )
                fingerprint_service.wait_for_finger_removed()
                time.sleep(FINGERPRINT_COOLDOWN)
                continue

            run_attendance_scan(
                device_id,
                api_client,
                fingerprint_service,
                oled,
                buzzer,
                led,
            )

        except R307PacketError as exc:
            log("SENSOR ERROR", str(exc))
            led.sensor_error()
            oled.show_sensor_error()
            buzzer.off()
            time.sleep(1)
            led.ready_status()
            oled.show_ready()

        except Exception as exc:  # pragma: no cover
            log("ERROR", "Main loop exception: %s" % exc)
            oled.show_api_error()
            led.api_error()
            buzzer.off()
            time.sleep(1)
            led.ready_status()
            oled.show_ready()


if __name__ == "__main__":
    main()
