"""Central configuration for the Lyra Pulse ESP32 fingerprint attendance device."""

# ------------------------------------------------------------
# Wi-Fi
# ------------------------------------------------------------
# Use a 2.4 GHz Wi-Fi network; ESP32 does not support 5 GHz.
# Replace these with your real values before flashing to a device.
WIFI_SSID = "Airtel_vasa_3220"
WIFI_PASSWORD = "Air@69764"
WIFI_TIMEOUT_SECONDS = 20
WIFI_RETRY_COUNT = 3
    
# ------------------------------------------------------------
# Device identity
# ------------------------------------------------------------
DEVICE_ID = "LYRA-DEVICE-001"
DEVICE_TOKEN = "1WCnPgVGKZH80X1Pz33JXs8z8dfIqFwbDIGjAgB8o3M"
TEST_MODE = True

# ------------------------------------------------------------
# API
# ------------------------------------------------------------
# Update to the actual Django backend URL before deployment.
API_BASE_URL = "http://192.168.1.8:8000"
API_FINGERPRINT_ENDPOINT = "/api/v1/attendance/fingerprint/"
API_DEVICE_ENROLLMENT_PENDING = "/api/v1/devices/{device_id}/enrollment/pending/"
API_DEVICE_ENROLLMENT_RESULT = "/api/v1/devices/{device_id}/enrollment/{enrollment_id}/result/"
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
