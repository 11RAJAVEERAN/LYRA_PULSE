# Lyra Pulse Backend

Phase 1 of the Lyra Pulse employee attendance and HR management API. This repository contains only the Django REST backend; no frontend or mobile UI is included.

## Architecture

The project is split into Django apps for accounts, employees, branches, departments, designations, and shared API concerns. OTP generation and verification live in `apps/accounts/services/`; views only coordinate validation, services, and response formatting. PostgreSQL is used whenever `DB_NAME` is configured, while SQLite is a local fallback for development and tests.

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

## Production notes

Set a strong `SECRET_KEY`, `DEBUG=False`, explicit `ALLOWED_HOSTS`, and production frontend origins in `CORS_ALLOWED_ORIGINS`. Run Gunicorn with `gunicorn config.wsgi:application`. Celery and Redis dependencies are included for later phases; attendance, device, leave, reporting, and notifications are intentionally not implemented until their specified phases.