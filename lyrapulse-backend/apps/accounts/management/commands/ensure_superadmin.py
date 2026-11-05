import os
import re

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from rest_framework import serializers

from apps.accounts.serializers import normalize_phone_number
from apps.accounts.services.role_permissions import sync_existing_role_groups

User = get_user_model()


class Command(BaseCommand):
    help = (
        "Ensure a SUPERADMIN account exists for the given mobile without replacing existing user data. "
        "Pass --phone or set LYRA_SUPERADMIN_PHONE. Nothing is hardcoded."
    )

    def add_arguments(self, parser):
        parser.add_argument("--phone", help="SUPERADMIN mobile number (10 digits, optional +91). Falls back to $LYRA_SUPERADMIN_PHONE.")

    @transaction.atomic
    def handle(self, *args, **options):
        raw_phone = options.get("phone") or os.environ.get("LYRA_SUPERADMIN_PHONE")
        if not raw_phone:
            raise CommandError("Provide the mobile with --phone <number> or the LYRA_SUPERADMIN_PHONE environment variable.")
        try:
            mobile = normalize_phone_number(raw_phone)
        except serializers.ValidationError:
            raise CommandError("Enter a valid 10-digit mobile number.")

        matches = []
        for user in User.objects.select_for_update().all():
            digits = re.sub(r"\D", "", user.phone_number or "")
            if len(digits) == 12 and digits.startswith("91"):
                digits = digits[2:]
            if digits == mobile:
                matches.append(user)
        if len(matches) > 1:
            raise CommandError("Multiple existing users normalize to this mobile; resolve the duplicate records first.")
        if matches:
            user = matches[0]
            user.role = User.Role.SUPERADMIN
            user.is_active = True
            user.is_staff = True
            user.is_superuser = True
            user.save(update_fields=["role", "is_active", "is_staff", "is_superuser", "updated_at"])
            sync_existing_role_groups()
            self.stdout.write(self.style.SUCCESS("SUPERADMIN account ensured for the given mobile."))
            return
        User.objects.create_user(
            phone_number=mobile, password=None, role=User.Role.SUPERADMIN,
            is_active=True, is_staff=True, is_superuser=True,
        )
        sync_existing_role_groups()
        self.stdout.write(self.style.SUCCESS("SUPERADMIN account created for the given mobile."))
