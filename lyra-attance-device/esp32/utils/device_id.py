"""Device ID generation and configuration helpers."""

from config import DEVICE_ID


def get_device_id():
    """Return a stable device identifier.

    Prefer the configured constant; if empty, produce a fallback based on the
    ESP32 MAC address when available.
    """
    if DEVICE_ID:
        return DEVICE_ID

    try:
        import network
        sta = network.WLAN(network.STA_IF)
        if sta:
            mac = sta.config("mac")
            if mac:
                return "LYRA-%02X%02X%02X" % (mac[0], mac[1], mac[2])
    except Exception:
        pass

    return "LYRA-DEVICE-001"
