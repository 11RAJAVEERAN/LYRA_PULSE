"""Copy to config_local.py on the ESP32 and fill in device-local values."""

WIFI_SSID = "TP-LINK_9BAF_5G"
WIFI_PASSWORD = "44639518"
DEVICE_ID = ""  # Leave blank to derive a stable ID from the full ESP32 MAC address.
DEVICE_TOKEN = ""  # One-time token from Admin > Devices; never commit the real value.
API_BASE_URL = "http://192.168.1.8:8000/api/v1"
