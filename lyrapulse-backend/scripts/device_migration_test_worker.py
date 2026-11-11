import os
import re
import sqlite3
import sys
from datetime import timedelta
from pathlib import Path
from unittest.mock import patch


BACKEND_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_ROOT))


def _database_path_from_settings():
    from django.conf import settings

    database = settings.DATABASES.get("default", {})
    if database.get("ENGINE") != "django.db.backends.sqlite3":
        raise RuntimeError("Migration tests require SQLite.")

    expected = Path(os.environ["LYRA_MIGRATION_TEST_DB"]).resolve(strict=True)
    configured = Path(database.get("NAME", "")).resolve(strict=True)
    project_database = Path(os.environ["LYRA_PROJECT_DATABASE_PATH"]).resolve(strict=False)
    if configured != expected or configured == project_database:
        raise RuntimeError("The active Django database is not the expected disposable database.")
    if configured.is_relative_to(BACKEND_ROOT):
        raise RuntimeError("The active Django database is inside the project workspace.")
    return expected


def _verify_sqlite_path(path):
    uri = f"{path.as_uri()}?mode=rw"
    with sqlite3.connect(uri, uri=True) as raw_connection:
        rows = raw_connection.execute("PRAGMA database_list").fetchall()
    main_paths = [Path(row[2]).resolve(strict=True) for row in rows if row[1] == "main"]
    if main_paths != [path]:
        raise RuntimeError("SQLite opened a database other than the verified disposable database.")


def _verify_django_connection(path):
    from django.db import connections

    with connections["default"].cursor() as cursor:
        cursor.execute("PRAGMA database_list")
        rows = cursor.fetchall()
    main_paths = [Path(row[2]).resolve(strict=True) for row in rows if row[1] == "main"]
    if main_paths != [path]:
        raise RuntimeError("Django's active SQLite connection is not the verified disposable database.")


def _verify_before_write(execute, sql, params, many, context):
    write_statement = re.match(
        r"\s*(?:/\*.*?\*/\s*)?(INSERT|UPDATE|DELETE|REPLACE|CREATE|ALTER|DROP|VACUUM|REINDEX)\b",
        sql,
        re.IGNORECASE | re.DOTALL,
    )
    if write_statement:
        from django.db import connection

        path = _database_path_from_settings()
        raw_connection = connection.connection
        if raw_connection.row_factory is not None:
            raise RuntimeError("Migration tests require Django's default SQLite row factory.")
        rows = raw_connection.execute("PRAGMA database_list").fetchall()
        main_paths = [Path(row[2]).resolve(strict=True) for row in rows if row[1] == "main"]
        if main_paths != [path]:
            raise RuntimeError("A write was attempted against an unverified SQLite database.")
    return execute(sql, params, many, context)


def _initialize():
    path = _database_path_from_settings()
    _verify_sqlite_path(path)

    import django

    django.setup()
    _verify_django_connection(path)
    from django.db import connection

    connection.ensure_connection()
    if connection.connection.row_factory is not None:
        raise RuntimeError("Migration tests require Django's default SQLite row factory.")
    return path


def _migrate(targets):
    from django.db import connection
    from django.db.migrations.executor import MigrationExecutor

    MigrationExecutor(connection).migrate(targets)


def _assert_constraint_exists():
    from django.db import connection
    from apps.devices.models import Device

    with connection.cursor() as cursor:
        constraints = connection.introspection.get_constraints(cursor, Device._meta.db_table)
    constraint = constraints.get("one_fingerprint_device_per_branch")
    if not constraint or not constraint.get("unique") or constraint.get("columns") != ["branch_id"]:
        raise AssertionError("The one-device-per-branch database constraint is missing.")


def _fresh_database():
    from django.db.migrations.executor import MigrationExecutor
    from django.db import connection

    executor = MigrationExecutor(connection)
    _migrate(executor.loader.graph.leaf_nodes())
    _assert_constraint_exists()


def _prepare_device_migration_state():
    from django.db import connection
    from django.db.migrations.executor import MigrationExecutor

    _migrate([("devices", "0001_initial")])
    executor = MigrationExecutor(connection)
    return executor.loader.project_state([("devices", "0001_initial")]).apps


def _create_historical_device(apps, device_id, branch):
    Device = apps.get_model("devices", "Device")
    return Device.objects.create(
        device_id=device_id,
        branch_id=branch.pk,
        token_hash="isolated-migration-test-hash",
    )


def _valid_existing_data():
    from django.db import connection
    from django.db.migrations.executor import MigrationExecutor

    apps = _prepare_device_migration_state()
    Branch = apps.get_model("branches", "Branch")
    branch = Branch.objects.create(name="Isolated branch", code="ISOLATED-VALID")
    original = _create_historical_device(apps, "ISOLATED-VALID-DEVICE", branch)
    original_branch_id = original.branch_id

    _migrate([("devices", "0002_one_fingerprint_device_per_branch")])
    executor = MigrationExecutor(connection)
    Device = executor.loader.project_state(
        [("devices", "0002_one_fingerprint_device_per_branch")]
    ).apps.get_model("devices", "Device")
    migrated = Device.objects.get(pk=original.pk)
    if migrated.device_id != "ISOLATED-VALID-DEVICE" or migrated.branch_id != original_branch_id:
        raise AssertionError("The valid existing device record changed during migration.")
    _assert_constraint_exists()


def _duplicate_branch_data():
    from django.db import connection
    from django.db.migrations.executor import MigrationExecutor

    apps = _prepare_device_migration_state()
    Branch = apps.get_model("branches", "Branch")
    branch = Branch.objects.create(name="Isolated duplicate branch", code="ISOLATED-DUPLICATE")
    first = _create_historical_device(apps, "ISOLATED-DUPLICATE-ONE", branch)
    second = _create_historical_device(apps, "ISOLATED-DUPLICATE-TWO", branch)
    original = {
        first.pk: (first.device_id, first.branch_id),
        second.pk: (second.device_id, second.branch_id),
    }

    try:
        _migrate([("devices", "0002_one_fingerprint_device_per_branch")])
    except RuntimeError as error:
        if "Cannot enforce one fingerprint device per branch" not in str(error):
            raise
    else:
        raise AssertionError("The migration unexpectedly accepted duplicate branch devices.")

    executor = MigrationExecutor(connection)
    Device = executor.loader.project_state(
        [("devices", "0001_initial")]
    ).apps.get_model("devices", "Device")
    actual = {
        row.pk: (row.device_id, row.branch_id)
        for row in Device.objects.filter(pk__in=original)
    }
    if actual != original:
        raise AssertionError("The failed migration deleted or reassigned a device.")
    _assert_constraint_absent()


def _assert_constraint_absent():
    from django.db import connection
    from apps.devices.models import Device

    with connection.cursor() as cursor:
        constraints = connection.introspection.get_constraints(cursor, Device._meta.db_table)
    if "one_fingerprint_device_per_branch" in constraints:
        raise AssertionError("A failed migration partially applied the unique constraint.")


def _provisioning():
    from django.contrib.auth import get_user_model
    from rest_framework.test import APIClient

    from apps.branches.models import Branch
    from apps.devices.models import Device
    from apps.organizations.models import Organization

    _fresh_database()
    organization = Organization.objects.create(name="Isolated company", code="ISOLATED-ORG")
    branch = Branch.objects.create(
        organization=organization,
        name="Provisioning branch",
        code="ISOLATED-PROVISION",
    )
    admin = get_user_model().objects.create_user(
        "9000000000",
        role="SUPERADMIN",
        is_staff=True,
        is_superuser=True,
    )
    client = APIClient()
    client.force_authenticate(admin)

    created = client.post(
        "/api/v1/devices/",
        {"device_id": "ISOLATED-PROVISION-ONE", "branch_id": branch.pk},
        format="json",
    )
    if created.status_code != 201 or not Device.objects.filter(
        device_id="ISOLATED-PROVISION-ONE",
        branch=branch,
    ).exists():
        raise AssertionError("Normal device provisioning failed in the isolated database.")

    duplicate = client.post(
        "/api/v1/devices/",
        {"device_id": "ISOLATED-PROVISION-TWO", "branch_id": branch.pk},
        format="json",
    )
    if duplicate.status_code != 400 or Device.objects.filter(
        device_id="ISOLATED-PROVISION-TWO",
    ).exists():
        raise AssertionError("Provisioning did not reject a second device for the branch.")

    race_branch = Branch.objects.create(
        organization=organization,
        name="Constraint race branch",
        code="ISOLATED-RACE",
    )
    existing = Device(
        device_id="ISOLATED-RACE-ONE",
        branch=race_branch,
        token_hash="isolated-test-hash",
    )
    existing.set_token("isolated-test-token")
    existing.save()
    manager = Device.objects
    original_filter = manager.filter
    stale_preflight = [True]

    def filter_with_stale_branch_read(*args, **kwargs):
        queryset = original_filter(*args, **kwargs)
        if kwargs == {"branch": race_branch} and stale_preflight[0]:
            stale_preflight[0] = False
            return queryset.none()
        return queryset

    with patch.object(manager, "filter", side_effect=filter_with_stale_branch_read):
        raced = client.post(
            "/api/v1/devices/",
            {"device_id": "ISOLATED-RACE-TWO", "branch_id": race_branch.pk},
            format="json",
        )
    if stale_preflight[0] or raced.status_code != 400:
        raise AssertionError("The unique-constraint race was not handled as a validation error.")
    if Device.objects.filter(branch=race_branch).count() != 1:
        raise AssertionError("The provisioning race created a duplicate device.")


def _device_last_seen_migration():
    from django.contrib.auth import get_user_model
    from django.db import connection
    from django.db.migrations.executor import MigrationExecutor
    from django.utils import timezone

    target_0002 = ("devices", "0002_one_fingerprint_device_per_branch")
    target_0003 = ("devices", "0003_device_last_seen")
    executor = MigrationExecutor(connection)
    targets = [
        node for node in executor.loader.graph.leaf_nodes()
        if node != target_0003
    ]
    _migrate(targets)

    apps = MigrationExecutor(connection).loader.project_state([target_0002]).apps
    HistoricalDevice = apps.get_model("devices", "Device")

    from apps.attendance.models import Attendance
    from apps.branches.models import Branch
    from apps.departments.models import Department
    from apps.employees.models import Employee
    from apps.fingerprints.models import EmployeeFingerprint, FingerprintEnrollment
    from apps.organizations.models import Organization

    organization = Organization.objects.create(
        name="Migration test organization",
        code="MIGRATION-LAST-SEEN-ORG",
    )
    branch = Branch.objects.create(
        organization=organization,
        name="Migration test branch",
        code="MIGRATION-LAST-SEEN-BRANCH",
    )
    device = HistoricalDevice.objects.create(
        device_id="MIGRATION-LAST-SEEN-DEVICE",
        branch_id=branch.pk,
        token_hash="isolated-migration-test-hash",
    )
    user_model = get_user_model()
    administrator = user_model.objects.create_user(
        "9800000101",
        role="SUPERADMIN",
        is_superuser=True,
    )
    employee_user = user_model.objects.create_user(
        "9800000102",
        role="EMPLOYEE",
    )
    department = Department.objects.create(name="Migration test department", branch=branch)
    employee = Employee.objects.create(
        employee_code="MIGRATION-LAST-SEEN-EMPLOYEE",
        user=employee_user,
        branch=branch,
        department=department,
    )
    now = timezone.now()
    EmployeeFingerprint.objects.create(
        employee=employee,
        device_id=device.pk,
        fingerprint_slot=1,
        finger="right_index",
    )
    FingerprintEnrollment.objects.create(
        employee=employee,
        device_id=device.pk,
        finger="right_index",
        status="SUCCESS",
        actual_slot=1,
        created_by=administrator,
        expires_at=now + timedelta(hours=1),
    )
    Attendance.objects.create(
        employee=employee,
        device_id=device.pk,
        branch=branch,
        attendance_date=now.date(),
        check_in_at=now,
        source="BIOMETRIC",
    )

    def preserved_rows():
        raw = connection.connection
        snapshots = {}
        specifications = (
            ("devices_device", "id", device.pk),
            ("branches_branch", "id", branch.pk),
            ("fingerprints_employeefingerprint", "device_id", device.pk),
            ("fingerprints_fingerprintenrollment", "device_id", device.pk),
            ("attendance_attendance", "device_id", device.pk),
        )
        for table, filter_column, value in specifications:
            columns = [
                row[1]
                for row in raw.execute(f'PRAGMA table_info("{table}")').fetchall()
                if not (table == "devices_device" and row[1] == "last_seen")
            ]
            selected = ", ".join(f'"{column}"' for column in columns)
            rows = raw.execute(
                f'SELECT {selected} FROM "{table}" WHERE "{filter_column}" = ? ORDER BY 1',
                (value,),
            ).fetchall()
            snapshots[table] = (columns, rows)
        return snapshots

    before = preserved_rows()
    if len(before["fingerprints_employeefingerprint"][1]) != 1:
        raise AssertionError("The disposable fingerprint mapping fixture is missing.")
    if len(before["fingerprints_fingerprintenrollment"][1]) != 1:
        raise AssertionError("The disposable enrollment fixture is missing.")
    if len(before["attendance_attendance"][1]) != 1:
        raise AssertionError("The disposable attendance fixture is missing.")

    def has_last_seen():
        return any(
            row[1] == "last_seen" and row[3] == 0
            for row in connection.connection.execute(
                'PRAGMA table_info("devices_device")'
            ).fetchall()
        )

    def migration_recorded():
        return connection.connection.execute(
            "SELECT 1 FROM django_migrations WHERE app = ? AND name = ?",
            target_0003,
        ).fetchone() is not None

    def assert_preserved():
        if preserved_rows() != before:
            raise AssertionError("The device migration changed protected disposable records.")

    connection.connection.row_factory = sqlite3.Row
    try:
        try:
            _migrate([target_0003])
        except RuntimeError as error:
            if "default SQLite row factory" not in str(error):
                raise
        else:
            raise AssertionError("The write guard accepted a custom SQLite row factory.")
    finally:
        connection.connection.row_factory = None
    if has_last_seen() or migration_recorded():
        raise AssertionError("The row-factory guard allowed a partial migration.")
    assert_preserved()

    def fail_after_add_field(schema_editor, model, field, *args, **kwargs):
        result = original_add_field(schema_editor, model, field, *args, **kwargs)
        if model._meta.model_name == "device" and field.name == "last_seen":
            raise RuntimeError("Injected disposable migration failure.")
        return result

    original_add_field = connection.SchemaEditorClass.add_field
    try:
        with patch.object(connection.SchemaEditorClass, "add_field", new=fail_after_add_field):
            _migrate([target_0003])
    except RuntimeError as error:
        if str(error) != "Injected disposable migration failure.":
            raise
    else:
        raise AssertionError("The injected migration failure did not occur.")

    if has_last_seen() or migration_recorded():
        raise AssertionError("The failed migration left partial schema or migration state.")
    assert_preserved()

    connection.force_debug_cursor = True
    _migrate([target_0003])
    if not has_last_seen() or not migration_recorded():
        raise AssertionError("The fresh disposable migration did not add nullable last_seen.")
    assert_preserved()

    _migrate([target_0002])
    if has_last_seen() or migration_recorded():
        raise AssertionError("The reverse migration did not remove last_seen and its record.")
    assert_preserved()


SCENARIOS = {
    "fresh": _fresh_database,
    "valid-existing": _valid_existing_data,
    "duplicate-branch": _duplicate_branch_data,
    "provisioning": _provisioning,
    "device-last-seen": _device_last_seen_migration,
}


if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in SCENARIOS:
        raise SystemExit("Expected one supported isolated scenario name.")
    _initialize()
    from django.db import connection

    with connection.execute_wrapper(_verify_before_write):
        SCENARIOS[sys.argv[1]]()
    print(f"PASS: {sys.argv[1]}")
