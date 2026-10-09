# Lyra Pulse Backend

Lyra Pulse Django REST backend for employee/HR management, device-managed fingerprint enrollment, and fingerprint attendance. No frontend or mobile UI is included.

## Architecture

The project is split into Django apps for accounts, employees, branches, departments, designations, devices, fingerprints, attendance, and shared API concerns. OTP generation and verification live in `apps/accounts/services/`; views only coordinate validation, services, and response formatting. PostgreSQL is used whenever `DB_NAME` is configured, while SQLite is a local fallback for development and tests.

## Setup

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements/development.txt
cp .env.example .env
```

Set `DB_NAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`, and `DB_PORT` in `.env` for PostgreSQL. Keep `DB_NAME` unset for the SQLite development fallback.

```bash
python manage.py makemigrations
python manage.py migrate
python manage.py seed_demo_data
python manage.py runserver
python manage.py check
python manage.py test
```

## Phase 1 API

- `POST /api/v1/auth/send-otp/`
- `POST /api/v1/auth/resend-otp/`
- `POST /api/v1/auth/verify-otp/`
- `POST /api/v1/auth/token/refresh/`
- `POST /api/v1/auth/logout/`
- `GET /api/v1/auth/me/`
- `GET /api/v1/branches/` (HR/SUPERADMIN)
- `POST /api/v1/employees/` (HR/SUPERADMIN)
- `POST /api/v1/employees/<employee_id>/fingerprints/enroll/` (HR/SUPERADMIN)
- `GET /api/v1/employees/<employee_id>/fingerprints/enrollments/<enrollment_id>/` (HR/SUPERADMIN)
- `GET /api/v1/devices/<device_id>/enrollment/pending/` (device credential)
- `POST /api/v1/devices/<device_id>/enrollment/<enrollment_id>/result/` (device credential)
- `POST /api/v1/attendance/fingerprint/` (device credential)
- `GET /api/v1/attendance/?employee_id=<id>&date=YYYY-MM-DD` (HR/SUPERADMIN JWT)
- `GET /api/v1/mobile/me/`
- `GET /api/schema/`
- `GET /api/docs/`

All API responses use `success`, `message`, `data`, and `errors` where applicable. JWT access tokens expire after 30 minutes; refresh tokens expire after 7 days and support blacklist logout.

## Development OTP flow

Run `seed_demo_data`, then request an OTP for `9876543210`. With `DEBUG=True` and `SMS_PROVIDER=mock`, the hashed OTP is stored in the database and the development mock logs the generated OTP. Production mode never logs or returns it. OTPs expire after five minutes, allow five attempts, and have a 30-second resend cooldown.

```bash
curl -X POST http://127.0.0.1:8000/api/v1/auth/send-otp/ \
  -H 'Content-Type: application/json' \
  -d '{"phone_number":"9876543210"}'

curl -X POST http://127.0.0.1:8000/api/v1/auth/verify-otp/ \
  -H 'Content-Type: application/json' \
  -d '{"phone_number":"9876543210","otp":"123456"}'
```

Use the returned access token as `Authorization: Bearer <token>` when calling `/api/v1/auth/me/` or `/api/v1/mobile/me/`.

## Device fingerprint enrollment

Apply migrations, then provision each ESP32 against an active branch. The generated device token is printed only once and is stored on the server as a password hash:

```bash
python manage.py migrate
python manage.py provision_device --device-id LYRA-DEVICE-001 --branch-code MAIN --name "Main Branch Sensor"
```

Configure the resulting device ID and token in the device's local `esp32/config.py`; do not commit the token. The device polls for enrollment jobs using its device credential and posts progress plus the sensor-confirmed slot. The backend stores fingerprint metadata only; raw images and templates remain in the R307S sensor. Use HTTPS in deployed environments.

## Fingerprint attendance

The employee only places a finger on the sensor: the ESP32 captures it and searches the R307 local template database, then sends the returned match slot to Django. The employee does not enter a slot. The device token is sent in the existing `Authorization: Device <token>` header. The backend resolves the active fingerprint mapping and employee, then checks the employee in or out against the Asia/Kolkata work date. Each IN/OUT pair is a separate attendance record, so sessions can repeat throughout the day. A scan within `ATTENDANCE_FINGERPRINT_SCAN_COOLDOWN_SECONDS` (default 5 seconds) of the latest action is reported as a duplicate without changing attendance.

```bash
curl -X POST http://127.0.0.1:8000/api/v1/attendance/fingerprint/ \
  -H 'Authorization: Device <device-token>' \
  -H 'Content-Type: application/json' \
  -d '{"device_id":"LYRA-DEVICE-001","fingerprint_slot":<r307_match_slot>}'
```

The check-in/check-out response includes `data.status`, `data.attendance_id`, `data.employee.id`, `data.employee.name`, `data.attendance_date`, `data.check_in_time`, and `data.check_out_time`.

HR/SUPERADMIN clients can retrieve all sessions for an employee and date using their existing JWT:

```bash
curl 'http://127.0.0.1:8000/api/v1/attendance/?employee_id=3&date=2026-10-08' \
  -H 'Authorization: Bearer <access-token>'
```

History includes completed and open sessions. `total_working_seconds` and `total_working_hours` sum completed sessions only; an open check-in remains visible but is not counted yet.

## Production notes

Set a strong `SECRET_KEY`, `DEBUG=False`, explicit `ALLOWED_HOSTS`, and production frontend origins in `CORS_ALLOWED_ORIGINS`. Run Gunicorn with `gunicorn config.wsgi:application`. Leave, reporting, and notifications are not implemented by this backend phase.