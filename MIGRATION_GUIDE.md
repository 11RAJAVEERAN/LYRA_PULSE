# Migration and Deployment Guide

## Database state

The live database identity, schema, applied migrations, and records are UNKNOWN. ZIP migration files are not proof that any migration has been applied. Do not run these migrations against a production database until its state and a verified backup are known.

## New migrations

1. `employees.0003_attendance_permissions_audit` adds three boolean permissions and an audit table. Existing employee rows are backfilled to GPS ON, photo ON, biometric OFF to retain Project B's previous mobile attendance behavior. New employees use all OFF. The migration reverse function does not restore original field values; because these columns did not previously exist, rollback drops them and the audit table.
2. `attendance.0002_sessions_devices_events` removes `unique_employee_attendance_per_day`, allows null GPS/photo evidence for biometric/manual attendance, and adds source/device/event/audit structures. Existing attendance records are retained; no record rewrite or deletion is intended.
3. Project A device/fingerprint apps add independent tables. Their migrations are retained as a sequence and are not copied into Project B's attendance schema.

## Backup, inspect, validate, deploy

For PostgreSQL, take a custom-format backup and verify that it is nonempty:

```powershell
pg_dump --format=custom --file=lyra-before-integration.dump --dbname="$env:DB_NAME"
Get-Item .\lyra-before-integration.dump | Select-Object Length
```

Restore it to a separate disposable database and test the restore before production work:

```powershell
createdb lyra_restore_check
pg_restore --dbname=lyra_restore_check .\lyra-before-integration.dump
```

Use the production database's existing connection variables in a secure environment; never put credentials in a command transcript or this package. First run against a restored staging database:

```powershell
python manage.py showmigrations
python manage.py migrate --plan
python manage.py migrate
python manage.py check
```

Verify existing attendance counts and employee counts before/after, confirm old attendance photo paths still resolve, check migration rows, verify existing employees have GPS/photo ON and biometric OFF, and confirm new employees get all permissions OFF. Then exercise mobile and device attendance against staging. Production cutover should use a maintenance window and a fresh backup.

## Rollback

Take another backup immediately before deployment. Prefer rolling back application code only if the forward schema remains backward compatible. Reversing attendance migration restores the unique employee/day constraint and can fail if multi-session rows have been created. Before reversal, export/resolve additional sessions without deleting business data; do not run `migrate attendance 0001` blindly. Reversing the employee permission migration removes permission/audit columns and discards permission-change history. Restore the verified backup into a separate database if rollback is needed, then plan cutover explicitly.

No backup, restore, migration, PostgreSQL compatibility test, or production operation was executed for this package.
