"""Compatibility shim for `utime` during local debugging and tests."""

import time as _time


def ticks_ms():
    return int(_time.time() * 1000)


def ticks_add(ticks, delta):
    return ticks + delta


def ticks_diff(end, start):
    return end - start


def sleep_ms(ms):
    _time.sleep(ms / 1000)


def sleep(seconds):
    _time.sleep(seconds)
