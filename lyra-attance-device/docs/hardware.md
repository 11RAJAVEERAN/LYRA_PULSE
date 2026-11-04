# Hardware overview

The Lyra Pulse attendance device is a dedicated ESP32-WROOM terminal intended for employee fingerprint check-in and check-out.

## Main components

- ESP32-WROOM development board
- R307 / R307S fingerprint sensor
- 128x64 SSD1306 OLED display
- Green status LED
- Red status LED
- Active buzzer
- Wi-Fi 2.4 GHz network

## Recommended design

- Keep the fingerprint sensor isolated from noisy power rails.
- Use a stable 3.3V rail for the OLED and sensor if the module requires it.
- Add a common ground between ESP32 and sensor.
- Use a buzzer driver with short pulses to avoid noise.
- Route sensor UART lines away from high-current loads.

## Safety note

The exact R307 module can be power- and logic-voltage sensitive. Confirm the module's datasheet before connecting UART TX directly to an ESP32 GPIO.
