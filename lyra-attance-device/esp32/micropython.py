"""Compatibility shim for `micropython.const` in CPython-based debug runs."""


def const(value):
    return value
