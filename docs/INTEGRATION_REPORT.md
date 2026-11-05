# LYRA PULSE Project A → Project B Integration Report

## Scope and source identification

- Project B is the base application from `LYRA_PULSE B.zip`: Django backend (`lyrapulse-backend`), React/Vite Admin (`lyrapulse-admin`), and Flutter application (`lyrapulse-mobile`).
- Project A is the source of the ESP32/R307 firmware and the `devices` and `fingerprints` Django apps from `LYRA_PULSE_MAIN A.zip`.
- The supplied `ChatGPT.txt` transcript contains earlier analysis-only instructions, later decisions, and an earlier comparison report. The current master request explicitly authorizes implementation and supersedes the transcript's earlier “do not modify code” stage instruction.
- The transcript's confirmed decisions used here: multiple daily sessions; alternating fingerprint scans; photo required on both mobile actions when enabled; GPS remains required; cross-method sessions allowed; new employees default all three permissions OFF; only Super Admin/Admin edit; ignore photos when photo permission is OFF; and queue offline device scans for later sync.

## Confirmed source findings

- Project B's `Attendance` model originally had one row per employee/day enforced by `unique_employee_attendance_per_day`; mobile check-in/out mutate the same row.
- Project B already had server-side GPS location verification, branch scoping, employee authentication, photo validation/storage, attendance admin list/summary/detail/export, and a Flutter client.
- Project A provides hashed device tokens, device provisioning, employee fingerprint enrollment state, sensor slot mappings, R307 MicroPython firmware, and protocol/hardware tests.
- The database connection configuration supports PostgreSQL when `DB_NAME` is set, otherwise SQLite. The actual database and applied migrations are UNKNOWN; no live database was accessed.
- Project A's active firmware configuration contained Wi-Fi and device credentials. Those values were not copied into this package. Treat the exposed values as compromised and rotate them before any device is used.
- Project B's archive also contained a populated backend `.env`, including configured `SECRET_KEY`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, and related settings. It is excluded from the release ZIP; the included `.env.example` has been replaced with placeholders. Rotate any real credentials from the supplied `.env` if it was used outside a local test environment.

## Implemented in Project B

- Added employee biometric, mobile GPS, and photo permission fields, with a new employee model default of OFF. Migration `employees.0003` deliberately backfills existing employees to GPS ON/photo ON/biometric OFF to preserve Project B's prior effective mobile flow; it is reversible only in the schema sense, and its reverse data operation does not restore previous values.
- Added an employee permission audit model with actor, previous values, new values, and timestamp.
- Added Project A device/fingerprint apps, device token authentication, provisioning command, enrollment endpoints, scoped device management API, and Admin Web device provisioning/enrollment initiation page.
- Added `AttendanceEvent` action records, `DeviceAttendanceEvent` idempotency ledger, attendance method/source, optional GPS/photo evidence for non-mobile sessions, and a migration removing the one-row/day constraint without deleting or rewriting existing attendance rows.
- Updated mobile attendance service to enforce GPS permission, require photos on both actions only when photo permission is enabled, discard submitted photos when that permission is OFF, support repeated sessions, and close an open session across midnight. An abandoned open session remains open until a later checkout or Admin manual action; there is no automatic checkout.
- Added device event submission with device-token authentication, active-device/branch/fingerprint mapping checks, biometric permission enforcement, event UUID idempotency, timestamp validation, device/employee row locking, alternating check-in/check-out behavior, and method-level action auditing.
- Added Super Admin/Admin scoped manual attendance; the action alternates according to the employee's open-session state and records the acting admin.
- Updated Admin attendance list/detail/export representations to include session details and sum completed session duration; the detail drawer renders per-session method/actor events.
- Added employee permission controls and manual attendance action to the Admin employee panel; added device provisioning/list/status and enrollment initiation to a device page.
- Updated Flutter's today model/controller to parse sessions, permit another check-in after a completed session, and display multiple session times.
- Added Project A firmware source and a persistent FIFO queue with stable event IDs. The device attempts to sync queued events whenever connectivity is available.
- Replaced copied firmware secret values with blank configuration placeholders. Backup folders and enrolled-person text dumps are excluded from the release package.

## Files created or materially modified

Key backend files: `lyrapulse-backend/apps/attendance/{models.py,services.py,views.py,urls.py,admin_services.py,admin_serializers.py,admin_views.py,device_serializers.py,device_views.py,migrations/0002_sessions_devices_events.py,test_integration_rules.py}`; `apps/employees/{models.py,serializers.py,views.py,migrations/0003_attendance_permissions_audit.py}`; new `apps/devices/` and `apps/fingerprints/`; `config/{settings.py,urls.py}`.

Key Admin Web files: `lyrapulse-admin/src/features/devices/pages/DevicesPage.jsx`; `src/app/router/routes.jsx`; `src/features/employees/{employeeFormModel.js,api/employeesApi.js,components/EmployeeDetailsPanel.jsx}`.

Key Flutter files: `lyrapulse-mobile/lib/data/models/attendance_model.dart`; `lib/features/attendance/controllers/attendance_controller.dart`; `lib/features/home/widgets/today_summary_card.dart`.

Key firmware files: `lyra-attance-device/esp32/{config.py,main.py,drivers/oled.py,services/api_service.py,services/wifi_service.py,services/event_queue.py,tests/test_event_queue.py}`.

Other Project B files were retained. Generated Python caches, local Android SDK configuration, Git internals, dependency/build directories, and Project A's dated device backups were excluded from the ZIP.

## Not fully integrated / limitations

- Fingerprint enrollment initiation and status polling are in Admin Web; fingerprint mapping inventory/deactivation, device heartbeat/health screens, and event-monitoring screens are not complete.
- Flutter still uses Project B's GPS/photo flow and current-session cards; it does not offer a separate history screen for all past sessions or proactively hide attendance controls based on employee permissions. The server rejects disallowed actions.
- No real PostgreSQL connection, existing data, migration state, backup, or restore was available for validation.
- The audit is implementation-focused rather than an exhaustive semantic review of every line in every source file in both ZIPs. The delivered inventory covers every included release file; unrelated B-only UI, all A/B matching-file diffs, and the transcript's previous file-count claims were not independently exhaustively analyzed. The transcript's counts are explicitly marked unverified in `ARCHITECTURE_AUDIT.md`.
- Django/API tests, React production build, Flutter analyzer/build, MicroPython compile on ESP32, network synchronization, and physical R307/OLED/ESP32 behavior were not verified in this environment.
- No Git working-tree status/diff was available; source was extracted from ZIP archives into a separate working copy.

See `API_DOCUMENTATION.md`, `MIGRATION_GUIDE.md`, `DEVICE_SETUP.md`, and `TEST_REPORT.md` for implementation details and verification state.

The full release file inventory is in SOURCE_INVENTORY.md.
