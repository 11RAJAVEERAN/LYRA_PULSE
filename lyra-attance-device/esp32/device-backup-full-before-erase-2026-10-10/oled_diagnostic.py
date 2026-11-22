"""OLED-only diagnostic; does not initialize Wi-Fi, fingerprint, or GPIO outputs."""

import time

from drivers.oled import OledDisplay


def main():
    display = OledDisplay()
    print("OLED DIAGNOSTIC: initialized at configured I2C address")

    messages = (
        ("LYRA PULSE", "OLED TEST"),
        ("DEVICE READY",),
        ("WIFI CONNECTED",),
        ("FINGERPRINT READY",),
    )
    for lines in messages:
        display._show_lines(lines)
        print("OLED DIAGNOSTIC: displayed %s" % " / ".join(lines))
        time.sleep(2)

    display.reinitialize()
    display._show_lines(["LYRA PULSE", "DEVICE READY"])
    print("OLED DIAGNOSTIC: reinitialized; final screen left visible")


main()
