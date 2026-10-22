# Device tools

This folder is reserved for ESP32 flash, monitoring, and diagnostic helpers.

Typical workflow:

- Confirm the serial port is /dev/cu.usbserial-5B150103211
- Use MicroPython/Thonny or mpremote to upload the firmware
- Monitor the serial output with the REPL
- Validate the fingerprint sensor and Wi-Fi status

Future tools may include:

- mass upload script
- status checker
- local firmware test helper
