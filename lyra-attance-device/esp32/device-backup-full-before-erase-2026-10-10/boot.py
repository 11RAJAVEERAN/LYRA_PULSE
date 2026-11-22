"""MicroPython boot module. Keep this minimal and safe."""

import gc

# Enable garbage collection early for stable runtime execution.
gc.collect()
