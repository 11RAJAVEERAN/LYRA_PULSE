"""Wi-Fi management service for the ESP32 device."""

import time

try:
    import network
except ImportError:  # pragma: no cover - used only on MicroPython runtime
    network = None

from config import WIFI_PASSWORD, WIFI_RETRY_COUNT, WIFI_SSID, WIFI_TIMEOUT_SECONDS
from utils.logger import log

NTP_SERVERS = ("time.cloudflare.com", "time.google.com", "pool.ntp.org")
NTP_RETRY_INTERVAL_SECONDS = 60


class WiFiService:
    def __init__(self):
        self.wlan = None
        self.time_synced = False
        self.next_clock_sync_at = 0
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
            self._sync_clock()
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

            log(
                "WIFI",
                "Connection starting (timeout=%ds)" % WIFI_TIMEOUT_SECONDS,
            )
            self.wlan.connect(WIFI_SSID, WIFI_PASSWORD)
            log("WIFI", "Association request returned")
        except OSError as exc:
            log("WIFI", "Connection setup failed: %s" % exc)
            return False

        deadline = time.time() + WIFI_TIMEOUT_SECONDS
        attempts = 0

        while time.time() < deadline:
            if self.is_connected():
                log("WIFI", "Connected")
                self._sync_clock()
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
            connected = self.wlan.isconnected()
        except Exception:
            return False
        if connected:
            self._sync_clock()
        return connected

    def ensure_connected(self):
        for attempt in range(WIFI_RETRY_COUNT):
            log(
                "WIFI",
                "Connection attempt %d/%d"
                % (attempt + 1, WIFI_RETRY_COUNT),
            )
            if self.connect():
                log("WIFI", "Connection attempt %d succeeded" % (attempt + 1))
                return True
            log("WIFI", "Connection attempt %d failed" % (attempt + 1))
            time.sleep(1)
        return False

    def get_ip(self):
        if self.wlan is None:
            return "0.0.0.0"
        try:
            return self.wlan.ifconfig()[0]
        except Exception:
            return "0.0.0.0"

    def _sync_clock(self):
        if self.time_synced:
            return
        now = time.time()
        if now < self.next_clock_sync_at:
            return
        self.next_clock_sync_at = now + NTP_RETRY_INTERVAL_SECONDS
        try:
            import ntptime
        except ImportError as exc:
            log("CLOCK", "NTP module unavailable (%s)" % exc.__class__.__name__)
            return

        for host in NTP_SERVERS:
            ntptime.host = host
            log("CLOCK", "NTP sync starting via %s" % host)
            try:
                ntptime.settime()
            except Exception as exc:
                log(
                    "CLOCK",
                    "NTP sync failed via %s (%s)"
                    % (host, exc.__class__.__name__),
                )
                continue
            self.time_synced = True
            log("CLOCK", "Device clock synchronized via %s" % host)
            return

        log(
            "CLOCK",
            "Time synchronization unavailable; attendance scans require a valid clock",
        )
