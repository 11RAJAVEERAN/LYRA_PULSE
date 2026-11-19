"""Copy to config_local.py on the ESP32 and fill in device-local values."""

WIFI_SSID = "TP-LINK_9BAF"
WIFI_PASSWORD = "44639518"
DEVICE_ID = "ESP32"  # Leave blank to derive a stable ID from the full ESP32 MAC address.
DEVICE_TOKEN = "ktIK7ZOps17SCBmARpxK4B-quSpw3n1Qg8Qu1l8g_0c"  # One-time token from Admin > Devices; never commit the real value.
ALLOW_INSECURE_HTTP = True
API_BASE_URL = "http://192.168.1.104:8000"
