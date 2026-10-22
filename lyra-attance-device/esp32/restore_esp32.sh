#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PORT=${PORT:-/dev/cu.usbserial-5B150103211}
MPREMOTE_BIN=${MPREMOTE_BIN:-/opt/anaconda3/envs/lyraPulseEnv314/bin/mpremote}
STAMP=$(date '+%Y%m%d-%H%M%S')
SOURCE_ARCHIVE="$SCRIPT_DIR/../esp32-source-before-restore-$STAMP.tar.gz"
DEVICE_BACKUP="$SCRIPT_DIR/device-backup-before-restore-$STAMP"

if [ ! -x "$MPREMOTE_BIN" ]; then
    echo "mpremote executable not found: $MPREMOTE_BIN" >&2
    exit 1
fi

echo "Archiving current ESP32 source to: $SOURCE_ARCHIVE"
tar -czf "$SOURCE_ARCHIVE" \
    --exclude='device-backup-*' \
    --exclude='__pycache__' \
    --exclude='.DS_Store' \
    -C "$SCRIPT_DIR" .

echo "Checking ESP32 connection and filesystem..."
"$MPREMOTE_BIN" connect "$PORT" fs tree :

mkdir -p "$DEVICE_BACKUP"
echo "Backing up current ESP32 filesystem to: $DEVICE_BACKUP"
"$MPREMOTE_BIN" connect "$PORT" fs cp -r : "$DEVICE_BACKUP/"

if [ ! -f "$DEVICE_BACKUP/config.py" ] || [ ! -f "$DEVICE_BACKUP/main.py" ]; then
    echo "ESP32 backup is incomplete; refusing to upload firmware." >&2
    exit 1
fi
echo "ESP32 backup verified (config.py and main.py present)."

echo "Ensuring firmware package directories exist..."
"$MPREMOTE_BIN" connect "$PORT" exec \
    "import os; dirs=('drivers','hardware','lib','services','utils'); [os.mkdir(d) for d in dirs if d not in os.listdir('/')]"

upload_file() {
    source_path=$1
    remote_path=$2
    if [ ! -f "$SCRIPT_DIR/$source_path" ]; then
        echo "Required source file is missing: $source_path" >&2
        exit 1
    fi
    echo "Uploading $source_path -> :$remote_path"
    "$MPREMOTE_BIN" connect "$PORT" fs cp \
        "$SCRIPT_DIR/$source_path" ":$remote_path"
}

upload_file boot.py boot.py
upload_file config.py config.py
upload_file main.py main.py
upload_file enroll.py enroll.py
upload_file hardware_test.py hardware_test.py
upload_file r307_uart_diagnostic.py r307_uart_diagnostic.py

upload_file drivers/__init__.py drivers/__init__.py
upload_file drivers/oled.py drivers/oled.py
upload_file drivers/r307.py drivers/r307.py
upload_file hardware/__init__.py hardware/__init__.py
upload_file hardware/buzzer.py hardware/buzzer.py
upload_file hardware/status_led.py hardware/status_led.py
upload_file lib/__init__.py lib/__init__.py
upload_file lib/font5x8.py lib/font5x8.py
upload_file lib/ssd1306.py lib/ssd1306.py
upload_file services/__init__.py services/__init__.py
upload_file services/api_service.py services/api_service.py
upload_file services/fingerprint_service.py services/fingerprint_service.py
upload_file services/wifi_service.py services/wifi_service.py
upload_file utils/__init__.py utils/__init__.py
upload_file utils/device_id.py utils/device_id.py
upload_file utils/logger.py utils/logger.py

echo "Verifying firmware imports on the ESP32..."
"$MPREMOTE_BIN" connect "$PORT" exec \
    "import config, drivers.oled, drivers.r307, hardware.buzzer, hardware.status_led, lib.ssd1306, services.api_service, services.fingerprint_service, services.wifi_service, utils.device_id, utils.logger, main, enroll, hardware_test, r307_uart_diagnostic; print('FIRMWARE IMPORTS OK')"

echo "Listing restored ESP32 files..."
"$MPREMOTE_BIN" connect "$PORT" fs tree :
echo "Restore complete. enroll.py was uploaded but not executed."
echo "Run main.py separately after reviewing import verification and hardware state."
