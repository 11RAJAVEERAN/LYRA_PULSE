"""Device ID generation and configuration helpers."""

from config import DEVICE_ID


def get_device_id():
    """Return a stable device identifier.

    Prefer the configured constant; otherwise use the full stable ESP32 MAC.
    """
    if DEVICE_ID:
        return DEVICE_ID

    try:
        import network
        sta = network.WLAN(network.STA_IF)
        if sta:
            mac = sta.config("mac")
            if mac:
                return "LYRA-%02X%02X%02X%02X%02X%02X" % tuple(mac[-6:])
    except Exception:
        pass

    raise RuntimeError("No configured device ID and ESP32 MAC address is unavailable")
