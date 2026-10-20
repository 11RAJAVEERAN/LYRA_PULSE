"""Main state-machine entry point for the Lyra Pulse attendance device."""

import time

from config import FINGERPRINT_COOLDOWN, FINGER_REMOVAL_SETTLE_SECONDS
from drivers.oled import OledDisplay
from drivers.r307 import R307, R307CommunicationError, R307PacketError
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
    sensor_faulted = False
    try:
        fingerprint_service.enroll_from_command(command, oled, api_client, device_id)
        buzzer.success_beep()
        led.green_on()
    except EnrollmentError as exc:
        sensor_faulted = exc.error_code in (
            "SENSOR_TIMEOUT",
            "SENSOR_COMMUNICATION_ERROR",
        )
        log("ENROLL", "Enrollment failed (%s): %s" % (exc.error_code, exc))
        response = api_client.report_enrollment_status(
            device_id,
            command.get("enrollment_id"),
            "FAILED",
            error_code=exc.error_code,
        )
        if not response.get("success"):
            log("ENROLL", "Could not record enrollment failure with the server")
        if sensor_faulted:
            oled.show_sensor_error()
            led.sensor_error()
            buzzer.off()
        else:
            oled.show_enrollment_failed()
            buzzer.error_beep()
            led.red_on()
            time.sleep(1.5)
            led.red_off()
            led.green_on()
    return sensor_faulted


def show_feedback(oled, method_name, *args):
    try:
        getattr(oled, method_name)(*args)
    except Exception as exc:
        log("OLED ERROR", "%s failed: %s" % (method_name, exc))


def run_attendance_scan(
    device_id,
    api_client,
    fingerprint_service,
    oled,
    buzzer,
    led,
    on_wait=None,
):
    finger_detected = False
    sensor_faulted = False
    led.ready_status()
    oled.show_ready()
    try:
        if on_wait is None:
            image_ready = fingerprint_service.wait_for_finger()
        else:
            image_ready = fingerprint_service.wait_for_finger(on_wait=on_wait)
        if image_ready is not True:
            raise R307CommunicationError(
                "GetImage did not confirm a captured image; conversion skipped"
            )
        finger_detected = True
        oled.show_finger_detected()
        log("SCAN", "state=CONVERTING_IMAGE")
        log("SCAN", "GetImage ACK=0x00; converting captured image once")
        oled.show_processing()
        fingerprint_service.capture_fingerprint()
        log("SCAN", "state=SEARCHING")
        oled.show_searching()
        fingerprint_slot = fingerprint_service.search_fingerprint()
        if fingerprint_slot is None:
            log("SCAN", "state=MATCH_FAILURE")
            led.match_failed()
            buzzer.beep_twice()
            show_feedback(oled, "show_not_found")
            time.sleep(0.5)
            return

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
        log("SCAN", "state=MATCH_SUCCESS")
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
        sensor_faulted = True
        log(
            "SENSOR",
            "Temporary %s; scan will retry after recovery: %s"
            % (exc.__class__.__name__, exc),
        )
        show_feedback(oled, "show_sensor_error")
        led.sensor_error()
        buzzer.off()
        time.sleep(0.25)
    except Exception as exc:
        log("API ERROR", str(exc))
        led.api_error()
        oled.show_api_error()
        time.sleep(0.5)
    finally:
        if finger_detected:
            try:
                if fingerprint_service.wait_for_finger_removed():
                    time.sleep(FINGER_REMOVAL_SETTLE_SECONDS)
                else:
                    sensor_faulted = True
                    show_feedback(oled, "show_sensor_error")
                    led.sensor_error()
                    buzzer.off()
            except R307PacketError as exc:
                sensor_faulted = True
                log(
                    "SENSOR",
                    "Removal polling failed (%s); will retry"
                    % exc.__class__.__name__,
                )
                show_feedback(oled, "show_sensor_error")
                led.sensor_error()
                buzzer.off()
        buzzer.off()
        if sensor_faulted:
            led.sensor_error()
            show_feedback(oled, "show_sensor_error")
        else:
            led.ready_status()
            oled.show_ready()
    return sensor_faulted


def main():
    log("BOOT", "Lyra Pulse device starting")

    device_id = get_device_id()
    oled = OledDisplay()
    buzzer = Buzzer()
    led = StatusLed()
    touch_sensor = TouchSensor()
    wifi = WiFiService()
    r307 = R307()
    api_client = AttendanceAPIClient()
    fingerprint_service = FingerprintService(r307, touch_sensor)

    oled.show_startup()
    buzzer.off()
    led.ready_status()

    sensor_ready = False
    sensor_retry_delay_seconds = 2
    sensor_retry_max_seconds = 30
    try:
        r307.begin()
        sensor_ready = True
        log("R307", "Sensor initialized")
        led.ready_status()
        oled.show_ready()
    except R307PacketError as exc:  # pragma: no cover - hardware may not be attached during test
        log("SENSOR", "Temporary initialization failure (%s)" % exc.__class__.__name__)
        led.sensor_error()
        oled.show_sensor_error()

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
                log(
                    "R307",
                    "Retrying VerifyPassword after %ds backoff"
                    % sensor_retry_delay_seconds,
                )
                time.sleep(sensor_retry_delay_seconds)
                try:
                    r307.begin()
                    sensor_ready = True
                    sensor_retry_delay_seconds = 2
                    log("R307", "Sensor initialized")
                except R307PacketError as exc:
                    log(
                        "SENSOR",
                        "Initialization retry failed (%s); next retry in up to %ds"
                        % (
                            exc.__class__.__name__,
                            min(sensor_retry_delay_seconds * 2, sensor_retry_max_seconds),
                        ),
                    )
                    led.sensor_error()
                    oled.show_sensor_error()
                    sensor_retry_delay_seconds = min(
                        sensor_retry_delay_seconds * 2,
                        sensor_retry_max_seconds,
                    )
                    continue

            led.ready_status()
            oled.show_ready()

            log("DEVICE", "UART idle; polling enrollment API")
            enrollment_command = poll_enrollment_command(api_client, device_id)
            if isinstance(enrollment_command, dict):
                sensor_faulted = run_enrollment(
                    enrollment_command,
                    device_id,
                    api_client,
                    fingerprint_service,
                    oled,
                    buzzer,
                    led,
                )
                if not sensor_faulted:
                    fingerprint_service.wait_for_finger_removed()
                if sensor_faulted:
                    sensor_ready = False
                time.sleep(FINGERPRINT_COOLDOWN)
                continue

            enrollment_sensor_faulted = [False]

            def poll_enrollment_while_waiting():
                command = poll_enrollment_command(api_client, device_id)
                if isinstance(command, dict):
                    enrollment_sensor_faulted[0] = run_enrollment(
                        command,
                        device_id,
                        api_client,
                        fingerprint_service,
                        oled,
                        buzzer,
                        led,
                    )
                    fingerprint_service.wait_for_finger_removed()
                return None

            sensor_faulted = run_attendance_scan(
                device_id,
                api_client,
                fingerprint_service,
                oled,
                buzzer,
                led,
                on_wait=poll_enrollment_while_waiting,
            )
            if sensor_faulted or enrollment_sensor_faulted[0]:
                sensor_ready = False

        except R307PacketError as exc:
            log("SENSOR", "Temporary %s; main loop will recover" % exc.__class__.__name__)
            buzzer.off()
            sensor_ready = False
            time.sleep(0.25)
            led.sensor_error()
            oled.show_sensor_error()

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
