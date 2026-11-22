"""Standalone, non-attendance MicroPython hardware test entry point."""

import time

from config import (
    OLED_I2C_ADDRESS,
    OLED_SCL_PIN,
    OLED_SDA_PIN,
    WIFI_PASSWORD,
    WIFI_SSID,
    WIFI_TIMEOUT_SECONDS,
    UART_BAUDRATE,
    UART_ID,
    UART_RX_PIN,
    UART_TX_PIN,
)

FINGER_WAIT_SECONDS = 20


def report(name, result):
    print("%s: %s" % (name, "OK" if result else "FAIL"))
    return result


def test_oled():
    try:
        from drivers.oled import OledDisplay

        display = OledDisplay()
        display.show_orientation_test_pattern()
        report("OLED", True)
        return display
    except Exception as exc:
        print("OLED: FAIL - %s" % exc)
        return None


def test_green_led(led):
    try:
        led.green_on()
        time.sleep(0.5)
        led.green_off()
        return report("GREEN LED", True)
    except Exception as exc:
        print("GREEN LED: FAIL - %s" % exc)
        return False


def test_red_led(led):
    try:
        led.red_on()
        time.sleep(0.5)
        led.red_off()
        return report("RED LED", True)
    except Exception as exc:
        print("RED LED: FAIL - %s" % exc)
        return False


def test_buzzer():
    try:
        from hardware.buzzer import Buzzer

        buzzer = Buzzer()
        buzzer.startup_beep()
        return report("BUZZER", True)
    except Exception as exc:
        print("BUZZER: FAIL - %s" % exc)
        return False


def test_r307_uart():
    try:
        from drivers.r307 import R307

        print("R307: UART%d %d baud TX=GPIO%d RX=GPIO%d" % (
            UART_ID, UART_BAUDRATE, UART_TX_PIN, UART_RX_PIN
        ))
        sensor = R307(debug=True)
        sensor.verify_password(sensor.password)
        print("R307: OK")
        return sensor
    except Exception as exc:
        print("R307: FAIL - %s" % exc)
        print("R307 CHECK: UART2 57600 baud, ESP32 TX GPIO17 to sensor RX, sensor TX to ESP32 RX GPIO16, shared ground, and module-rated power.")
        return None


def test_fingerprint(sensor):
    from drivers.r307 import R307FingerError

    if sensor is None:
        print("FINGERPRINT TEST: SKIPPED - R307 INITIALIZATION FAILED")
        return False

    print("FINGERPRINT TEST: PLACE A STORED FINGER")
    deadline = time.ticks_add(time.ticks_ms(), FINGER_WAIT_SECONDS * 1000)
    while time.ticks_diff(deadline, time.ticks_ms()) > 0:
        try:
            sensor.get_image()
            sensor.image_to_template(buffer_id=1)
            match = sensor.search(buffer_id=1, start_page=0, page_num=100)
            if match is None:
                print("FINGERPRINT TEST: CAPTURE OK, NO MATCH")
            else:
                print("FINGERPRINT TEST: MATCH ID=%s SCORE=%s" % (
                    match["fingerprint_id"], match["score"]
                ))
            return True
        except R307FingerError:
            time.sleep_ms(150)
        except Exception as exc:
            print("FINGERPRINT TEST: FAIL - %s" % exc)
            return False

    print("FINGERPRINT TEST: FAIL - TIMED OUT WAITING FOR FINGER")
    return False


def test_wifi():
    try:
        import network

        if not WIFI_SSID or WIFI_SSID == "YOUR_WIFI_SSID" or not WIFI_PASSWORD or WIFI_PASSWORD == "YOUR_WIFI_PASSWORD":
            print("WIFI: FAIL - CONFIGURE SSID/PASSWORD IN CONFIG")
            return False

        wlan = network.WLAN(network.STA_IF)
        if wlan.active():
            try:
                wlan.disconnect()
            except Exception:
                pass
            wlan.active(False)
            time.sleep_ms(250)
        wlan.active(True)
        time.sleep_ms(250)
        wlan.connect(WIFI_SSID, WIFI_PASSWORD)

        deadline = time.ticks_add(time.ticks_ms(), WIFI_TIMEOUT_SECONDS * 1000)
        while not wlan.isconnected() and time.ticks_diff(deadline, time.ticks_ms()) > 0:
            time.sleep_ms(250)

        if wlan.isconnected():
            print("WIFI: OK")
            return True
        print("WIFI: FAIL - CONNECTION TIMEOUT")
        return False
    except Exception as exc:
        print("WIFI: FAIL - %s" % exc)
        return False


def test_api():
    print("API TEST: SKIPPED - NO SAFE TEST ENDPOINT")
    return "SKIP"


def show_final_summary(display, oled_ok, led_ok, buzzer_ok, r307_ok, wifi_ok, api_result):
    rows = [
        "LYRA PULSE",
        "HW TEST",
        "OLED   %s" % ("OK" if oled_ok else "FAIL"),
        "LED    %s" % ("OK" if led_ok else "FAIL"),
        "BUZZER %s" % ("OK" if buzzer_ok else "FAIL"),
        "R307   %s" % ("OK" if r307_ok else "FAIL"),
        "WIFI   %s" % ("OK" if wifi_ok else "FAIL"),
        "API    %s" % api_result,
    ]
    print("\n".join(rows))

    if display is not None:
        try:
            for row, text in enumerate(rows):
                display.draw_centered_text(text, row * 8)
            display.oled.show()
        except Exception as exc:
            print("OLED SUMMARY: FAIL - %s" % exc)


def main():
    print("BOOT: OK")

    display = test_oled()

    try:
        from hardware.status_led import StatusLed

        led = StatusLed()
        green_ok = test_green_led(led)
        red_ok = test_red_led(led)
    except Exception as exc:
        print("GREEN LED: FAIL - %s" % exc)
        print("RED LED: FAIL - %s" % exc)
        green_ok = False
        red_ok = False
    led_ok = green_ok and red_ok

    buzzer_ok = test_buzzer()
    sensor = test_r307_uart()
    test_fingerprint(sensor)
    wifi_ok = test_wifi()
    api_result = test_api()

    show_final_summary(
        display,
        display is not None,
        led_ok,
        buzzer_ok,
        sensor is not None,
        wifi_ok,
        api_result,
    )


if __name__ == "__main__":
    main()
