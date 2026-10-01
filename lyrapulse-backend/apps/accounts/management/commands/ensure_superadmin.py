import re

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from apps.accounts.services.role_permissions import sync_existing_role_groups

User = get_user_model()
MOBILE = "9150181669"


class Command(BaseCommand):
    help = "Ensure the configured SUPERADMIN account exists without replacing existing user data."

    @transaction.atomic
    def handle(self, *args, **options):
        matches = []
        for user in User.objects.select_for_update().all():
            digits = re.sub(r"\D", "", user.phone_number or "")
            if len(digits) == 12 and digits.startswith("91"):
                digits = digits[2:]
            if digits == MOBILE:
                matches.append(user)
        if len(matches) > 1:
            raise CommandError("Multiple existing users normalize to the configured mobile; resolve the duplicate records first.")
        if matches:
            user = matches[0]
            user.role = User.Role.SUPERADMIN
            user.is_active = True
            user.is_staff = True
            user.is_superuser = True
            user.save(update_fields=["role", "is_active", "is_staff", "is_superuser", "updated_at"])
            sync_existing_role_groups()
            self.stdout.write(self.style.SUCCESS("SUPERADMIN account ensured for the configured mobile."))
            return
        User.objects.create_user(
            phone_number=MOBILE, password=None, role=User.Role.SUPERADMIN,
            is_active=True, is_staff=True, is_superuser=True,
        )
        sync_existing_role_groups()
        self.stdout.write(self.style.SUCCESS("SUPERADMIN account created for the configured mobile."))