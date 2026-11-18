#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PORT=${PORT:-/dev/cu.usbserial-5B150103211}
MPREMOTE_BIN=${MPREMOTE_BIN:-/opt/anaconda3/envs/lyraPulseEnv314/bin/mpremote}
if [ -n "${PYTHON_BIN:-}" ]; then
    :
else
    PYTHON_BIN=$(dirname "$MPREMOTE_BIN")/python
fi

usage() {
    echo "Usage: ./esp32.sh {run|stop|logs}" >&2
    exit 2
}

check_mpremote() {
    if [ ! -x "$MPREMOTE_BIN" ]; then
        echo "mpremote executable not found: $MPREMOTE_BIN" >&2
        exit 1
    fi
}

check_serial_port_available() {
    if ! command -v lsof >/dev/null 2>&1; then
        echo "Cannot verify serial-port ownership because lsof is unavailable; refusing to access the ESP32." >&2
        exit 1
    fi
    if [ ! -e "$PORT" ]; then
        echo "Configured ESP32 serial port does not exist: $PORT" >&2
        exit 1
    fi

    port_owners=$(lsof -nP "$PORT" 2>/dev/null || true)
    if [ -n "$port_owners" ]; then
        echo "ESP32 serial port is already open; close the listed process before retrying." >&2
        printf '%s\n' "$port_owners" >&2
        echo "No command was sent to the ESP32." >&2
        exit 1
    fi
}

run_firmware() {
    check_mpremote
    check_serial_port_available

    firmware_files='
boot.py
config.py
config_local.py
main.py
drivers/__init__.py
drivers/oled.py
drivers/r307.py
hardware/__init__.py
hardware/buzzer.py
hardware/status_led.py
hardware/touch_sensor.py
lib/__init__.py
lib/font5x8.py
lib/ssd1306.py
services/__init__.py
services/api_service.py
services/event_queue.py
services/fingerprint_service.py
services/wifi_service.py
utils/__init__.py
utils/device_id.py
utils/logger.py
'

    echo "Serial port is available: $PORT"
    set -- connect "$PORT" resume fs ls :
    set -- "$@" + exec "import hashlib, os; hashlib.sha256(); dirs=('drivers','hardware','lib','services','utils'); [os.mkdir(d) for d in dirs if d not in os.listdir('/')]"

    for relative_path in $firmware_files; do
        if [ ! -f "$SCRIPT_DIR/$relative_path" ]; then
            echo "Required firmware file is missing: $relative_path" >&2
            exit 1
        fi
        echo "Validated local firmware file: $relative_path"
        set -- "$@" + fs cp "$SCRIPT_DIR/$relative_path" ":$relative_path"
    done

    echo "Starting one mpremote session: hash-check files, copy changes, then request reset."
    echo "If raw-REPL entry fails, this command will not retry."
    set -- "$@" + reset
    if "$MPREMOTE_BIN" "$@"; then
        echo "mpremote confirmed the file operations and reset command completed."
        echo "Firmware startup was not independently verified."
    else
        result=$?
        echo "ESP32 run failed; file-transfer or reset completion was not confirmed." >&2
        echo "The operation may be partial. No automatic retry was attempted." >&2
        return "$result"
    fi
}

stop_firmware() {
    check_mpremote
    check_serial_port_available
    echo "Stopping the running MicroPython program without resetting the board..."
    "$MPREMOTE_BIN" connect "$PORT" resume exec "print('Firmware stopped at the MicroPython REPL')"
}

show_logs() {
    check_serial_port_available
    if [ ! -x "$PYTHON_BIN" ]; then
        echo "Python executable not found: $PYTHON_BIN" >&2
        exit 1
    fi

    echo "Reading ESP32 serial output from $PORT. Press Ctrl+C to stop viewing logs."
    "$PYTHON_BIN" - "$PORT" <<'PY'
import sys

import serial

port_name = sys.argv[1]
connection = serial.Serial(port=None, baudrate=115200, timeout=0.25)
connection.dtr = False
connection.rts = False
connection.port = port_name

try:
    connection.open()
except serial.SerialException as exc:
    print("Unable to open ESP32 serial port %s: %s" % (port_name, exc), file=sys.stderr)
    sys.exit(1)

try:
    while True:
        output = connection.read(256)
        if output:
            sys.stdout.buffer.write(output)
            sys.stdout.buffer.flush()
except KeyboardInterrupt:
    print("\nStopped log viewing; no command was sent to the ESP32.", file=sys.stderr)
finally:
    connection.close()
PY
}

case "${1:-}" in
    run)
        [ "$#" -eq 1 ] || usage
        run_firmware
        ;;
    stop)
        [ "$#" -eq 1 ] || usage
        stop_firmware
        ;;
    logs)
        [ "$#" -eq 1 ] || usage
        show_logs
        ;;
    *)
        usage
        ;;
esac
