import uuid

from django.db import models
from django.db.models import Q
from django.utils import timezone

from apps.branches.models import Branch
from apps.employees.models import Employee


def _photo_path(kind, instance, filename):
    # Random name: neither the client filename nor any employee identifier is ever used on disk.
    extension = "png" if str(filename).lower().endswith(".png") else "jpg"
    day = instance.attendance_date or timezone.localdate()
    return f"attendance/{kind}/{day:%Y/%m/%d}/{uuid.uuid4()}.{extension}"


def check_in_photo_path(instance, filename):
    return _photo_path("checkin", instance, filename)


def check_out_photo_path(instance, filename):
    return _photo_path("checkout", instance, filename)


class Attendance(models.Model):
    """One employee's attendance for one day. Created by check-in, completed (same row) by check-out."""

    class State(models.TextChoices):
        NOT_CHECKED_IN = "NOT_CHECKED_IN", "Not checked in"
        CHECKED_IN = "CHECKED_IN", "Checked in"
        CHECKED_OUT = "CHECKED_OUT", "Checked out"

    employee = models.ForeignKey(Employee, on_delete=models.PROTECT, related_name="attendance_records")
    device = models.ForeignKey("devices.Device", on_delete=models.PROTECT, related_name="attendance_records", null=True, blank=True)
    created_by = models.ForeignKey("accounts.User", on_delete=models.PROTECT, related_name="manual_attendance_records", null=True, blank=True)
    source = models.CharField(max_length=20, choices=[("MOBILE_GPS", "Mobile GPS"), ("BIOMETRIC", "Biometric"), ("MANUAL", "Admin manual")], default="MOBILE_GPS")
    branch = models.ForeignKey(
        Branch, on_delete=models.PROTECT, related_name="attendance_records",
        help_text="Branch the employee was verified against at check-in (decided by the server).",
    )
    attendance_date = models.DateField(help_text="Calendar date in the application time zone.")

    # --- Check-in (a row only exists once the employee has checked in) ---
    check_in_at = models.DateTimeField()
    check_in_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    check_in_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    check_in_accuracy = models.FloatField(null=True, blank=True, help_text="GPS accuracy reported by the device, in meters.")
    check_in_distance_meters = models.FloatField(null=True, blank=True, help_text="Distance from the branch attendance location, in meters.")
    check_in_location_verified = models.BooleanField(null=True, blank=True)
    check_in_photo = models.ImageField(upload_to=check_in_photo_path, blank=True)

    # --- Check-out (empty until the employee checks out) ---
    check_out_at = models.DateTimeField(null=True, blank=True)
    check_out_latitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    check_out_longitude = models.DecimalField(max_digits=10, decimal_places=7, null=True, blank=True)
    check_out_accuracy = models.FloatField(null=True, blank=True, help_text="GPS accuracy reported by the device, in meters.")
    check_out_distance_meters = models.FloatField(null=True, blank=True, help_text="Distance from the branch attendance location, in meters.")
    check_out_location_verified = models.BooleanField(null=True, blank=True)
    check_out_photo = models.ImageField(upload_to=check_out_photo_path, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-attendance_date", "-check_in_at"]
        constraints = [models.UniqueConstraint(
            fields=("employee", "attendance_date"),
            condition=Q(check_out_at__isnull=True),
            name="one_open_attendance_per_employee_day",
        )]
        indexes = [
            models.Index(fields=["branch", "attendance_date"], name="attendance_branch_date_idx"),
        ]

    def __str__(self):
        return f"{self.employee.employee_code} {self.attendance_date}"

    @property
    def state(self):
        return self.State.CHECKED_OUT if self.check_out_at else self.State.CHECKED_IN


class DeviceAttendanceEvent(models.Model):
    """Idempotency ledger for fingerprint events, including accepted and rejected acknowledgements."""
    device = models.ForeignKey("devices.Device", on_delete=models.PROTECT, related_name="attendance_events")
    event_id = models.UUIDField()
    fingerprint_slot = models.PositiveIntegerField()
    occurred_at = models.DateTimeField()
    outcome = models.CharField(max_length=24, default="RECEIVED")
    response = models.JSONField(default=dict, blank=True)
    attendance = models.ForeignKey(Attendance, on_delete=models.PROTECT, null=True, blank=True, related_name="device_events")
    received_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=("device", "event_id"), name="unique_device_attendance_event")]
        indexes = [models.Index(fields=("device", "received_at"), name="device_event_received_idx")]


class AttendanceEvent(models.Model):
    class Action(models.TextChoices):
        CHECK_IN = "CHECK_IN", "Check-in"
        CHECK_OUT = "CHECK_OUT", "Check-out"

    class Method(models.TextChoices):
        MOBILE_GPS = "MOBILE_GPS", "Mobile GPS"
        BIOMETRIC = "BIOMETRIC", "Biometric"
        MANUAL = "MANUAL", "Admin manual"

    attendance = models.ForeignKey(Attendance, on_delete=models.PROTECT, related_name="actions")
    action = models.CharField(max_length=12, choices=Action.choices)
    method = models.CharField(max_length=16, choices=Method.choices)
    actor = models.ForeignKey("accounts.User", on_delete=models.PROTECT, related_name="attendance_actions", null=True, blank=True)
    device = models.ForeignKey("devices.Device", on_delete=models.PROTECT, related_name="attendance_actions", null=True, blank=True)
    device_event = models.ForeignKey(DeviceAttendanceEvent, on_delete=models.PROTECT, related_name="actions", null=True, blank=True)
    occurred_at = models.DateTimeField()

    class Meta:
        ordering = ["occurred_at", "id"]
