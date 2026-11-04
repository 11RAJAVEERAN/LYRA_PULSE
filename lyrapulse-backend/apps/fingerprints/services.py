from datetime import timedelta

from django.conf import settings

from .models import FingerprintEnrollment


def cancel_queued_finger(enrollment, now, reason):
    if enrollment.pair_id is None or enrollment.total_fingers < 2:
        return
    FingerprintEnrollment.objects.filter(
        pair_id=enrollment.pair_id,
        status=FingerprintEnrollment.Status.QUEUED,
    ).update(
        status=FingerprintEnrollment.Status.CANCELLED,
        completed_at=now,
        failure_reason=reason,
        updated_at=now,
    )


def activate_next_finger(enrollment, now):
    if enrollment.pair_id is None or enrollment.finger_index >= enrollment.total_fingers:
        return None
    next_enrollment = (
        FingerprintEnrollment.objects.select_for_update()
        .filter(
            pair_id=enrollment.pair_id,
            finger_index=enrollment.finger_index + 1,
            status=FingerprintEnrollment.Status.QUEUED,
        )
        .first()
    )
    if next_enrollment is None:
        return None
    next_enrollment.status = FingerprintEnrollment.Status.PENDING
    ttl_seconds = getattr(settings, "FINGERPRINT_ENROLLMENT_TTL_SECONDS", 300)
    next_enrollment.expires_at = now + timedelta(seconds=ttl_seconds)
    next_enrollment.save(update_fields=("status", "expires_at", "updated_at"))
    return next_enrollment
