import sys
import types
import unittest
from unittest.mock import patch

from services import wifi_service
from services.wifi_service import WiFiService


class FakeWLAN:
    def __init__(self):
        self.active_calls = []
        self.connect_calls = []
        self.connected = False

    def active(self, state):
        self.active_calls.append(bool(state))
        return True

    def disconnect(self):
        self.connected = False

    def connect(self, ssid, password):
        self.connect_calls.append((ssid, password))
        self.connected = True

    def isconnected(self):
        return self.connected


class FakeNetworkModule:
    STA_IF = 1

    def WLAN(self, iface):
        return FakeWLAN()


class WiFiServiceTests(unittest.TestCase):
    def test_connect_does_not_toggle_station_interface_before_connecting(self):
        fake_wlan = FakeWLAN()

        with patch("services.wifi_service.network", FakeNetworkModule()), patch(
            "services.wifi_service.WIFI_SSID", "test-network"
        ), patch("services.wifi_service.WIFI_PASSWORD", "secret"), patch(
            "services.wifi_service.WIFI_TIMEOUT_SECONDS", 0.01
        ):
            service = WiFiService()
            service.wlan = fake_wlan

            result = service.connect()

        self.assertTrue(result)
        self.assertEqual(fake_wlan.active_calls, [True])
        self.assertEqual(fake_wlan.connect_calls, [("test-network", "secret")])


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
    def test_falls_back_to_a_working_ntp_server(self):
        ntptime = FakeNtpTime({"time.cloudflare.com"})
        with (
            patch.object(wifi_service, "network", FakeNetworkModule()),
            patch.dict(sys.modules, {"ntptime": ntptime}),
            patch.object(wifi_service.time, "time", return_value=1000),
            patch.object(wifi_service, "log"),
        ):
            service = WiFiService()
            service._sync_clock()

        self.assertTrue(service.time_synced)
        self.assertEqual(ntptime.attempted_hosts, ["time.cloudflare.com", "time.google.com"])

    def test_retries_after_backoff_without_repeating_immediately(self):
        ntptime = FakeNtpTime(set(wifi_service.NTP_SERVERS))
        clock = [1000]
        with (
            patch.object(wifi_service, "network", FakeNetworkModule()),
            patch.dict(sys.modules, {"ntptime": ntptime}),
            patch.object(wifi_service.time, "time", side_effect=lambda: clock[0]),
            patch.object(wifi_service, "log"),
        ):
            service = WiFiService()
            service._sync_clock()
            first_attempts = len(ntptime.attempted_hosts)
            service._sync_clock()
            self.assertEqual(len(ntptime.attempted_hosts), first_attempts)
            ntptime.failing_hosts.clear()
            clock[0] += wifi_service.NTP_RETRY_INTERVAL_SECONDS + 1
            service._sync_clock()

        self.assertTrue(service.time_synced)
        self.assertEqual(len(ntptime.attempted_hosts), first_attempts + 1)


if __name__ == "__main__":
    unittest.main()
