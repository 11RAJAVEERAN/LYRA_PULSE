from datetime import date, datetime

from django.conf import settings
from django.db import models
from django.db.models import F, Q
from django.db.models.functions import Lower
from django.utils import timezone

from apps.branches.models import Branch
from apps.employees.models import Employee


class Weekday(models.TextChoices):
    SUNDAY = "SUNDAY", "Sunday"
    MONDAY = "MONDAY", "Monday"
    TUESDAY = "TUESDAY", "Tuesday"
    WEDNESDAY = "WEDNESDAY", "Wednesday"
    THURSDAY = "THURSDAY", "Thursday"
    FRIDAY = "FRIDAY", "Friday"
    SATURDAY = "SATURDAY", "Saturday"


WEEKDAY_ORDER = tuple(Weekday.values)


class Shift(models.Model):
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, related_name="shifts")
    name = models.CharField(max_length=120)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("branch__name", "name")
        constraints = [
            models.UniqueConstraint(Lower("name"), "branch", name="unique_shift_name_per_branch_ci"),
        ]
        permissions = [("manage_shifts", "Can create and manage shifts")]

    def __str__(self):
        return f"{self.name} ({self.branch.name})"

    def save(self, *args, **kwargs):
        self.name = self.name.strip()
        super().save(*args, **kwargs)

    def schedule_for(self, on_date: date):
        """Return the immutable schedule revision effective on a date, if one exists."""
        revisions = getattr(self, "_prefetched_schedule_revisions", None)
        if revisions is not None:
            applicable = [revision for revision in revisions if revision.effective_from <= on_date]
            return max(applicable, key=lambda revision: revision.effective_from) if applicable else None
        return self.schedule_revisions.filter(effective_from__lte=on_date).order_by("-effective_from").first()


class ShiftScheduleRevision(models.Model):
    """An effective-dated weekly schedule. Revisions effective in the past are never edited."""

    shift = models.ForeignKey(Shift, on_delete=models.PROTECT, related_name="schedule_revisions")
    effective_from = models.DateField()
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL,
        related_name="created_shift_schedule_revisions",
    )
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL,
        related_name="updated_shift_schedule_revisions",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("effective_from", "id")
        constraints = [models.UniqueConstraint(fields=("shift", "effective_from"), name="unique_shift_schedule_effective_date")]

    def __str__(self):
        return f"{self.shift.name} from {self.effective_from}"


class ShiftDaySchedule(models.Model):
    revision = models.ForeignKey(ShiftScheduleRevision, on_delete=models.CASCADE, related_name="days")
    weekday = models.CharField(max_length=9, choices=Weekday.choices)
    is_working = models.BooleanField(default=False)
    start_time = models.TimeField(null=True, blank=True)
    end_time = models.TimeField(null=True, blank=True)
    break_start_time = models.TimeField(null=True, blank=True)
    break_end_time = models.TimeField(null=True, blank=True)

    class Meta:
        ordering = ("weekday",)
        constraints = [
            models.UniqueConstraint(fields=("revision", "weekday"), name="unique_shift_day_per_revision"),
            models.CheckConstraint(
                condition=(
                    Q(is_working=False, start_time__isnull=True, end_time__isnull=True,
                      break_start_time__isnull=True, break_end_time__isnull=True)
                    | Q(is_working=True, start_time__isnull=False, end_time__isnull=False,
                        start_time__lt=F("end_time"))
                ),
                name="shift_day_working_time_consistency",
            ),
            models.CheckConstraint(
                condition=(Q(break_start_time__isnull=True, break_end_time__isnull=True)
                           | Q(break_start_time__isnull=False, break_end_time__isnull=False)),
                name="shift_day_break_pair_consistency",
            ),
            models.CheckConstraint(
                condition=(Q(break_start_time__isnull=True)
                           | Q(start_time__lt=F("break_start_time"),
                               break_start_time__lt=F("break_end_time"),
                               break_end_time__lt=F("end_time"))),
                name="shift_day_break_inside_shift",
            ),
        ]

    def __str__(self):
        return f"{self.get_weekday_display()} - {self.revision.shift.name}"

    @property
    def scheduled_working_seconds(self):
        if not self.is_working or self.start_time is None or self.end_time is None:
            return None
        start = datetime.combine(date.min, self.start_time)
        end = datetime.combine(date.min, self.end_time)
        seconds = int((end - start).total_seconds())
        if self.break_start_time is not None and self.break_end_time is not None:
            break_start = datetime.combine(date.min, self.break_start_time)
            break_end = datetime.combine(date.min, self.break_end_time)
            seconds -= int((break_end - break_start).total_seconds())
        return seconds


class ShiftAssignment(models.Model):
    employee = models.ForeignKey(Employee, on_delete=models.PROTECT, related_name="shift_assignments")
    shift = models.ForeignKey(Shift, on_delete=models.PROTECT, related_name="assignments")
    effective_from = models.DateField()
    effective_to = models.DateField(null=True, blank=True)
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL,
        related_name="created_shift_assignments",
    )
    updated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, null=True, blank=True, on_delete=models.SET_NULL,
        related_name="updated_shift_assignments",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ("-effective_from", "-id")
        constraints = [
            models.CheckConstraint(condition=Q(effective_to__isnull=True) | Q(effective_to__gte=F("effective_from")),
                                   name="shift_assignment_valid_date_range"),
        ]
        permissions = [("assign_shiftassignment", "Can assign shifts and manage employee week offs")]

    def __str__(self):
        return f"{self.employee.employee_code} - {self.shift.name} from {self.effective_from}"

    @property
    def week_off_days(self):
        ordered = {day: index for index, day in enumerate(WEEKDAY_ORDER)}
        return [value for value in sorted(self.week_offs.values_list("weekday", flat=True), key=ordered.get)]

    @property
    def assignment_state(self):
        today = timezone.localdate()
        if self.effective_from > today:
            return "FUTURE"
        if self.effective_to is not None and self.effective_to < today:
            return "EXPIRED"
        return "CURRENT"


class AssignmentWeekOff(models.Model):
    assignment = models.ForeignKey(ShiftAssignment, on_delete=models.CASCADE, related_name="week_offs")
    weekday = models.CharField(max_length=9, choices=Weekday.choices)

    class Meta:
        ordering = ("weekday",)
        constraints = [models.UniqueConstraint(fields=("assignment", "weekday"), name="unique_assignment_week_off")]

    def __str__(self):
        return f"{self.assignment.employee.employee_code}: {self.get_weekday_display()} off"

