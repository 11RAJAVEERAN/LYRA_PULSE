# Lyra Pulse Fingerprint Attendance Device

This repository contains the ESP32 MicroPython firmware for the Lyra Pulse fingerprint attendance terminal.

## Scope

- ESP32-WROOM firmware only
- R307/R307S fingerprint sensor support
- SSD1306 128x64 OLED UI
- Wi-Fi connectivity to the existing Lyra Pulse Django backend
- Attendance event transmission using the device fingerprint ID

This project integrates with the existing:

- lyrapulse-backend
- lyrapulse-admin
- lyrapulse-mobile

## Attendance backend

The ESP32 uses the existing Django endpoint `POST /api/v1/attendance/fingerprint/`.
After the R307 search returns a real match, it sends the configured device ID and
the matched `fingerprint_slot` using the existing device-token authentication.
The backend resolves the registered employee and chooses check-in or check-out.

## Hardware

- ESP32-WROOM
- R307 / R307S fingerprint sensor
- 128x64 SSD1306 OLED (I2C)
- Green LED (GPIO 25)
- Blue LED (GPIO 26)
- Red LED (GPIO 27)
- Buzzer

## Serial port

The project is configured for the user's Mac serial port:

- /dev/cu.usbserial-5B150103211

## Quick start

1. Install MicroPython on the ESP32.
2. Connect the hardware and verify the wiring.
3. Update credentials in `esp32/config.py`.
4. Copy the firmware files and all imported modules from `esp32/` to the root of the ESP32 filesystem. For example, from the `lyra-attance-device/` directory:

   ```sh
   PORT=/dev/cu.usbserial-5B150103211
   mpremote connect "$PORT" fs cp esp32/main.py :main.py
   mpremote connect "$PORT" fs cp esp32/config.py :config.py
   mpremote connect "$PORT" fs cp -r esp32/drivers :/
   mpremote connect "$PORT" fs cp -r esp32/hardware :/
   mpremote connect "$PORT" fs cp -r esp32/lib :/
   mpremote connect "$PORT" fs cp -r esp32/services :/
   mpremote connect "$PORT" fs cp -r esp32/utils :/
   ```

5. Restart the board, then run the firmware. `mpremote run main.py` sends that entry-point file for execution, but does **not** update imported modules already stored on the ESP32. Re-copy the module directories whenever their source changes.

## Device flow

1. Power on
2. Initialize the R307, OLED, buzzer, LEDs, and Wi-Fi services
3. Show `PLACE FINGER` with the blue ready LED once the sensor initializes
4. Wait for Wi-Fi before processing attendance requests
5. Capture fingerprint and search the sensor template store
6. Send only the matched slot returned by the R307 to Django
7. Show success or no match, with the corresponding LED and buzzer feedback
8. Wait for finger removal and return to the blue ready state

## Fingerprint enrollment

Start enrollment from the Django admin workflow; the ESP32 polls for an enrollment command while idle. Before testing, ensure the latest `services/`, `drivers/`, `main.py`, and `config.py` have been copied to the board. The `mpremote run main.py` command alone does not synchronize those files.

```sh
mpremote connect /dev/cu.usbserial-5B150103211 run main.py
```

Set `ENROLLMENT_TEMPLATE_ID` in `esp32/config.py` to choose the starting sensor slot (default `1`). Follow the OLED prompts to scan the same finger twice. Enrollment is reported as successful only after a third scan searches the sensor and confirms the actual stored slot.

## Notes

- No fingerprint images are transmitted.
- No Wi-Fi passwords or tokens are printed to logs.
- LEDs use the existing active-high convention; the blue ready LED is GPIO 26.
- Attendance requests are not automatically retried after a timeout because each accepted scan changes attendance state.
- Production API traffic should use HTTPS.

## Wi-Fi troubleshooting

- ESP32 supports 2.4 GHz Wi-Fi only. Configure `WIFI_SSID` and `WIFI_PASSWORD` in `esp32/config.py` for a 2.4 GHz network.
- The Wi-Fi service resets the station interface before each connection attempt to recover from stale MicroPython Wi-Fi state. If connection attempts still fail, verify the SSID, password, and router's 2.4 GHz settings.
