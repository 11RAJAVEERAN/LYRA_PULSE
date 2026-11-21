"""Copy to config_local.py on the ESP32 and fill in device-local values."""

WIFI_SSID = "sury@"
WIFI_PASSWORD = "Surya2003"
DEVICE_ID = "ESP32"  # Leave blank to derive a stable ID from the full ESP32 MAC address.
DEVICE_TOKEN = "PFEfF5ojlen_K8IbrycW7lxAHgbQv3D0jQFQq4yOzq8"  # One-time token from Admin > Devices; never commit the real value.
ALLOW_INSECURE_HTTP = True
API_BASE_URL = "http://10.174.138.23:8000"
