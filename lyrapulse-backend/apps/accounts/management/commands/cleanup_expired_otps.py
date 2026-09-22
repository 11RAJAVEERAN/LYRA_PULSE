from django.core.management.base import BaseCommand
from django.utils import timezone

from apps.accounts.models import OTPVerification


class Command(BaseCommand):
    help = "Delete expired OTP verification records."

    def handle(self, *args, **options):
        deleted, _ = OTPVerification.objects.filter(expires_at__lt=timezone.now()).delete()
        self.stdout.write(self.style.SUCCESS(f"Deleted {deleted} expired OTP records."))