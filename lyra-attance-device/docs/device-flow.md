# Device flow

## Normal operation

1. Boot the ESP32.
2. Initialize OLED, buzzer, and LEDs.
3. Connect to the configured Wi-Fi network.
4. Show startup and ready screens.
5. Wait for a debounced GPIO18 edge (polarity configurable; default unverified).
   In hybrid mode, the sensor can also be probed with GetImage at the configured
   low frequency while idle.
6. Capture the fingerprint image.
7. Convert the image to a template.
8. Search the local R307 database for a matching template.
9. If a match is found, send the fingerprint ID to the backend.
10. Display success and sound the green success beep.
11. Wait until the finger is removed.
12. Return to the ready state.

## Not found path

- Only a valid sensor search response with confirmation `0x09` is a no-match.
- Display `NO MATCH`, use the red LED, and sound two beeps.
- Return to ready after finger removal.

## Sensor communication errors

- A timeout, missing response, malformed packet, or other R307 communication
  error is a sensor error, not a fingerprint mismatch.
- Keep mismatch feedback off and retry sensor initialization with backoff.
- Recognition stays latched until removal is confirmed. If removal cannot be
  confirmed before the configured timeout, apply the bounded rearm cooldown.

## Offline path

- If Wi-Fi is unavailable, display a network error and continue monitoring the sensor.
- The device remains responsive and does not crash.
