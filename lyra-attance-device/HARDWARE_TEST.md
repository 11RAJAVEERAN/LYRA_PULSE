# Lyra Pulse Hardware Test

## Purpose

This is a safe hardware test flow for the ESP32 fingerprint attendance terminal. It is intentionally separate from the production firmware and should not be used for real attendance, check-in, or check-out operations.

## Wiring

### R307 UART

- ESP32 GPIO17 -> R307 RX
- ESP32 GPIO16 <- R307 TX
- ESP32 GND -> R307 GND
- R307 VCC -> module power rail, according to the exact R307 module specification

### OLED

- ESP32 GPIO21 -> OLED SDA
- ESP32 GPIO22 -> OLED SCL
- ESP32 3.3V -> OLED VCC
- ESP32 GND -> OLED GND

### GPIO outputs

- Buzzer -> GPIO4
- Green LED -> GPIO18
- Red LED -> GPIO19

## Configuration

The project expects these values in `esp32/config.py`:

- UART ID: 2
- UART baudrate: 57600
- R307 password: `0x00000000`
- I2C address: `0x3C`

## Uploading the test firmware manually

The test is run from a separate `/hwtest` directory on the ESP32. It does not replace or rename `main.py`. Run these commands from the local `lyra-attance-device/esp32` directory. Create `/hwtest` only once:

```bash
mpremote connect /dev/cu.usbserial-5B150103211 fs mkdir :hwtest
mpremote connect /dev/cu.usbserial-5B150103211 fs cp config.py :hwtest/config.py
mpremote connect /dev/cu.usbserial-5B150103211 fs cp -r drivers :hwtest/drivers
mpremote connect /dev/cu.usbserial-5B150103211 fs cp -r hardware :hwtest/hardware
mpremote connect /dev/cu.usbserial-5B150103211 fs cp -r lib :hwtest/lib
mpremote connect /dev/cu.usbserial-5B150103211 fs cp -r utils :hwtest/utils
mpremote connect /dev/cu.usbserial-5B150103211 fs cp hardware_test.py :hwtest/hardware_test.py
mpremote connect /dev/cu.usbserial-5B150103211 exec "import sys; sys.path.insert(0, '/hwtest'); import hardware_test"
```

For later runs, do not repeat the `mkdir` command. Copy updated files into `/hwtest` as needed, then run the final `exec` command again. The test reads Wi-Fi credentials from the copied `config.py`; it never prints the password. Do not share that file or serial output containing credentials.

## Connect to the MicroPython REPL

Typical method:

```bash
ls /dev/cu.*
python -m serial.tools.miniterm /dev/cu.usbserial-5B150103211 115200
```

If `pyserial` is not installed:

```bash
pip install pyserial
```

## Expected serial output

```text
BOOT: OK
OLED: OK
GREEN LED: OK
RED LED: OK
BUZZER: OK
R307: OK
FINGERPRINT TEST: PLACE A STORED FINGER
FINGERPRINT TEST: MATCH ID=23 SCORE=42
WIFI: OK
API TEST: SKIPPED - NO SAFE TEST ENDPOINT
LYRA PULSE
HW TEST
OLED   OK
LED    OK
BUZZER OK
R307   OK
WIFI   OK
API    SKIP
```

Actual results vary. R307 failures include the driver's timeout or packet/checksum error, followed by wiring checks. Fingerprint testing is skipped if R307 initialization fails. Wi-Fi reports a configuration failure for placeholder credentials, a connection timeout if it cannot connect, or the underlying network error. The API test always skips because no dedicated safe health/test endpoint is configured.

## Expected OLED output

The OLED first displays the device-test status, then the final summary:

```text
LYRA PULSE
HW TEST
OLED   OK
LED    OK
BUZZER OK
R307   OK/FAIL
WIFI   OK/FAIL
API    SKIP
```

## R307 troubleshooting

- Confirm ESP32 GPIO17 (TX) connects to R307 RX and R307 TX connects to ESP32 GPIO16 (RX).
- Confirm the UART is configured as 57600, 8N1.
- Confirm the sensor has module-rated power and shares ground with the ESP32.
- The test reports the driver's timeout or malformed-packet/checksum error; do not ignore it.

## Wi-Fi troubleshooting

- Confirm the SSID and password are valid.
- Ensure the device is connecting to a 2.4 GHz network if required.
- Verify the antenna and reception quality.
- Do not print the Wi‑Fi password to the serial log.

## Safety

- Do not perform attendance or check-in APIs during the hardware test.
- Do not create attendance records.
- Do not change Django, admin, or mobile app code.
- This is a local hardware validation only.
