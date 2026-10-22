import re
import secrets

from django.core.management.base import BaseCommand, CommandError
from django.db import IntegrityError

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
        try:
            branch = Branch.objects.get(code=options["branch_code"], is_active=True)
        except Branch.DoesNotExist as exc:
            raise CommandError("An active branch with that code does not exist.") from exc

        token = secrets.token_urlsafe(32)
        try:
            device = Device(device_id=options["device_id"], branch=branch, name=options["name"])
            device.set_token(token)
            device.save()
        except IntegrityError as exc:
            raise CommandError("A device with that ID already exists.") from exc

        self.stdout.write(self.style.SUCCESS("Device provisioned. Configure this credential on the device now:"))
        self.stdout.write("DEVICE_ID=%s" % device.device_id)
        self.stdout.write("DEVICE_TOKEN=%s" % token)
        self.stdout.write(self.style.WARNING("The raw token is not stored and cannot be displayed again."))
