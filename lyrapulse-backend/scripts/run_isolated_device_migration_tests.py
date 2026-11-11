import os
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path


BACKEND_ROOT = Path(__file__).resolve().parents[1]
PROJECT_DATABASE = BACKEND_ROOT / "db.sqlite3"
SETTINGS_MODULE = "config.migration_test_settings"
WORKER = BACKEND_ROOT / "scripts" / "device_migration_test_worker.py"
SCENARIOS = (
    "fresh",
    "valid-existing",
    "duplicate-branch",
    "provisioning",
    "device-last-seen",
)


def _database_metadata(path):
    try:
        stat = path.stat()
    except FileNotFoundError:
        return None
    return stat.st_dev, stat.st_ino, stat.st_size, stat.st_mtime_ns


def _probe_settings_import(environment):
    return subprocess.run(
        [sys.executable, "-c", "import config.migration_test_settings"],
        cwd=BACKEND_ROOT,
        env=environment,
        capture_output=True,
        text=True,
        check=False,
    )


def _assert_guard_probes(temp_root):
    base_environment = os.environ.copy()
    base_environment.pop("DB_NAME", None)
    base_environment["DJANGO_SETTINGS_MODULE"] = SETTINGS_MODULE
    base_environment["LYRA_PROJECT_DATABASE_PATH"] = str(PROJECT_DATABASE.resolve(strict=False))

    missing = base_environment.copy()
    for key in (
        "LYRA_MIGRATION_TEST_DB",
        "LYRA_MIGRATION_TEST_MARKER",
        "LYRA_MIGRATION_TEST_RUN_ID",
    ):
        missing.pop(key, None)
    if _probe_settings_import(missing).returncode == 0:
        raise RuntimeError("Test settings accepted missing temporary database configuration.")

    wrong_path = base_environment.copy()
    wrong_path.update({
        "LYRA_MIGRATION_TEST_DB": str(PROJECT_DATABASE.resolve(strict=False)),
        "LYRA_MIGRATION_TEST_MARKER": str(PROJECT_DATABASE.parent / ".migration-test-run"),
        "LYRA_MIGRATION_TEST_RUN_ID": "guard-probe",
    })
    if _probe_settings_import(wrong_path).returncode == 0:
        raise RuntimeError("Test settings accepted the configured project database path.")

    workspace_path = BACKEND_ROOT / "must-not-be-created.sqlite3"
    workspace_probe = base_environment.copy()
    workspace_probe.update({
        "LYRA_MIGRATION_TEST_DB": str(workspace_path),
        "LYRA_MIGRATION_TEST_MARKER": str(workspace_path.parent / ".migration-test-run"),
        "LYRA_MIGRATION_TEST_RUN_ID": "guard-probe",
    })
    if _probe_settings_import(workspace_probe).returncode == 0:
        raise RuntimeError("Test settings accepted a database path inside the workspace.")
    if workspace_path.exists():
        raise RuntimeError("A rejected workspace database path was unexpectedly created.")

    if not temp_root.is_relative_to(Path(tempfile.gettempdir()).resolve()):
        raise RuntimeError("The scenario directory is not under the system temporary directory.")
    print("PASS: missing, project, workspace, and fallback database guards")


def _create_scenario_environment(root, scenario):
    scenario_directory = root / scenario
    scenario_directory.mkdir(mode=0o700)
    marker = scenario_directory / ".migration-test-run"
    run_id = str(uuid.uuid4())
    with marker.open("x", encoding="ascii") as marker_file:
        marker_file.write(run_id)
    marker.chmod(0o600)

    database = scenario_directory / "scenario.sqlite3"
    descriptor = os.open(database, os.O_CREAT | os.O_EXCL | os.O_RDWR, 0o600)
    os.close(descriptor)

    environment = os.environ.copy()
    for key in ("DB_NAME", "DB_USER", "DB_PASSWORD", "DB_HOST", "DB_PORT"):
        environment.pop(key, None)
    environment.update({
        "DJANGO_SETTINGS_MODULE": SETTINGS_MODULE,
        "LYRA_MIGRATION_TEST_DB": str(database.resolve(strict=True)),
        "LYRA_MIGRATION_TEST_MARKER": str(marker.resolve(strict=True)),
        "LYRA_MIGRATION_TEST_RUN_ID": run_id,
        "LYRA_PROJECT_DATABASE_PATH": str(PROJECT_DATABASE.resolve(strict=False)),
    })
    return database, environment


def main():
    if PROJECT_DATABASE.exists():
        original_metadata = _database_metadata(PROJECT_DATABASE)
    else:
        original_metadata = None

    with tempfile.TemporaryDirectory(prefix="lyra-device-migration-tests-") as directory:
        root = Path(directory).resolve(strict=True)
        _assert_guard_probes(root)

        for scenario in SCENARIOS:
            database, environment = _create_scenario_environment(root, scenario)
            result = subprocess.run(
                [sys.executable, str(WORKER), scenario],
                cwd=BACKEND_ROOT,
                env=environment,
                capture_output=True,
                text=True,
                check=False,
            )
            if result.returncode:
                print(f"FAIL: {scenario}; isolated worker exited unsuccessfully.", file=sys.stderr)
                if result.stderr:
                    print(result.stderr, file=sys.stderr)
                raise SystemExit(result.returncode)
            if database.stat().st_size == 0:
                raise RuntimeError(f"The {scenario} scenario did not run against its database.")
            if result.stdout.strip() != f"PASS: {scenario}":
                raise RuntimeError(f"The {scenario} worker returned unexpected output.")
            print(result.stdout.strip())

    if _database_metadata(PROJECT_DATABASE) != original_metadata:
        raise RuntimeError("The configured project database metadata changed during the test run.")
    print("PASS: configured project database metadata unchanged")


if __name__ == "__main__":
    main()
