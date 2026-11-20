
"""Central configuration for the Lyra Pulse ESP32 fingerprint attendance device."""

import os

try:
    import config_local as _local
except ImportError:
    _local = None


def _env(name, default):
    environ_get = getattr(os, "getenv", None)
    return environ_get(name, default) if environ_get else default


def _setting(name, environment_name, default):
    value = _env(environment_name, default)

    if value == default and _local is not None:
        value = getattr(_local, name, default)

    return value


# ------------------------------------------------------------
# Wi-Fi
# ------------------------------------------------------------
# ESP32 supports 2.4 GHz Wi-Fi only.

WIFI_SSID = _setting("WIFI_SSID", "LYRA_WIFI_SSID", "")
WIFI_PASSWORD = _setting("WIFI_PASSWORD", "LYRA_WIFI_PASSWORD", "")

WIFI_TIMEOUT_SECONDS = int(_env("LYRA_WIFI_TIMEOUT_SECONDS", "20"))
WIFI_RETRY_COUNT = int(_env("LYRA_WIFI_RETRY_COUNT", "3"))


# ------------------------------------------------------------
# Device identity
# ------------------------------------------------------------

DEVICE_ID = _setting("DEVICE_ID", "LYRA_DEVICE_ID", "")
DEVICE_TOKEN = _setting("DEVICE_TOKEN", "LYRA_DEVICE_TOKEN", "")

TEST_MODE = _env("LYRA_TEST_MODE", "false").lower() == "true"


# ------------------------------------------------------------
# API
# ------------------------------------------------------------

API_BASE_URL = _setting("API_BASE_URL", "LYRA_API_BASE_URL", "")

# Allow HTTP only when explicitly enabled in config_local.py.
ALLOW_INSECURE_HTTP = (
    getattr(_local, "ALLOW_INSECURE_HTTP", False)
    if _local is not None else False
)

API_FINGERPRINT_ENDPOINT = "/api/v1/attendance/fingerprint/events/"

API_DEVICE_HEARTBEAT = "/api/v1/devices/{device_id}/heartbeat/"

API_DEVICE_ENROLLMENT_PENDING = (
    "/api/v1/devices/{device_id}/enrollment/pending/"
)

API_DEVICE_ENROLLMENT_RESULT = (
    "/api/v1/devices/{device_id}/enrollment/{enrollment_id}/result/"
)

API_TIMEOUT = int(_env("LYRA_API_TIMEOUT", "10"))
API_RETRY_COUNT = int(_env("LYRA_API_RETRY_COUNT", "2"))

HEARTBEAT_INTERVAL_SECONDS = int(
    _env("LYRA_HEARTBEAT_INTERVAL_SECONDS", "60")
)


# ------------------------------------------------------------
# UART fingerprint sensor
# ------------------------------------------------------------

UART_ID = 2
UART_BAUDRATE = 57600
UART_TX_PIN = 17
UART_RX_PIN = 16

R307_ADDRESS = 0xFFFFFFFF
R307_UART_READ_TIMEOUT_MS = 10
R307_DEBUG = True

R307_TOUCH_PIN = 18
R307_TOUCH_ACTIVE_LEVEL = None
R307_TOUCH_DEBOUNCE_SAMPLES = 5
# Enable only when the connected sensor output needs the ESP32's internal pull-up.
# The default preserves Project A's existing floating/external-bias configuration.
R307_TOUCH_PULL_UP_ENABLED = False
R307_TOUCH_SAMPLE_INTERVAL_SECONDS = 0.01

R307_DETECTION_MODE = "hybrid"
R307_UART_FALLBACK_ENABLED = True
R307_UART_FALLBACK_INTERVAL_SECONDS = 2.0

R307_TOUCH_CAPTURE_RETRY_INTERVAL_SECONDS = 0.25
R307_TOUCH_CAPTURE_TIMEOUT_SECONDS = 10
R307_TOUCH_CAPTURE_MAX_ATTEMPTS = 40

R307_FINGER_REMOVAL_TIMEOUT_SECONDS = 30
R307_FINGER_REMOVAL_COOLDOWN_SECONDS = 30

R307_DIAGNOSTIC_MODE = "sensor"
R307_LOOPBACK_CONFIRMED_DISCONNECTED = False

R307_PASSWORD = 0x00000000
ENROLLMENT_TEMPLATE_ID = 1


# ------------------------------------------------------------
# OLED display
# ------------------------------------------------------------

OLED_SDA_PIN = 21
OLED_SCL_PIN = 22
OLED_I2C_ADDRESS = 0x3C
OLED_I2C_FREQUENCY = 100000


# ------------------------------------------------------------
# GPIO outputs
# ------------------------------------------------------------

BUZZER_PIN = 4
GREEN_LED_PIN = 25
BLUE_LED_PIN = 26
RED_LED_PIN = 27


# ------------------------------------------------------------
# Behavior and safety
# ------------------------------------------------------------

FINGERPRINT_COOLDOWN = 5
FINGER_REMOVAL_SETTLE_SECONDS = 1

MAX_TEMPLATE_COUNT = 1000
ENROLLMENT_STEP_TIMEOUT_SECONDS = 30


# ------------------------------------------------------------
# Serial configuration
# ------------------------------------------------------------

SERIAL_PORT = _env("LYRA_SERIAL_PORT", "/dev/ttyUSB0")


# ------------------------------------------------------------
# Safe configuration summary
# ------------------------------------------------------------

def safe_config_summary():
    return {
        "device_id": DEVICE_ID,
        "wifi_configured": bool(WIFI_SSID and WIFI_PASSWORD),
        "api_base_url": API_BASE_URL,
        "test_mode": TEST_MODE,
    }


# ------------------------------------------------------------
# Runtime configuration validation
# ------------------------------------------------------------

def validate_runtime_config(device_id=None):

    if not WIFI_SSID or WIFI_SSID == "YOUR_WIFI_SSID":
        raise ValueError(
            "Configure WIFI_SSID in device-local config_local.py"
        )

    if not WIFI_PASSWORD or WIFI_PASSWORD == "YOUR_WIFI_PASSWORD":
        raise ValueError(
            "Configure WIFI_PASSWORD in device-local config_local.py"
        )

    if not DEVICE_TOKEN:
        raise ValueError(
            "Configure DEVICE_TOKEN in device-local config_local.py"
        )

    is_https = API_BASE_URL.startswith("https://")
    is_http = API_BASE_URL.startswith("http://")

    if not is_https and not (is_http and ALLOW_INSECURE_HTTP):
        raise ValueError(
            "Use HTTPS, or enable ALLOW_INSECURE_HTTP for local testing"
        )

    prefix_length = 8 if is_https else 7

    host = (
        API_BASE_URL[prefix_length:]
        .split("/", 1)[0]
        .split(":", 1)[0]
        .strip("[]")
        .lower()
    )

    if (
        not host
        or host in ("localhost", "127.0.0.1", "::1")
        or host.startswith("127.")
    ):
        raise ValueError(
            "API_BASE_URL must use the backend's reachable host"
        )

    if not device_id:
        raise ValueError(
            "A stable device ID is required"
        )
