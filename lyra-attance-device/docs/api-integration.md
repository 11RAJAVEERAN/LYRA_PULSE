# Device API integration

The ESP32 firmware authenticates requests with `Authorization: Device <token>`.
Configure the backend base URL with `LYRA_API_BASE_URL` using HTTPS; the firmware
rejects HTTP URLs. Keep `LYRA_DEVICE_TOKEN` in secure device configuration and
never commit credential values.

## Endpoints

- `POST /api/v1/attendance/fingerprint/events/` — submit a matched sensor slot
  with a stable event ID and occurrence timestamp.
- `POST /api/v1/devices/{device_id}/heartbeat/` — record the device's last-seen
  time. Firmware sends a heartbeat every `LYRA_HEARTBEAT_INTERVAL_SECONDS`
  (default 60 seconds).
- `GET /api/v1/devices/{device_id}/enrollment/pending/` — poll for an enrollment.
- `POST /api/v1/devices/{device_id}/enrollment/{enrollment_id}/result/` — report
  enrollment outcome.

The management API derives device status from `last_seen`. A device is Online
when its last valid heartbeat is within `DEVICE_ONLINE_THRESHOLD_SECONDS`
(default 300 seconds); otherwise it is Offline.

Attendance payloads include `device_id`, `event_id`, `fingerprint_slot`, and
`occurred_at`. Raw fingerprint images are not transmitted.

## Transport and credential handling

- Use HTTPS with valid server certificates.
- Do not configure an HTTP fallback.
- Store device tokens only in protected device configuration and rotate them
  through the authorized management workflow.
- Do not log or commit raw tokens.

Certificate-chain and hostname validation depend on the MicroPython TLS
implementation installed on the physical device. Verify that runtime before
deployment; the host-side tests do not establish hardware TLS validation.
