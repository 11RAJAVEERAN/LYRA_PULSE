# Wiring guide

## Fingerprint sensor (R307)

- R307 TX -> ESP32 GPIO16
- R307 RX -> ESP32 GPIO17
- R307 GND -> ESP32 GND
- R307 VCC -> module-specified voltage

## OLED

- OLED SDA -> ESP32 GPIO21
- OLED SCL -> ESP32 GPIO22
- OLED VCC -> ESP32 3.3V
- OLED GND -> ESP32 GND

## Status outputs

- Buzzer -> GPIO4
- Green LED -> GPIO25
- Blue LED -> GPIO26
- Red LED -> GPIO27
- R307 TOUCH -> GPIO18

## UART configuration

- UART 2
- 57600 baud
- 8 data bits
- no parity
- 1 stop bit

## Serial port

The intended local development serial port is:

- /dev/cu.usbserial-5B150103211

Use the R307S module-rated supply voltage and connect the module and ESP32
grounds together. Do not infer the correct sensor VCC from this wiring guide;
check the exact module specification.
