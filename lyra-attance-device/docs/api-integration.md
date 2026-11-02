# API integration

The firmware uses the existing Django device APIs. The backend source is in
`lyrapulse-backend`; these routes are implemented and are not placeholders.

## Device authentication

Device requests use the configured device token in the `Authorization` header
as `Device <token>`. Requests use JSON and the common success envelope:

```json
{
  "success": true,
  "message": "Operation successful",
  "data": {}
}
```

## Enrollment polling

`GET /api/v1/devices/{device_id}/enrollment/pending/` returns an empty `data`
object when there is no pending enrollment, or a command containing
`enrollment_id`, `employee_id`, `action`, and `finger`. The device captures and
verifies the fingerprint locally; the employee-to-device mapping is completed
only after the backend accepts the reported successful enrollment.

The device reports enrollment progress to
`POST /api/v1/devices/{device_id}/enrollment/{enrollment_id}/result/`:

- `WAITING_FOR_SECOND_SCAN`
- `PROCESSING`
- `SUCCESS` with `fingerprint_slot`
- `FAILED` with `error_code`

## Attendance

`POST /api/v1/attendance/fingerprint/` accepts the existing device payload:

```json
{
  "device_id": "LYRA-DEVICE-001",
  "fingerprint_slot": 23
}
```

The backend authenticates the device, resolves the active employee mapping for
that slot, and applies its existing check-in/check-out rules. The device must
not infer the attendance action locally. A successful response includes the
employee name and a `status` of `CHECKED_IN` or `CHECKED_OUT`; duplicate scans
may include `duplicate: true`. Firmware success feedback is shown only when
the response contains a valid status and employee name.

## Integration constraints

- Preserve the endpoint paths, methods, authentication, and payload fields.
- Never send raw fingerprint images; only the matched slot is sent.
- Attendance requests are not retried automatically after a timeout because a
  retry could change the attendance state.
- Use HTTPS in production and protect `DEVICE_TOKEN` in device configuration.
