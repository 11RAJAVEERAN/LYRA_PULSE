"""Serializers for the Admin attendance APIs: query-string validation and read-only representations.

Photo fields are returned as absolute URLs built from the request (`request.build_absolute_uri`), so the same
API works behind any host/domain. The database keeps only the relative storage path.
"""
from django.utils import timezone
from rest_framework import serializers

from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation

from .admin_services import (
    MAX_RANGE_DAYS, ORDERING_CHOICES, STATUS_FILTER_VALUES, DEFAULT_EXPORT_ORDERING, DEFAULT_LIST_ORDERING,
    AttendanceFilters, format_duration, working_seconds,
)
from .models import Attendance

MAX_PAGE_SIZE = 100


# ----------------------------------------------------------------------------------------------------------------
# Query-string validation
# ----------------------------------------------------------------------------------------------------------------
class _StatusField(serializers.ChoiceField):
    """Case-insensitive; only present / absent are supported (late, early and overtime are NOT implemented)."""

    def to_internal_value(self, data):
        return super().to_internal_value(str(data).strip().lower())


class _BaseQuerySerializer(serializers.Serializer):
    date = serializers.DateField(required=False, help_text="Single day, YYYY-MM-DD. Defaults to today.")
    start_date = serializers.DateField(required=False, help_text="Range start, YYYY-MM-DD (use with end_date).")
    end_date = serializers.DateField(required=False, help_text="Range end, YYYY-MM-DD (use with start_date).")
    branch = serializers.IntegerField(required=False, min_value=1)
    department = serializers.IntegerField(required=False, min_value=1)
    designation = serializers.IntegerField(required=False, min_value=1)
    search = serializers.CharField(required=False, allow_blank=True, max_length=100)

    # ---- ids must be inside the caller's own scope; out-of-scope and non-existent look identical (no leak) ----
    def _in_scope(self, model, value, branch_lookup, label):
        user = self.context["request"].user
        if not scope_queryset(model.objects.filter(pk=value), user, branch_lookup).exists():
            raise serializers.ValidationError(f"Invalid {label}.")
        return value

    def validate_branch(self, value):
        return self._in_scope(Branch, value, "id", "branch")

    def validate_department(self, value):
        return self._in_scope(Department, value, "branch", "department")

    def validate_designation(self, value):
        return self._in_scope(Designation, value, "department__branch", "designation")

    # ---- date resolution ----
    def validate(self, attrs):
        today = timezone.localdate()
        single, start, end = attrs.pop("date", None), attrs.pop("start_date", None), attrs.pop("end_date", None)
        if single and (start or end):
            raise serializers.ValidationError({"date": "Use either date or start_date/end_date, not both."})
        if single:
            start = end = single
        elif start or end:
            if not (start and end):
                raise serializers.ValidationError({
                    "end_date" if start else "start_date": "start_date and end_date must be provided together.",
                })
        else:
            start = end = today
        if start > end:
            raise serializers.ValidationError({"end_date": "end_date must be on or after start_date."})
        if end > today:
            raise serializers.ValidationError({("date" if single else "end_date"): "The date cannot be in the future."})
        if (end - start).days + 1 > MAX_RANGE_DAYS:
            raise serializers.ValidationError({"end_date": f"The date range cannot exceed {MAX_RANGE_DAYS} days."})
        attrs["start_date"], attrs["end_date"] = start, end
        return attrs

    def filters(self, **extra):
        data = self.validated_data
        return AttendanceFilters(
            branch=data.get("branch"), department=data.get("department"), designation=data.get("designation"),
            search=data.get("search", "").strip(), **extra,
        )


class SummaryQuerySerializer(_BaseQuerySerializer):
    """status / ordering / pagination do not apply to the summary and are ignored."""


class ListQuerySerializer(_BaseQuerySerializer):
    status = _StatusField(
        choices=STATUS_FILTER_VALUES, required=False,
        error_messages={"invalid_choice": "Unsupported status. Use 'present' or 'absent'."},
    )
    ordering = serializers.ChoiceField(choices=ORDERING_CHOICES, required=False, default=DEFAULT_LIST_ORDERING)
    page = serializers.IntegerField(required=False, min_value=1)
    page_size = serializers.IntegerField(required=False, min_value=1, max_value=MAX_PAGE_SIZE)

    def filters(self):
        return super().filters(status=self.validated_data.get("status"), ordering=self.validated_data["ordering"])


class ExportQuerySerializer(ListQuerySerializer):
    ordering = serializers.ChoiceField(choices=ORDERING_CHOICES, required=False, default=DEFAULT_EXPORT_ORDERING)


class DetailQuerySerializer(serializers.Serializer):
    date = serializers.DateField(required=False, help_text="YYYY-MM-DD. Defaults to today.")

    def validate_date(self, value):
        if value > timezone.localdate():
            raise serializers.ValidationError("The date cannot be in the future.")
        return value


# ----------------------------------------------------------------------------------------------------------------
# Presentation helpers (shared with the CSV export)
# ----------------------------------------------------------------------------------------------------------------
def employee_name(employee):
    """First + last name, else the display name, else the employee code. Never falls back to the phone number."""
    full = f"{employee.user.first_name} {employee.user.last_name}".strip()
    return full or employee.display_name or employee.employee_code


def media_url(request, field_file):
    """Absolute URL for an ImageField/FileField, or None when there is no file."""
    if not field_file:
        return None
    try:
        return request.build_absolute_uri(field_file.url)
    except ValueError:
        return None


_DATETIME = serializers.DateTimeField()


def _when(value):
    """ISO-8601 in the project time zone, exactly like the existing mobile attendance serializers."""
    return None if value is None else _DATETIME.to_representation(value)


def _brief(obj):
    return None if obj is None else {"id": obj.pk, "name": obj.name}


def _number(value):
    return None if value is None else float(value)


def _branch_location(branch):
    """Branch id/name plus its configured attendance coordinates (null when not configured). Display only."""
    if branch is None:
        return None
    return {**_brief(branch), "latitude": _number(branch.latitude), "longitude": _number(branch.longitude)}


class _RowSerializer(serializers.Serializer):
    """Base for serializers whose instance is an `AttendanceRow`."""

    def _request(self):
        return self.context["request"]

    def _employee(self, row):
        employee = row.employee
        return {
            "id": employee.pk,
            "employee_code": employee.employee_code,
            "name": employee_name(employee),
            "profile_photo": media_url(self._request(), employee.profile_photo),
        }


class AdminAttendanceRowSerializer(_RowSerializer):
    """One table row of the Admin Attendance page."""

    def to_representation(self, row):
        attendance, seconds = row.attendance, working_seconds(row.attendance)
        return {
            "employee": self._employee(row),
            "branch": _brief(row.employee.branch),
            "department": _brief(row.employee.department),
            "designation": _brief(row.employee.designation),
            "attendance_date": row.attendance_date,
            "status": row.status,
            "state": attendance.state.value if attendance else Attendance.State.NOT_CHECKED_IN.value,
            "has_check_in": attendance is not None,
            "has_check_out": attendance is not None and attendance.check_out_at is not None,
            "check_in_at": _when(attendance.check_in_at) if attendance else None,
            "check_out_at": _when(attendance.check_out_at) if attendance else None,
            "working_seconds": seconds,
            "working_hours_display": format_duration(seconds),
            "check_in_location_verified": attendance.check_in_location_verified if attendance else None,
            "check_out_location_verified": attendance.check_out_location_verified if attendance else None,
        }


class AdminAttendanceDetailSerializer(_RowSerializer):
    """Everything the right-hand detail panel needs, taken straight from the stored attendance record."""

    def _check_in(self, attendance):
        if attendance is None:
            return None
        return {
            "time": _when(attendance.check_in_at),
            "latitude": _number(attendance.check_in_latitude),
            "longitude": _number(attendance.check_in_longitude),
            "accuracy_m": attendance.check_in_accuracy,
            "distance_from_branch_m": attendance.check_in_distance_meters,
            "location_verified": attendance.check_in_location_verified,
            "photo": media_url(self._request(), attendance.check_in_photo),
        }

    def _check_out(self, attendance):
        if attendance is None or attendance.check_out_at is None:
            return None
        return {
            "time": _when(attendance.check_out_at),
            "latitude": _number(attendance.check_out_latitude),
            "longitude": _number(attendance.check_out_longitude),
            "accuracy_m": attendance.check_out_accuracy,
            "distance_from_branch_m": attendance.check_out_distance_meters,
            "location_verified": attendance.check_out_location_verified,
            "photo": media_url(self._request(), attendance.check_out_photo),
        }

    def to_representation(self, row):
        attendance, seconds = row.attendance, working_seconds(row.attendance)
        employee = row.employee
        return {
            "employee": {
                **self._employee(row),
                "branch": _brief(employee.branch),
                "department": _brief(employee.department),
                "designation": _brief(employee.designation),
            },
            "attendance_date": row.attendance_date,
            "status": row.status,
            "state": attendance.state.value if attendance else Attendance.State.NOT_CHECKED_IN.value,
            "attendance_branch": _branch_location(attendance.branch) if attendance else None,
            "check_in": self._check_in(attendance),
            "check_out": self._check_out(attendance),
            "working_seconds": seconds,
            "working_hours_display": format_duration(seconds),
        }