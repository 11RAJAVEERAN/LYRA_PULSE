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

## Organizations, branches and admin scope

`Organization -> Branch -> Department / Employee`. ADMIN/HR/MANAGER users belong to one `Organization` and may manage only their `allowed_branches` (all of which must belong to that organization). SUPERADMIN is global. Set these up in Django Admin: Organizations -> Branches -> Users. Existing branches/admins are left unassigned by the migration; until a scope is assigned, a non-SUPERADMIN admin sees no employee data.

First SUPERADMIN (no mobile is hardcoded):

```bash
python manage.py ensure_superadmin --phone <10-digit mobile>   # or set LYRA_SUPERADMIN_PHONE
# or: python manage.py createsuperuser
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

## Employee attendance API (mobile)

Employee-role JWT required. The employee is `request.user`'s profile and the branch is the employee's assigned branch;
`employee_id`, `branch_id` and any client time are ignored. All responses use the `success/message/data|errors` envelope.
Business errors return `errors.code` (e.g. `OUTSIDE_ATTENDANCE_RADIUS`, `ALREADY_CHECKED_IN`, `NOT_CHECKED_IN`).

- `POST /api/v1/attendance/verify-location/` (JSON or form): `latitude`, `longitude`, `accuracy` -> UX pre-check only, never an authorisation.
- `POST /api/v1/attendance/check-in/` (multipart): `latitude`, `longitude`, `accuracy`, `photo` (JPEG/PNG, max 5 MB).
- `POST /api/v1/attendance/check-out/` (multipart): same fields; updates today's existing row.
- `GET  /api/v1/attendance/today/` -> `NOT_CHECKED_IN | CHECKED_IN | CHECKED_OUT`.

Set each branch's location in Django Admin -> Branches -> *Attendance Location* (latitude, longitude, allowed radius in meters).
A branch without coordinates rejects attendance with `BRANCH_LOCATION_NOT_CONFIGURED`. Photos are stored under
`MEDIA_ROOT/attendance/{checkin,checkout}/YYYY/MM/DD/<uuid>.<jpg|png>` (served by Django only when `DEBUG=True`).

## Admin attendance API (web)

Read-only APIs for the React admin Attendance page. They read the SAME `Attendance` table the mobile app writes
to (no copies, no extra tables, no migrations), so a mobile check-in is visible to admins immediately.

**Auth / permissions:** JWT (`Authorization: Bearer <access>`) + the existing `employees.view_employee` permission
(ADMIN / HR / MANAGER role groups; SUPERADMIN always). EMPLOYEE-role users get `403`, anonymous `401`.
**Scope:** the same organization/branch scoping as the Employees API (`scope_queryset`). SUPERADMIN is global; every
other user only sees employees of their `allowed_branches`; a user with no scope sees nothing. `branch`,
`department` and `designation` ids outside your scope are rejected with `400` (indistinguishable from a
non-existent id, so nothing leaks). All responses use the usual `success / message / data | errors` envelope.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/v1/attendance/admin/` | Paginated table rows (present **and** absent employees) |
| GET | `/api/v1/attendance/admin/summary/` | `total_employees`, `present`, `absent` |
| GET | `/api/v1/attendance/admin/<employee_id>/` | Detail panel (check-in/out, GPS, photos) for one employee and date |
| GET | `/api/v1/attendance/admin/export/` | CSV download of the same rows (not paginated) |

**Query parameters** (list / summary / export): `date=YYYY-MM-DD` (single day) **or** `start_date` + `end_date`
(both required, inclusive); default is today. Future dates, `start_date > end_date`, mixing `date` with a range and
ranges over 92 days are `400`. For Today / This Week / This Month / Custom the web app simply sends the matching dates
(end date = today at most). Also: `branch`, `department`, `designation` (ids), `search` (employee name or code; phone
numbers are not searchable), and — list/export only — `status=present|absent` (case-insensitive),
`ordering` (`attendance_date`, `employee_name`, `check_in`, `check_out`, prefix `-` for descending), and — list only —
`page`, `page_size` (default 25, max 100). `summary` ignores `status`. Detail takes only `date`.

**Status rules — CURRENT:** `PRESENT` (the employee has an attendance record for that date) and `ABSENT` (an eligible
employee with no record for that date; derived on read, never stored, so nothing is "closed" early in the day).
Eligible = active employee + active user + (no joining date or joined on/before that date); an employee who has a
record is always listed for that date even if deactivated later. **FUTURE / NOT IMPLEMENTED:** `LATE`, `EARLY`,
`OVERTIME` (need shift/policy rules); there is no shift field and none is invented. Unsupported `status` values are `400`.

**List** (`data`): `count, page, page_size, total_pages, next, previous, start_date, end_date, results[]`. For a range
the list is one row per employee **per day** (a date is never collapsed into one status); rows are grouped by
`attendance_date` (newest first, or oldest first with `ordering=attendance_date`) and the other sort keys order rows
inside each date. Row:

```json
{"employee": {"id": 7, "employee_code": "EMP001", "name": "Arun Kumar", "profile_photo": null},
 "branch": {"id": 1, "name": "Cuddalore"}, "department": {"id": 2, "name": "Sales"}, "designation": {"id": 3, "name": "Executive"},
 "attendance_date": "2026-10-18", "status": "PRESENT", "state": "CHECKED_OUT",
 "has_check_in": true, "has_check_out": true,
 "check_in_at": "2026-10-18T09:12:00+05:30", "check_out_at": "2026-10-18T18:08:00+05:30",
 "working_seconds": 32160, "working_hours_display": "8h 56m",
 "check_in_location_verified": true, "check_out_location_verified": true}
```

An absent row has `status: "ABSENT"`, `state: "NOT_CHECKED_IN"`, `has_check_in/out: false` and `null` for every time,
working-hours and verification field.

**Working hours:** `check_out_at - check_in_at` in whole seconds (`working_seconds`) plus `working_hours_display`
(`"8h 56m"`). Only completed days have a value: checked in but not checked out (including today) is `null`, no live
duration is presented as a final one, and nothing is stored. Inconsistent data (out before in) is `null`.

**Summary:** `{"date": "2026-10-18", "start_date": ..., "end_date": ..., "total_employees": 48, "present": 42, "absent": 6}`.
For one date these are per-day counts and always equal what the list shows. For a range they count distinct
**employees**: `present` = at least one record in the range, `absent` = the rest (`date` is `null`). Late / overtime are not returned.

**Detail:** `{"employee": {id, employee_code, name, profile_photo, branch, department, designation}, "attendance_date", "status", "state",
"attendance_branch", "check_in": {time, latitude, longitude, accuracy_m, distance_from_branch_m, location_verified, photo} | null,
"check_out": {...} | null, "working_seconds", "working_hours_display"}`. Absent employee: `status: "ABSENT"`, `check_in`/`check_out` `null`.
`404` when the employee is not in your scope (or not part of that date's population). Coordinates are returned for a
map to render later; the backend calls no map service.

**Photos:** the database keeps only the relative path (`attendance/checkin/YYYY/MM/DD/<uuid>.jpg`). The API returns an
absolute URL built from the incoming request host (`request.build_absolute_uri`), or `null` when there is no photo. In
production serve `MEDIA_ROOT` from the web server / object storage (Django serves it only when `DEBUG=True`).

**Export:** `text/csv; charset=utf-8` (UTF-8 BOM for Excel), `Content-Disposition: attachment;
filename="attendance-report-<start>-to-<end>.csv"`, streamed. Same scope and filters as the list; one row per employee
per day (default oldest date first). Columns: Date, Employee ID, Employee Name, Branch, Department, Designation, Status,
Check In, Check Out, Working Hours, check-in latitude/longitude/accuracy/distance/verified/photo URL and the same six
for check-out. Times are in the project time zone. Text cells that start with `= + - @` are prefixed with `'`.

**Time zone:** `attendance_date` is the server's local date at check-in (`TIME_ZONE`), and the API filters on that
stored date, so nothing is shifted across midnight; timestamps stay timezone-aware.

Code: `apps/attendance/admin_services.py` (scope, present/absent, summary, working hours), `admin_serializers.py`
(query validation + representations), `admin_views.py`, `pagination.py`; tests in `test_admin_api.py`.

## Production notes

Set a strong `SECRET_KEY`, `DEBUG=False`, explicit `ALLOWED_HOSTS`, and production frontend origins in `CORS_ALLOWED_ORIGINS`. Run Gunicorn with `gunicorn config.wsgi:application`. Celery and Redis dependencies are included for later phases; attendance, device, leave, reporting, and notifications are intentionally not implemented until their specified phases.
# Attendance permissions

Administrators manage per-employee mobile, photo, location, biometric, and auto-punch-out settings through `GET /api/v1/attendance-permissions/`, `GET/PATCH /api/v1/attendance-permissions/{employee_id}/`, and `POST /api/v1/attendance-permissions/bulk/`. Access is limited to Super Admin and Admin users and employee records are restricted to their allowed branches. Changes are recorded in `AttendancePermissionAudit`.

Mobile check-in and check-out enforce the employee's mobile, photo, and location settings on the server. Existing employees that already had mobile attendance retain the previous photo and geofence requirements after migration. New employees receive disabled settings and must be configured by an administrator.

`auto_punch_out_enabled` is configuration only. The project currently has no configured task scheduler or shift-end rules to execute automatic checkout; integrate a reliable scheduler and shift end-time policy before treating enabled values as automatic behavior.
