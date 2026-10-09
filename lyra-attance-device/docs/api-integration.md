# API integration

## Existing backend state

The checked-in Django backend exposes authentication and employee endpoints but no device attendance/fingerprint route was found during inspection.

Relevant files inspected:

- lyrapulse-backend/config/urls.py
- lyrapulse-backend/apps/accounts/urls.py
- lyrapulse-backend/apps/employees/urls.py

The current project includes these routes:

- /api/v1/auth/send-otp/
- /api/v1/auth/verify-otp/
- /api/v1/auth/me/
- /api/v1/mobile/me/

No `/api/v1/attendance/` or fingerprint-specific endpoint is currently implemented.

## Device payload

The firmware is written to send this structure:

```json
{
  "device_id": "LYRA-DEVICE-001",
  "fingerprint_id": 23,
  "event_type": "fingerprint"
}
```

## Placeholder endpoint

The configuration currently targets:

- /api/v1/attendance/fingerprint/

This is a placeholder and should be replaced by the backend team when the actual device attendance endpoint is created.

## Security recommendations

- Use HTTPS in production.
- Store `DEVICE_TOKEN` in secure storage.
- Never send raw fingerprint images.
- Only send the matched template ID.
