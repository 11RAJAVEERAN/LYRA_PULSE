# Fingerprint Device Setup

## Source-verified hardware configuration

Project A firmware source is configured for an ESP32, R307 fingerprint sensor on UART2 (TX GPIO 17, RX GPIO 16, 57,600 baud), SSD1306 OLED on I²C GPIO 21/22 at address `0x3C`, touch input GPIO 18, buzzer GPIO 4, and status LEDs GPIO 25/26/27. These are source settings, not hardware-verified facts.

## Provisioning

1. Deploy the Project B backend over HTTPS and configure a trusted URL in `esp32/config.py`.
2. Create an active branch and provision the device using either the Admin Web Devices page or:

   ```powershell
   python manage.py provision_device --device-id LYRA-DEVICE-001 --branch-code BRANCH_CODE
   ```

3. Copy the one-time raw device token into a private local firmware `config.py`; keep it out of source control. Configure the 2.4 GHz Wi-Fi SSID/password locally. The packaged configuration has blank placeholders.
4. Synchronize the ESP32 clock through NTP after Wi-Fi connects. Device timestamps earlier than 2020 or later than server time are rejected; offline attendance needs a valid RTC.
5. Flash the active `esp32` source using the appropriate MicroPython deployment workflow. Do not flash archived backup folders.
6. Enable Biometric Attendance for the employee, start an enrollment from the Admin Web, and complete the two sensor scans. The API maps the reported R307 slot to the employee and device.

## Event and offline behavior

The device assigns a UUID and UTC timestamp to each scan and stores events in a persistent FIFO JSON file on device flash. It syncs oldest-first when online; successful/idempotent acknowledgments remove events. Failed responses remain queued and block later events to preserve order. A rejected/misconfigured event therefore needs administrative correction and retry. The queue is bounded at 500 events. Queue file corruption, flash wear, power-loss behavior, local clock behavior, Wi-Fi loss, and sensor operation have not been tested on physical hardware.

The backend alternates scans: an employee with no open session checks in; an employee with an open session checks out. Device event IDs are unique per device. A scan uses the device's `occurred_at`, not the server receipt time.

## Troubleshooting

- `401`: verify device ID/token pairing; rotate and reprovision if exposed.
- `403`: verify device and branch active state, employee active state, biometric permission, branch assignment, and HTTPS/backend configuration.
- `404`: check employee fingerprint mapping and sensor slot.
- Timestamp rejection: synchronize the device clock before collecting attendance.
- Queue not draining: review HTTP status/configuration; queue intentionally remains in order until its oldest event is accepted.
- Sensor/OLED behavior: confirm wiring and MicroPython hardware modules; no physical-hardware test was possible here.
