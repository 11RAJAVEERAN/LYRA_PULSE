import uuid

from django.conf import settings
from django.db import models
from django.db.models import Q

from apps.devices.models import Device
from apps.employees.models import Employee

ACTIVE_ENROLLMENT_STATUSES = (
    "PENDING",
    "WAITING_FOR_FINGER",
    "WAITING_FOR_SECOND_SCAN",
    "PROCESSING",
)


class FingerprintEnrollment(models.Model):
    ACTIVE_STATUSES = ACTIVE_ENROLLMENT_STATUSES

    class Finger(models.TextChoices):
        LEFT_THUMB = "left_thumb", "Left thumb"
        LEFT_INDEX = "left_index", "Left index"
        LEFT_MIDDLE = "left_middle", "Left middle"
        LEFT_RING = "left_ring", "Left ring"
        LEFT_LITTLE = "left_little", "Left little"
        RIGHT_THUMB = "right_thumb", "Right thumb"
        RIGHT_INDEX = "right_index", "Right index"
        RIGHT_MIDDLE = "right_middle", "Right middle"
        RIGHT_RING = "right_ring", "Right ring"
        RIGHT_LITTLE = "right_little", "Right little"

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        WAITING_FOR_FINGER = "WAITING_FOR_FINGER", "Waiting for finger"
        WAITING_FOR_SECOND_SCAN = "WAITING_FOR_SECOND_SCAN", "Waiting for second scan"
        PROCESSING = "PROCESSING", "Processing"
        SUCCESS = "SUCCESS", "Success"
        FAILED = "FAILED", "Failed"
        EXPIRED = "EXPIRED", "Expired"
        CANCELLED = "CANCELLED", "Cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    employee = models.ForeignKey(Employee, on_delete=models.PROTECT, related_name="fingerprint_enrollments")
    device = models.ForeignKey(Device, on_delete=models.PROTECT, related_name="fingerprint_enrollments")
    finger = models.CharField(max_length=20, choices=Finger.choices)
    status = models.CharField(max_length=30, choices=Status.choices, default=Status.PENDING)
    actual_slot = models.PositiveIntegerField(null=True, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="created_fingerprint_enrollments",
    )
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    expires_at = models.DateTimeField()
    failure_reason = models.CharField(max_length=64, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=("device",),
                condition=Q(status__in=ACTIVE_ENROLLMENT_STATUSES),
                name="one_active_enrollment_per_device",
            ),
        ]

    def __str__(self):
        return "%s (%s)" % (self.employee.employee_code, self.status)


class EmployeeFingerprint(models.Model):
    employee = models.ForeignKey(Employee, on_delete=models.PROTECT, related_name="fingerprints")
    device = models.ForeignKey(Device, on_delete=models.PROTECT, related_name="fingerprints")
    fingerprint_slot = models.PositiveIntegerField()
    finger = models.CharField(max_length=20, choices=FingerprintEnrollment.Finger.choices)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["device", "fingerprint_slot"]
        constraints = [
            models.UniqueConstraint(
                fields=("device", "fingerprint_slot"),
                condition=Q(is_active=True),
                name="unique_active_device_fingerprint_slot",
            ),
        ]

    def __str__(self):
        return "%s:%s" % (self.device.device_id, self.fingerprint_slot)
