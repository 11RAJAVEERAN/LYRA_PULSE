"""Wi-Fi management service for the ESP32 device."""

import time

try:
    import network
except ImportError:  # pragma: no cover - used only on MicroPython runtime
    network = None

from config import WIFI_PASSWORD, WIFI_RETRY_COUNT, WIFI_SSID, WIFI_TIMEOUT_SECONDS
from utils.logger import log


class WiFiService:
    def __init__(self):
        self.wlan = None
        if network is not None:
            self.wlan = network.WLAN(network.STA_IF)
            self.wlan.active(True)

    def connect(self):
        if network is None:
            log("WIFI", "Wi-Fi unavailable in this runtime")
            return False

        if self.wlan is None:
            return False

        if self.is_connected():
            return True

        try:
            self.wlan.disconnect()
        except OSError as exc:
            log("WIFI", "Disconnect before reconnect failed: %s" % exc)

        try:
            self.wlan.active(False)
            time.sleep(0.25)
            self.wlan.active(True)
            time.sleep(0.25)

            log("WIFI", "Connecting to SSID")
            self.wlan.connect(WIFI_SSID, WIFI_PASSWORD)
        except OSError as exc:
            log("WIFI", "Connection setup failed: %s" % exc)
            return False

        deadline = time.time() + WIFI_TIMEOUT_SECONDS
        attempts = 0

        while time.time() < deadline:
            if self.is_connected():
                log("WIFI", "Connected")
                return True
            time.sleep(0.5)
            attempts += 1
        log("WIFI", "Connection timeout")
        return False

    def disconnect(self):
        if self.wlan is not None:
            self.wlan.disconnect()

    def is_connected(self):
        if self.wlan is None:
            return False
        try:
            return self.wlan.isconnected()
        except Exception:
            return False

    def ensure_connected(self):
        for _ in range(WIFI_RETRY_COUNT):
            if self.connect():
                return True
            time.sleep(1)
        return False

    def get_ip(self):
        if self.wlan is None:
            return "0.0.0.0"
        try:
            return self.wlan.ifconfig()[0]
        except Exception:
            return "0.0.0.0"
