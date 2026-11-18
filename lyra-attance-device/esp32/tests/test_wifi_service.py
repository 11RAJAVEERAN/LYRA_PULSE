import unittest
from unittest.mock import patch

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


if __name__ == "__main__":
    unittest.main()
