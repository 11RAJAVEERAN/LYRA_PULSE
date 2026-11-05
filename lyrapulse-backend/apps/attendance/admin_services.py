"""Read-only attendance logic for the Admin web app.

Nothing here writes to the database. Everything is derived from the SAME `Attendance` table that the Flutter
check-in / check-out endpoints write to, so a mobile check-in is visible to admins immediately.

Present / Absent (the only business statuses supported for now)
---------------------------------------------------------------
For a given date the *population* is the set of employees in the caller's organization/branch scope who are
either
  * eligible: active employee, active user, and (no joining date, or joined on/before that date), OR
  * already have an attendance row on that date (so history stays correct for people deactivated later).

  PRESENT = the population member has an Attendance row for that date (a row only exists once checked in).
  ABSENT  = the population member has no Attendance row for that date. This is DERIVED on read; no row is
            ever created for an absent employee.

Late / Early / Overtime are deliberately NOT implemented (they need shift / policy rules that are not final).

Date ranges
-----------
A range is reported as one logical row per employee PER DAY (never collapsed into a single status). Rows are
grouped by date (newest first by default); the other sort keys order the rows inside each date.
"""
import datetime as dt
from dataclasses import dataclass, field
from typing import List, Optional

from django.db.models import Count, Exists, F, OuterRef, Q, Subquery

from apps.accounts.scope import scope_queryset
from apps.employees.models import Employee

from .models import Attendance

STATUS_PRESENT = "PRESENT"
STATUS_ABSENT = "ABSENT"
STATUS_FILTER_VALUES = ("present", "absent")  # query-string values; deliberately no late/early/overtime

MAX_RANGE_DAYS = 92  # safeguard for list / summary / export; keeps the derived-row space bounded
EXPORT_CHUNK_SIZE = 500

ORDERING_CHOICES = (
    "attendance_date", "-attendance_date",
    "employee_name", "-employee_name",
    "check_in", "-check_in",
    "check_out", "-check_out",
)
DEFAULT_LIST_ORDERING = "-attendance_date"
DEFAULT_EXPORT_ORDERING = "attendance_date"

EMPLOYEE_RELATED = ("user", "branch", "department", "designation")


@dataclass(frozen=True)
class AttendanceFilters:
    branch: Optional[int] = None
    department: Optional[int] = None
    designation: Optional[int] = None
    search: str = ""
    status: Optional[str] = None  # "present" | "absent" | None
    ordering: str = DEFAULT_LIST_ORDERING


@dataclass
class AttendanceRow:
    """One employee on one date. `attendance` is None for an absent employee."""
    employee: Employee
    attendance_date: dt.date
    attendance: Optional[Attendance]
    sessions: list = field(default_factory=list)

    @property
    def status(self):
        return STATUS_PRESENT if self.attendance is not None else STATUS_ABSENT


# ----------------------------------------------------------------------------------------------------------------
# Working hours
# ----------------------------------------------------------------------------------------------------------------
def working_seconds(attendance):
    """Completed working duration in whole seconds, or None.

    None when there is no attendance, the employee has not checked out yet (a live duration is NOT presented
    as a final one), or the stored times are inconsistent (check-out before check-in).
    """
    if attendance is None or attendance.check_out_at is None:
        return None
    seconds = int((attendance.check_out_at - attendance.check_in_at).total_seconds())
    return seconds if seconds >= 0 else None


def total_working_seconds(sessions):
    values = [working_seconds(item) for item in sessions]
    return None if not any(value is not None for value in values) else sum(value or 0 for value in values)


def format_duration(seconds):
    if seconds is None:
        return None
    hours, remainder = divmod(seconds, 3600)
    return f"{hours}h {remainder // 60}m"


# ----------------------------------------------------------------------------------------------------------------
# Dates
# ----------------------------------------------------------------------------------------------------------------
def days_in_range(start, end, newest_first=True):
    days = [start + dt.timedelta(days=offset) for offset in range((end - start).days + 1)]
    return days[::-1] if newest_first else days


# ----------------------------------------------------------------------------------------------------------------
# Population (scope + filters) — always starts from the caller's organization/branch scope
# ----------------------------------------------------------------------------------------------------------------
def _apply_search(queryset, search):
    """Every whitespace-separated term must match the employee code or name. Phone numbers are never searched."""
    for term in (search or "").split():
        queryset = queryset.filter(
            Q(employee_code__icontains=term) | Q(user__first_name__icontains=term)
            | Q(user__last_name__icontains=term) | Q(display_name__icontains=term)
        )
    return queryset


def scoped_employees(user, filters):
    """Employees the user may see (the project's scope helper; fail-closed), narrowed by the query filters."""
    queryset = scope_queryset(Employee.objects.all(), user, "branch")
    if filters.branch:
        queryset = queryset.filter(branch_id=filters.branch)
    if filters.department:
        queryset = queryset.filter(department_id=filters.department)
    if filters.designation:
        queryset = queryset.filter(designation_id=filters.designation)
    return _apply_search(queryset, filters.search)


def _eligible_on(day):
    return Q(is_active=True, user__is_active=True) & (Q(joining_date__isnull=True) | Q(joining_date__lte=day))


def _order_by(ordering):
    key, descending = ordering.lstrip("-"), ordering.startswith("-")
    name_fields = ("user__first_name", "user__last_name", "employee_code")
    name = [F(field).asc() for field in name_fields]
    if key == "employee_name":
        return [F(field).desc() if descending else F(field).asc() for field in name_fields]
    if key in ("check_in", "check_out"):
        column = "att_check_in" if key == "check_in" else "att_check_out"
        primary = F(column).desc(nulls_last=True) if descending else F(column).asc(nulls_last=True)
        return [primary, *name]
    return name  # attendance_date: the date direction is handled by the day order; names break ties


def day_queryset(user, day, filters):
    """Employees in the population for `day`, with has_attendance / att_check_in / att_check_out annotated.

    Uses EXISTS / scalar subqueries (never a join), so rows can never be duplicated.
    """
    on_day = Attendance.objects.filter(employee=OuterRef("pk"), attendance_date=day)
    queryset = scoped_employees(user, filters).annotate(
        has_attendance=Exists(on_day),
        att_check_in=Subquery(on_day.values("check_in_at")[:1]),
        att_check_out=Subquery(on_day.values("check_out_at")[:1]),
    ).filter(_eligible_on(day) | Q(has_attendance=True))
    if filters.status == "present":
        queryset = queryset.filter(has_attendance=True)
    elif filters.status == "absent":
        queryset = queryset.filter(has_attendance=False)
    return queryset


def _rows_for_day(user, day, filters, start, stop):
    """Rows [start, stop) of one day: one query for the employees, one for their attendance (no N+1)."""
    queryset = (day_queryset(user, day, filters).select_related(*EMPLOYEE_RELATED)
                .order_by(*_order_by(filters.ordering))[start:stop])
    employees = list(queryset)
    records = {}
    for record in Attendance.objects.filter(employee_id__in=[e.pk for e in employees], attendance_date=day).prefetch_related("actions").order_by("check_in_at", "pk"):
        records.setdefault(record.employee_id, []).append(record)
    return [AttendanceRow(employee, day, (records.get(employee.pk) or [None])[-1], records.get(employee.pk, [])) for employee in employees]


class AttendanceRowSequence:
    """A lazily-sliced, paginator-friendly sequence of AttendanceRow across one or more days.

    Absent employees are derived rows, so they cannot be paginated as a plain queryset. This keeps pagination in
    the database: it counts per day, then fetches only the slice of the days a page actually needs.
    """

    def __init__(self, user, days, filters):
        self.user, self.days, self.filters = user, days, filters
        self._counts = None

    def _day_counts(self):
        if self._counts is None:
            self._counts = [day_queryset(self.user, day, self.filters).order_by().count() for day in self.days]
        return self._counts

    def __len__(self):
        return sum(self._day_counts())

    def count(self):
        return len(self)

    def __getitem__(self, key):
        if not isinstance(key, slice):
            raise TypeError("AttendanceRowSequence only supports slicing.")
        start, stop, _ = key.indices(len(self))
        rows, offset = [], 0
        for day, count in zip(self.days, self._day_counts()):
            if offset >= stop:
                break
            low, high = max(start - offset, 0), min(stop - offset, count)
            if low < high:
                rows.extend(_rows_for_day(self.user, day, self.filters, low, high))
            offset += count
        return rows


def iter_rows(user, days, filters, chunk_size=EXPORT_CHUNK_SIZE):
    """Stream every row (used by the CSV export) in bounded-size chunks."""
    for day in days:
        total = day_queryset(user, day, filters).order_by().count()
        for start in range(0, total, chunk_size):
            yield from _rows_for_day(user, day, filters, start, start + chunk_size)


# ----------------------------------------------------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------------------------------------------------
def build_summary(user, start, end, filters):
    """total_employees / present / absent for the caller's scope.

    For a single date these are plain per-day counts. For a range they are counted per EMPLOYEE:
      total_employees = distinct employees in the population on at least one day of the range
      present         = those with an attendance record on at least one day of the range
      absent          = total_employees - present (no attendance record on any day of the range)
    Counts use EXISTS, so they are never inflated by joins.
    """
    in_range = Attendance.objects.filter(employee=OuterRef("pk"), attendance_date__range=(start, end))
    population = scoped_employees(user, filters).annotate(has_attendance=Exists(in_range)).filter(
        _eligible_on(end) | Q(has_attendance=True)
    )
    totals = population.aggregate(total=Count("pk"), present=Count("pk", filter=Q(has_attendance=True)))
    return {"total_employees": totals["total"], "present": totals["present"], "absent": totals["total"] - totals["present"]}


# ----------------------------------------------------------------------------------------------------------------
# Detail
# ----------------------------------------------------------------------------------------------------------------
def get_day_row(user, employee_id, day):
    """The row for one employee on one date, or None when the employee is not in the caller's scope/population."""
    employee = (day_queryset(user, day, AttendanceFilters()).select_related(*EMPLOYEE_RELATED)
                .filter(pk=employee_id).first())
    if employee is None:
        return None
    sessions = list(Attendance.objects.select_related("branch").filter(employee=employee, attendance_date=day).prefetch_related("actions").order_by("check_in_at", "pk"))
    return AttendanceRow(employee, day, sessions[-1] if sessions else None, sessions)
