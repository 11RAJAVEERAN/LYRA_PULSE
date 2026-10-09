"""Main state-machine entry point for the Lyra Pulse attendance device."""

import time

from config import DEVICE_ID, FINGERPRINT_COOLDOWN, TEST_MODE
from drivers.oled import OledDisplay
from drivers.r307 import R307, R307TimeoutError, R307FingerError
from hardware.buzzer import Buzzer
from hardware.status_led import StatusLed
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


def run_attendance_scan(device_id, api_client, fingerprint_service, oled, buzzer, led):
    oled.show_ready()
    fingerprint_service.wait_for_finger()
    try:
        oled.show_finger_detected()
        oled.show_processing()
        fingerprint_service.capture_fingerprint()
        oled.show_searching()
        fingerprint_slot = fingerprint_service.search_fingerprint()
        if fingerprint_slot is None:
            oled.show_not_found()
            buzzer.error_beep()
            led.red_on()
            time.sleep(1)
            led.red_off()
            return

        response = api_client.send_attendance(device_id, fingerprint_slot)
        if not response.get("success"):
            log("ATTENDANCE", "Attendance request failed")
            oled.show_network_error()
            buzzer.error_beep()
            led.red_on()
            time.sleep(1)
            led.red_off()
            return

        data = response.get("data")
        if not isinstance(data, dict) or data.get("status") not in (
            "CHECKED_IN",
            "CHECKED_OUT",
        ):
            log("ATTENDANCE", "Server returned an invalid attendance response")
            oled.show_network_error()
            buzzer.error_beep()
            led.red_on()
            time.sleep(1)
            led.red_off()
            return

        employee = data.get("employee")
        name = employee.get("name", "Employee") if isinstance(employee, dict) else "Employee"
        log(
            "ATTENDANCE",
            "%s recorded for matched slot %s"
            % (data["status"], fingerprint_slot),
        )
        oled.show_attendance_success(name)
        buzzer.success_beep()
        led.green_on()
        time.sleep(1)
    finally:
        fingerprint_service.wait_for_finger_removed()


def main():
    log("BOOT", "Lyra Pulse device starting")

    device_id = get_device_id()
    oled = OledDisplay()
    buzzer = Buzzer()
    led = StatusLed()
    wifi = WiFiService()
    r307 = R307()
    api_client = AttendanceAPIClient()
    fingerprint_service = FingerprintService(r307)

    oled.show_startup()
    buzzer.startup_beep()
    led.green_off()
    led.red_off()

    try:
        r307.begin()
        log("R307", "Sensor initialized")
    except Exception as exc:  # pragma: no cover - hardware may not be attached during test
        log("ERROR", "R307 init failed: %s" % exc)
        oled.show_device_error()
        buzzer.error_beep()
        time.sleep(2)

    if not wifi.ensure_connected():
        oled.show_network_error()
        buzzer.error_beep()
        log("WIFI", "Connection failed; device continuing in offline monitoring mode")

    oled.show_ready()
    led.green_on()

    while True:
        try:
            if not wifi.is_connected():
                oled.show_wifi_connecting()
                wifi.ensure_connected()
                if wifi.is_connected():
                    oled.show_wifi_connected()
                    time.sleep(1)
                else:
                    oled.show_network_error()
                    buzzer.error_beep()
                    time.sleep(1)
                    continue

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
            time.sleep(FINGERPRINT_COOLDOWN)

        except (R307TimeoutError, R307FingerError) as exc:
            log("ERROR", "Fingerprint flow error: %s" % exc)
            oled.show_device_error()
            buzzer.error_beep()
            led.red_on()
            time.sleep(1.5)
            led.red_off()
            led.green_on()
            fingerprint_service.wait_for_finger_removed()

        except Exception as exc:  # pragma: no cover
            log("ERROR", "Main loop exception: %s" % exc)
            oled.show_device_error()
            buzzer.error_beep()
            led.red_on()
            time.sleep(2)
            led.red_off()
            led.green_on()


if __name__ == "__main__":
    main()
