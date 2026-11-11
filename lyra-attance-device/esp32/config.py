"""Central configuration for the Lyra Pulse ESP32 fingerprint attendance device."""

import os

# ------------------------------------------------------------
# Wi-Fi
# ------------------------------------------------------------
# Use a 2.4 GHz Wi-Fi network; ESP32 does not support 5 GHz.
# Set these in the environment before flashing or running the device.
WIFI_SSID = os.getenv("LYRA_WIFI_SSID", "YOUR_WIFI_SSID")
WIFI_PASSWORD = os.getenv("LYRA_WIFI_PASSWORD", "YOUR_WIFI_PASSWORD")
WIFI_TIMEOUT_SECONDS = int(os.getenv("LYRA_WIFI_TIMEOUT_SECONDS", "20"))
WIFI_RETRY_COUNT = int(os.getenv("LYRA_WIFI_RETRY_COUNT", "3"))

# ------------------------------------------------------------
# Device identity
# ------------------------------------------------------------
DEVICE_ID = os.getenv("LYRA_DEVICE_ID", "")
DEVICE_TOKEN = os.getenv("LYRA_DEVICE_TOKEN", "")
TEST_MODE = os.getenv("LYRA_TEST_MODE", "false").lower() == "true"

# ------------------------------------------------------------
# API
# ------------------------------------------------------------
# Update to the actual Django backend URL before deployment.
API_BASE_URL = os.getenv("LYRA_API_BASE_URL", "https://localhost:8000")
API_FINGERPRINT_ENDPOINT = "/api/v1/attendance/fingerprint/events/"
API_DEVICE_HEARTBEAT = "/api/v1/devices/{device_id}/heartbeat/"
API_DEVICE_ENROLLMENT_PENDING = "/api/v1/devices/{device_id}/enrollment/pending/"
API_DEVICE_ENROLLMENT_RESULT = "/api/v1/devices/{device_id}/enrollment/{enrollment_id}/result/"
API_TIMEOUT = int(os.getenv("LYRA_API_TIMEOUT", "10"))
API_RETRY_COUNT = int(os.getenv("LYRA_API_RETRY_COUNT", "2"))
HEARTBEAT_INTERVAL_SECONDS = int(os.getenv("LYRA_HEARTBEAT_INTERVAL_SECONDS", "60"))

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

# Linux / ESP32 serial configuration for MicroPython development
SERIAL_PORT = os.getenv("LYRA_SERIAL_PORT", "/dev/ttyUSB0")

# ------------------------------------------------------------
# Optional: ensure no sensitive data is ever printed in logs
# ------------------------------------------------------------
def safe_config_summary():
    return {
        "device_id": DEVICE_ID,
        "wifi_ssid": "***configured***",
        "api_base_url": API_BASE_URL,
        "test_mode": TEST_MODE,
    }
