# Device flow

## Normal operation

1. Boot the ESP32.
2. Initialize OLED, buzzer, and LEDs.
3. Connect to the configured Wi-Fi network.
4. Show startup and ready screens.
5. Wait for a finger to be placed.
6. Capture the fingerprint image.
7. Convert the image to a template.
8. Search the local R307 database for a matching template.
9. If a match is found, send the fingerprint ID to the backend.
10. Display success and sound the green success beep.
11. Wait until the finger is removed.
12. Return to the ready state.

## Not found path

- If the search returns no match, display `Fingerprint Not Found`.
- Trigger the red LED with an error beep.
- Return to ready after finger removal.

## Offline path

- If Wi-Fi is unavailable, display a network error and continue monitoring the sensor.
- The device remains responsive and does not crash.
