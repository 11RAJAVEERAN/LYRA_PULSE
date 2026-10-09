from django.db import models
from django.db.models import Q

from apps.branches.models import Branch
from apps.devices.models import Device
from apps.employees.models import Employee


class Attendance(models.Model):
    employee = models.ForeignKey(Employee, on_delete=models.PROTECT, related_name="attendance_records")
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, related_name="attendance_records")
    device = models.ForeignKey(Device, on_delete=models.PROTECT, related_name="attendance_records")
    attendance_date = models.DateField()
    check_in_at = models.DateTimeField()
    check_out_at = models.DateTimeField(null=True, blank=True)
    source = models.CharField(max_length=20, default="BIOMETRIC")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-attendance_date", "check_in_at")
        constraints = [
            models.UniqueConstraint(
                fields=("employee", "attendance_date"),
                condition=Q(check_out_at__isnull=True),
                name="unique_open_employee_daily_attendance",
            ),
        ]

    def __str__(self):
        return "%s (%s)" % (self.employee.employee_code, self.attendance_date)
