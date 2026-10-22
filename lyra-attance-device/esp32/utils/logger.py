"""Safe logging helper for the ESP32 fingerprint terminal."""

try:
    import utime
except ImportError:  # pragma: no cover - local CPython compatibility
    import time as utime


def log(tag, message):
    timestamp = getattr(utime, "ticks_ms", lambda: 0)()
    print("[%s] [%s] %s" % (timestamp, tag, message))
