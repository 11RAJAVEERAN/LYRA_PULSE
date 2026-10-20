"""Central configuration for the Lyra Pulse ESP32 fingerprint attendance device."""

# ------------------------------------------------------------
# Wi-Fi
# ------------------------------------------------------------
# Replace these with your real values before flashing to a device.
WIFI_SSID = "TP-Link_9BAF_5G"
WIFI_PASSWORD = "44639518"
WIFI_TIMEOUT_SECONDS = 20
WIFI_RETRY_COUNT = 3
    
# ------------------------------------------------------------
# Device identity
# ------------------------------------------------------------
DEVICE_ID = "LYRA-DEVICE-001"
DEVICE_TOKEN = ""
TEST_MODE = True

# ------------------------------------------------------------
# API
# ------------------------------------------------------------
# Update to the actual Django backend URL before deployment.
API_BASE_URL = "http://192.168.1.13:8000"
API_FINGERPRINT_ENDPOINT = "/api/v1/attendance/fingerprint/"
API_TIMEOUT = 10
API_RETRY_COUNT = 2

# ------------------------------------------------------------
# UART fingerprint sensor
# ------------------------------------------------------------
UART_ID = 2
UART_BAUDRATE = 57600
UART_TX_PIN = 17
UART_RX_PIN = 16
R307_PASSWORD = 0x00000000

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
GREEN_LED_PIN = 18
RED_LED_PIN = 19

# ------------------------------------------------------------
# Behavior and safety
# ------------------------------------------------------------
FINGERPRINT_COOLDOWN = 5
MAX_TEMPLATE_COUNT = 1000

# Linux / ESP32 serial configuration for MicroPython development
SERIAL_PORT = "/dev/cu.usbserial-5B150103211"

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
