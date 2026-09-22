import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.db import transaction
from django.utils import timezone

from apps.accounts.models import OTPVerification

from .sms_service import get_sms_service


def generate_otp():
    return f"{secrets.randbelow(1_000_000):06d}"


def invalidate_previous_otps(phone_number, purpose=OTPVerification.Purpose.LOGIN):
    OTPVerification.objects.filter(phone_number=phone_number, purpose=purpose, is_verified=False).update(is_verified=True)


def can_resend_otp(phone_number, purpose=OTPVerification.Purpose.LOGIN):
    latest = OTPVerification.objects.filter(phone_number=phone_number, purpose=purpose).order_by("-created_at").first()
    if not latest:
        return True
    return timezone.now() >= latest.created_at + timedelta(seconds=settings.OTP_RESEND_COOLDOWN_SECONDS)


@transaction.atomic
def create_otp(phone_number, purpose=OTPVerification.Purpose.LOGIN):
    if not can_resend_otp(phone_number, purpose):
        raise ValueError("Please wait before requesting another OTP")
    invalidate_previous_otps(phone_number, purpose)
    otp = generate_otp()
    record = OTPVerification.objects.create(
        phone_number=phone_number,
        otp_hash=make_password(otp),
        purpose=purpose,
        max_attempts=settings.OTP_MAX_ATTEMPTS,
        expires_at=timezone.now() + timedelta(seconds=settings.OTP_EXPIRY_SECONDS),
    )
    # Keep the plaintext OTP transiently available to the development response only.
    record._plain_otp = otp
    get_sms_service().send_otp(phone_number, otp)
    return record


def verify_otp(phone_number, otp, purpose=OTPVerification.Purpose.LOGIN):
    record = OTPVerification.objects.filter(
        phone_number=phone_number, purpose=purpose, is_verified=False,
    ).order_by("-created_at").first()
    if not record:
        raise ValueError("Invalid or expired OTP")
    if record.expires_at <= timezone.now():
        raise ValueError("Invalid or expired OTP")
    if record.attempts >= record.max_attempts:
        raise ValueError("Maximum OTP attempts exceeded")
    record.attempts += 1
    if not check_password(otp, record.otp_hash):
        record.save(update_fields=["attempts"])
        raise ValueError("Invalid OTP")
    record.is_verified = True
    record.verified_at = timezone.now()
    record.save(update_fields=["attempts", "is_verified", "verified_at"])
    return record