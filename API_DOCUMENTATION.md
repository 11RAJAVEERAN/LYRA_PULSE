# Integrated API Notes

All routes are under `/api/v1/`. Normal user APIs use the existing Project B JWT authentication. Device attendance/enrollment uses `Authorization: Device <raw-token>`; only the token hash is stored. Responses use Project B's `{success,message,data}` envelope except standard validation-error envelopes.

## Mobile attendance

- `POST /attendance/verify-location/` (JWT employee): existing `{latitude,longitude,accuracy}`; GPS permission and current employee/branch location are checked.
- `POST /attendance/check-in/` and `POST /attendance/check-out/` (JWT employee, multipart): GPS fields plus optional `photo`. GPS permission is mandatory. If photo permission is ON, the photo is mandatory on both actions. When permission is OFF, `photo` is removed from request parsing before persistence and does not appear in responses. Check-in opens a session; check-out closes the current open session, including one started before midnight. Cross-method closing is allowed.
- `GET /attendance/today/` returns current state and `sessions[]` for today plus any open overnight session. State is `NOT_CHECKED_IN`, `CHECKED_IN`, or `CHECKED_OUT`.

## Fingerprint and devices

- `POST /attendance/fingerprint/events/` (device token): `{device_id,event_id,fingerprint_slot,occurred_at}`. Event ID is a UUID unique per device. Active device, branch, mapping, employee, biometric permission, event time, and sequence are validated; timestamps ahead of the backend clock are rejected. The server chooses check-in/check-out from locked attendance state and responds idempotently for a successfully recorded event.
- `GET /devices/` (Admin/HR view permission, scoped) lists safe device fields only.
- `POST /devices/` (Super Admin/Admin, branch scope): `{device_id,name,branch_id}`. The raw `provisioning_token` is returned once; the database stores its hash.
- `PATCH /devices/` (Super Admin/Admin, branch scope): `{device_id,is_active?,name?}`.
- `GET /devices/{device_id}/enrollment/pending/` (device token) and `POST /devices/{device_id}/enrollment/{enrollment_id}/result/` (device token) are Project A enrollment protocol endpoints.
- `POST /fingerprints/employees/{employee_id}/enrollments/` (employee-view permission and branch scope): `{device_id,finger}`. Employee biometric permission must be enabled first.
- `GET /fingerprints/employees/{employee_id}/enrollments/{enrollment_id}/` returns status.

## Attendance permissions and admin actions

- Existing employee create/update routes `/employees/` and `/employees/{id}/` include `biometric_attendance_enabled`, `mobile_gps_attendance_enabled`, and `photo_attendance_enabled` for Super Admin/Admin. Other roles cannot write these fields; permission changes create an audit row.
- `POST /attendance/admin/manual/` (Super Admin/Admin, employee branch scope): `{employee_id}`. Server alternates check-in/check-out from locked open-session state and records actor, method, and timestamp.
- Existing `/attendance/admin/`, `/summary/`, `/export/`, and `/{employee_id}/` remain. Rows/details add `session_count` and `sessions[]`; CSV adds session count and JSON detail while retaining prior columns.

Validation errors include `401`, `403`, `404`, and `409` as applicable. Invalid or out-of-order device timestamp returns `400`; device event IDs are stable across queue retries. No API integration run was possible without Django/dependencies/database.
