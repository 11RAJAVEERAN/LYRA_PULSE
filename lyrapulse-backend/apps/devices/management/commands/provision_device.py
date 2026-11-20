import re
import secrets

from django.core.management.base import BaseCommand, CommandError
from django.db import IntegrityError, transaction

from apps.branches.models import Branch
from apps.devices.models import Device


def _violated_unique_columns(exc):
    """Return the columns named by the violated unique constraint, when known."""
    cause = exc.__cause__
    constraint_name = getattr(getattr(cause, "diag", None), "constraint_name", None)
    if constraint_name == "one_fingerprint_device_per_branch":
        return ("branch_id",)

    # PostgreSQL names a unique field constraint from its table and column.
    device_id_constraint = f"{Device._meta.db_table}_{Device._meta.get_field('device_id').column}_key"
    if constraint_name == device_id_constraint:
        return ("device_id",)

    # SQLite does not expose constraint names, but its error identifies the
    # exact table and columns. Keep this fallback precise rather than treating
    # an arbitrary integrity failure as a duplicate device ID.
    prefix = "UNIQUE constraint failed: "
    message = str(exc)
    if message.startswith(prefix):
        qualified_columns = tuple(column.strip() for column in message[len(prefix):].split(","))
        table = Device._meta.db_table
        if qualified_columns == (f"{table}.branch_id",):
            return ("branch_id",)
        if qualified_columns == (f"{table}.device_id",):
            return ("device_id",)
    return None


class Command(BaseCommand):
    help = "Create a device and print its credential once."

    def add_arguments(self, parser):
        parser.add_argument("--device-id", required=True)
        parser.add_argument("--branch-code", required=True)
        parser.add_argument("--name", default="")

    def handle(self, *args, **options):
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,99}", options["device_id"]):
            raise CommandError("Device IDs may contain only letters, digits, dots, underscores, and hyphens.")
        try:
            branch = Branch.objects.get(code=options["branch_code"], is_active=True)
        except Branch.DoesNotExist as exc:
            raise CommandError("An active branch with that code does not exist.") from exc

        token = secrets.token_urlsafe(32)
        try:
            device = Device(device_id=options["device_id"], branch=branch, name=options["name"])
            device.set_token(token)
            with transaction.atomic():
                device.save()
        except IntegrityError as exc:
            columns = _violated_unique_columns(exc)
            if columns == ("branch_id",):
                raise CommandError(
                    f"Branch {branch.code} already has a registered fingerprint device."
                ) from exc
            if columns == ("device_id",):
                raise CommandError("A device with that ID already exists.") from exc
            raise CommandError("The device could not be provisioned because of a database constraint violation.") from exc

        self.stdout.write(self.style.SUCCESS("Device provisioned. Configure this credential on the device now:"))
        self.stdout.write("DEVICE_ID=%s" % device.device_id)
        self.stdout.write("DEVICE_TOKEN=%s" % token)
        self.stdout.write(self.style.WARNING("The raw token is not stored and cannot be displayed again."))
