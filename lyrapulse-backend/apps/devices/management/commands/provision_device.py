import re
import secrets

from django.core.management.base import BaseCommand, CommandError
from django.db import IntegrityError, transaction

from apps.branches.models import Branch
from apps.devices.models import Device


class Command(BaseCommand):
    help = "Create a device and print its credential once."

    def add_arguments(self, parser):
        parser.add_argument("--device-id", required=True)
        parser.add_argument("--branch-code", required=True)
        parser.add_argument("--name", default="")

    def handle(self, *args, **options):
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,99}", options["device_id"]):
            raise CommandError("Device IDs may contain only letters, digits, dots, underscores, and hyphens.")
        branch = None
        try:
            with transaction.atomic():
                branch = Branch.objects.select_for_update().get(
                    code=options["branch_code"],
                    is_active=True,
                )
                if Device.objects.filter(device_id=options["device_id"]).exists():
                    raise CommandError("A device with that ID already exists.")
                if Device.objects.filter(branch=branch).exists():
                    raise CommandError(
                        "This branch already has a registered fingerprint device."
                    )

                token = secrets.token_urlsafe(32)
                device = Device(
                    device_id=options["device_id"],
                    branch=branch,
                    name=options["name"],
                )
                device.set_token(token)
                device.save()
        except Branch.DoesNotExist as exc:
            raise CommandError("An active branch with that code does not exist.") from exc
        except IntegrityError as exc:
            if Device.objects.filter(device_id=options["device_id"]).exists():
                raise CommandError("A device with that ID already exists.") from exc
            if branch is not None and Device.objects.filter(branch_id=branch.pk).exists():
                raise CommandError(
                    "This branch already has a registered fingerprint device."
                ) from exc
            raise CommandError("Device provisioning failed due to a database constraint.") from exc

        self.stdout.write(self.style.SUCCESS("Device provisioned. Configure this credential on the device now:"))
        self.stdout.write("DEVICE_ID=%s" % device.device_id)
        self.stdout.write("DEVICE_TOKEN=%s" % token)
        self.stdout.write(self.style.WARNING("The raw token is not stored and cannot be displayed again."))
