"""Wi-Fi management service for the ESP32 device."""

import time
import gc

try:
    import network
except ImportError:
    network = None

from config import WIFI_PASSWORD, WIFI_RETRY_COUNT, WIFI_SSID, WIFI_TIMEOUT_SECONDS
from utils.logger import log

NTP_SERVERS = ("time.cloudflare.com", "time.google.com", "pool.ntp.org")
NTP_RETRY_INTERVAL_SECONDS = 60
RETRY_COOLDOWN_SECONDS = 10


class WiFiService:
    def __init__(self):
        # Initialize lazily to avoid unnecessary startup allocation.
        self.wlan = None
        self.time_synced = False
        self.next_clock_sync_at = 0
        self.next_retry_at = 0

    def _get_wlan(self):
        if network is None:
            return None

        gc.collect()

        if self.wlan is None:
            self.wlan = network.WLAN(network.STA_IF)

        if not self.wlan.active():
            gc.collect()
            self.wlan.active(True)

        return self.wlan

    def _status_text(self, wlan):
        try:
            status = wlan.status()
        except Exception:
            return "unknown"
        names = (
            "STAT_IDLE", "STAT_CONNECTING", "STAT_WRONG_PASSWORD",
            "STAT_NO_AP_FOUND", "STAT_CONNECT_FAIL", "STAT_ASSOC_FAIL",
            "STAT_BEACON_TIMEOUT", "STAT_HANDSHAKE_TIMEOUT", "STAT_GOT_IP",
        )
        for name in names:
            if hasattr(network, name) and status == getattr(network, name):
                return name
        return str(status)

    def connect(self):
        if network is None:
            log("WIFI", "Wi-Fi unavailable in this runtime")
            return False

        stage = "wlan_initialization"
        try:
            wlan = self._get_wlan()

            if wlan is None:
                return False

            if wlan.isconnected():
                self._sync_clock()
                return True

            gc.collect()
            stage = "ap_association"
            log("WIFI", "Connecting to configured network")

            wlan.connect(WIFI_SSID, WIFI_PASSWORD)

            deadline = time.time() + WIFI_TIMEOUT_SECONDS

            while time.time() < deadline:
                if wlan.isconnected():
                    ip = wlan.ifconfig()[0]
                    log("WIFI", "Connected; IP=%s" % ip)
                    self.next_retry_at = 0
                    self._sync_clock()
                    return True

                time.sleep(0.5)

            stage = "dhcp_or_association_timeout"
            log("WIFI", "Connection timeout")
            return False

        except Exception as exc:
            gc.collect()
            free = gc.mem_free() if hasattr(gc, "mem_free") else -1
            errno_value = getattr(exc, "errno", None)
            if errno_value is None and getattr(exc, "args", None):
                errno_value = exc.args[0] if isinstance(exc.args[0], int) else None
            status = self._status_text(wlan) if "wlan" in locals() else "unavailable"
            log(
                "WIFI ERROR",
                "stage=%s class=%s errno=%s args=%s status=%s free_memory=%s"
                % (stage, exc.__class__.__name__, errno_value, repr(exc.args), status, free)
            )
            return False

    def disconnect(self):
        if self.wlan is not None:
            try:
                self.wlan.disconnect()
            except Exception as exc:
                log("WIFI", "Disconnect failed: %s" % exc.__class__.__name__)

    def is_connected(self):
        if self.wlan is None:
            return False

        try:
            return self.wlan.isconnected()
        except Exception:
            return False

    def ensure_connected(self):
        now = time.time()

        if self.is_connected():
            self.next_retry_at = 0
            self._sync_clock()
            return True

        if now < self.next_retry_at:
            return False

        for attempt in range(WIFI_RETRY_COUNT):
            log(
                "WIFI",
                "Connection attempt %d/%d"
                % (attempt + 1, WIFI_RETRY_COUNT)
            )

            if self.connect():
                log("WIFI", "Connection successful")
                self.next_retry_at = 0
                return True

            gc.collect()

            if attempt + 1 < WIFI_RETRY_COUNT:
                time.sleep(1)

        self.next_retry_at = time.time() + RETRY_COOLDOWN_SECONDS
        log("WIFI", "Retry delayed for %s seconds" % RETRY_COOLDOWN_SECONDS)
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

        if not self.is_connected():
            return

        now = time.time()

        if now < self.next_clock_sync_at:
            return

        self.next_clock_sync_at = now + NTP_RETRY_INTERVAL_SECONDS

        try:
            import ntptime
        except ImportError as exc:
            log("CLOCK", "NTP unavailable: %s" % exc.__class__.__name__)
            return

        for host in NTP_SERVERS:
            try:
                ntptime.host = host
                log("CLOCK", "NTP sync starting via %s" % host)
                ntptime.settime()

                if time.gmtime()[0] >= 2020:
                    self.time_synced = True
                    log("CLOCK", "Device clock synchronized")
                    return

            except Exception as exc:
                log(
                    "CLOCK",
                    "NTP failed via %s (%s)"
                    % (host, exc.__class__.__name__)
                )

        log("CLOCK", "NTP synchronization pending")
