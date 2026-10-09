# Lyra Pulse Fingerprint Attendance Device

This repository contains the ESP32 MicroPython firmware for the Lyra Pulse fingerprint attendance terminal.

## Scope

- ESP32-WROOM firmware only
- R307/R307S fingerprint sensor support
- SSD1306 128x64 OLED UI
- Wi-Fi connectivity to the existing Lyra Pulse Django backend
- Attendance event transmission using the device fingerprint ID

This project intentionally does not duplicate or modify:

- lyrapulse-backend
- lyrapulse-admin
- lyrapulse-mobile

## Current backend status

The existing Django backend currently exposes authentication endpoints under `/api/v1/auth/` and employee mobile profile routes, but there is no attendance/fingerprint endpoint implemented yet in the checked-in project.

The ESP32 firmware therefore uses a configuration placeholder at:

- `/api/v1/attendance/fingerprint/`

This should be updated to the actual backend route when the backend team exposes the real attendance device endpoint.

## Hardware

- ESP32-WROOM
- R307 / R307S fingerprint sensor
- 128x64 SSD1306 OLED (I2C)
- Green LED
- Red LED
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
2. Connect to Wi-Fi
3. Show ready screen
4. Wait for finger
5. Capture fingerprint
6. Search template store
7. Send fingerprint ID to Django
8. Show success or not found
9. Wait for finger removal
10. Return to ready

## Fingerprint enrollment

Start enrollment from the Django admin workflow; the ESP32 polls for an enrollment command while idle. Before testing, ensure the latest `services/`, `drivers/`, `main.py`, and `config.py` have been copied to the board. The `mpremote run main.py` command alone does not synchronize those files.

```sh
mpremote connect /dev/cu.usbserial-5B150103211 run main.py
```

Set `ENROLLMENT_TEMPLATE_ID` in `esp32/config.py` to choose the starting sensor slot (default `1`). Follow the OLED prompts to scan the same finger twice. Enrollment is reported as successful only after a third scan searches the sensor and confirms the actual stored slot.

## Notes

- No fingerprint images are transmitted.
- No Wi-Fi passwords or tokens are printed to logs.
- Production API traffic should use HTTPS.

## Wi-Fi troubleshooting

- ESP32 supports 2.4 GHz Wi-Fi only. Configure `WIFI_SSID` and `WIFI_PASSWORD` in `esp32/config.py` for a 2.4 GHz network.
- The Wi-Fi service resets the station interface before each connection attempt to recover from stale MicroPython Wi-Fi state. If connection attempts still fail, verify the SSID, password, and router's 2.4 GHz settings.
