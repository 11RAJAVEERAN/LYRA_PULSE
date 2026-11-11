import os
import tempfile
from pathlib import Path

from .settings import *


def _required_path(name):
    value = os.environ.get(name)
    if not value:
        raise RuntimeError(f"{name} must be set for isolated migration tests.")
    path = Path(value)
    if not path.is_absolute():
        raise RuntimeError(f"{name} must be an absolute path.")
    if path.is_symlink():
        raise RuntimeError(f"{name} must not be a symbolic link.")
    return path.resolve(strict=False)


_expected_database = _required_path("LYRA_MIGRATION_TEST_DB")
_project_database = _required_path("LYRA_PROJECT_DATABASE_PATH")
_marker_path = _required_path("LYRA_MIGRATION_TEST_MARKER")
_run_id = os.environ.get("LYRA_MIGRATION_TEST_RUN_ID")

if not _run_id:
    raise RuntimeError("LYRA_MIGRATION_TEST_RUN_ID must be set for isolated migration tests.")
if _expected_database == _project_database:
    raise RuntimeError("The configured project database cannot be used for migration tests.")
if _expected_database.is_relative_to(BASE_DIR.resolve()):
    raise RuntimeError("The migration test database must be outside the project workspace.")
if not _expected_database.is_relative_to(Path(tempfile.gettempdir()).resolve()):
    raise RuntimeError("The migration test database must be inside the system temporary directory.")
if _marker_path != _expected_database.parent / ".migration-test-run":
    raise RuntimeError("The migration test run marker does not match the database directory.")
if _expected_database.is_symlink() or not _expected_database.is_file():
    raise RuntimeError("The migration test database must be a regular file created for this run.")
if _expected_database.stat().st_size != 0:
    raise RuntimeError("The migration test database must be empty before the test process starts.")
if _marker_path.is_symlink() or not _marker_path.is_file():
    raise RuntimeError("The migration test run marker is missing or invalid.")
if _marker_path.read_text(encoding="ascii") != _run_id:
    raise RuntimeError("The migration test run marker does not match this test process.")

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": str(_expected_database),
    }
}
ALLOWED_HOSTS = [*ALLOWED_HOSTS, "testserver"]
