import sys
import types
import unittest
from unittest.mock import patch

from services import wifi_service


class FakeWLAN:
    def active(self, _enabled):
        self.active_state = _enabled

    def isconnected(self):
        return True


class FakeNetwork:
    STA_IF = 0

    def __init__(self):
        self.wlan = FakeWLAN()
        self.interface = None

    def WLAN(self, interface):
        self.interface = interface
        return self.wlan


class FakeNtpTime(types.ModuleType):
    def __init__(self, failing_hosts):
        super().__init__("ntptime")
        self.host = ""
        self.attempted_hosts = []
        self.failing_hosts = failing_hosts

    def settime(self):
        self.attempted_hosts.append(self.host)
        if self.host in self.failing_hosts:
            raise OSError(116)


class NtpFallbackTests(unittest.TestCase):
    def make_ntptime(self, failing_hosts):
        return FakeNtpTime(failing_hosts)

    def test_falls_back_to_a_working_ntp_server(self):
        ntptime = self.make_ntptime({"time.cloudflare.com"})
        with (
            patch.object(wifi_service, "network", FakeNetwork()),
            patch.dict(sys.modules, {"ntptime": ntptime}),
            patch.object(wifi_service.time, "time", return_value=1000),
            patch.object(wifi_service, "log"),
        ):
            service = wifi_service.WiFiService()

            self.assertTrue(service.is_connected())

        self.assertTrue(service.time_synced)
        self.assertEqual(
            ntptime.attempted_hosts,
            ["time.cloudflare.com", "time.google.com"],
        )

    def test_retries_after_backoff_without_repeating_immediately(self):
        failing_hosts = set(wifi_service.NTP_SERVERS)
        ntptime = self.make_ntptime(failing_hosts)
        clock = [1000]
        with (
            patch.object(wifi_service, "network", FakeNetwork()),
            patch.dict(sys.modules, {"ntptime": ntptime}),
            patch.object(wifi_service.time, "time", side_effect=lambda: clock[0]),
            patch.object(wifi_service, "log"),
        ):
            service = wifi_service.WiFiService()
            service.is_connected()
            first_attempts = len(ntptime.attempted_hosts)

            service.is_connected()
            self.assertEqual(len(ntptime.attempted_hosts), first_attempts)

            failing_hosts.clear()
            clock[0] += wifi_service.NTP_RETRY_INTERVAL_SECONDS + 1
            service.is_connected()

        self.assertTrue(service.time_synced)
        self.assertEqual(
            len(ntptime.attempted_hosts),
            first_attempts + 1,
        )


if __name__ == "__main__":
    unittest.main()
