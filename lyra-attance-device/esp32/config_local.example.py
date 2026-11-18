"""Copy to config_local.py on the ESP32 and fill in device-local values."""

WIFI_SSID = "TP-LINK_9BAF"
WIFI_PASSWORD = "44639518"
DEVICE_ID = "ESP32"  # Leave blank to derive a stable ID from the full ESP32 MAC address.
DEVICE_TOKEN = "6PPdEkBucSEk-CASvr2IVPTqabMz4bLWA1BEHUJlIUQ"  # One-time token from Admin > Devices; never commit the real value.
ALLOW_INSECURE_HTTP = True
API_BASE_URL = "http://192.168.1.100:8000/api/v1"
