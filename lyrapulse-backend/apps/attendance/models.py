import uuid

from django.db import models
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
    branch = models.ForeignKey(
        Branch, on_delete=models.PROTECT, related_name="attendance_records",
        help_text="Branch the employee was verified against at check-in (decided by the server).",
    )
    attendance_date = models.DateField(help_text="Calendar date in the application time zone.")

    # --- Check-in (a row only exists once the employee has checked in) ---
    check_in_at = models.DateTimeField()
    check_in_latitude = models.DecimalField(max_digits=10, decimal_places=7)
    check_in_longitude = models.DecimalField(max_digits=10, decimal_places=7)
    check_in_accuracy = models.FloatField(help_text="GPS accuracy reported by the device, in meters.")
    check_in_distance_meters = models.FloatField(help_text="Distance from the branch attendance location, in meters.")
    check_in_location_verified = models.BooleanField()
    check_in_photo = models.ImageField(upload_to=check_in_photo_path)

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
        constraints = [
            models.UniqueConstraint(fields=["employee", "attendance_date"], name="unique_employee_attendance_per_day"),
        ]
        indexes = [
            models.Index(fields=["branch", "attendance_date"], name="attendance_branch_date_idx"),
        ]

    def __str__(self):
        return f"{self.employee.employee_code} {self.attendance_date}"

    @property
    def state(self):
        return self.State.CHECKED_OUT if self.check_out_at else self.State.CHECKED_IN
