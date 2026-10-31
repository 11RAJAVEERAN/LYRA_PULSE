from collections import Counter

from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework import serializers
from rest_framework.exceptions import PermissionDenied

from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch
from apps.employees.models import Employee

from .models import (
    AssignmentWeekOff, Shift, ShiftAssignment, ShiftDaySchedule, ShiftScheduleRevision, WEEKDAY_ORDER, Weekday,
)


class DayScheduleInputSerializer(serializers.Serializer):
    weekday = serializers.ChoiceField(choices=Weekday.choices)
    is_working = serializers.BooleanField()
    start_time = serializers.TimeField(required=False, allow_null=True)
    end_time = serializers.TimeField(required=False, allow_null=True)
    break_start_time = serializers.TimeField(required=False, allow_null=True)
    break_end_time = serializers.TimeField(required=False, allow_null=True)

    def validate(self, attrs):
        weekday = attrs["weekday"]
        start, end = attrs.get("start_time"), attrs.get("end_time")
        break_start, break_end = attrs.get("break_start_time"), attrs.get("break_end_time")
        if not attrs["is_working"]:
            if any(value is not None for value in (start, end, break_start, break_end)):
                raise serializers.ValidationError({"is_working": "Non-working days must not include timing or break values."})
            attrs.update(start_time=None, end_time=None, break_start_time=None, break_end_time=None)
            return attrs
        if start is None or end is None:
            raise serializers.ValidationError({"start_time": "Start and end time are required for a working day."})
        if end <= start:
            raise serializers.ValidationError({"end_time": "End time must be later than start time. Overnight shifts are not supported yet."})
        if (break_start is None) != (break_end is None):
            raise serializers.ValidationError({"break_start_time": "Provide both break start and break end, or leave both empty."})
        if break_start is not None and not (start < break_start < break_end < end):
            raise serializers.ValidationError({"break_start_time": "Break must be inside shift timing and have positive duration."})
        return attrs


def validate_week_schedule(days):
    if len(days) != len(WEEKDAY_ORDER):
        raise serializers.ValidationError({"days": "Provide exactly one schedule entry for each weekday."})
    counts = Counter(item["weekday"] for item in days)
    missing_or_duplicate = [day for day in WEEKDAY_ORDER if counts[day] != 1]
    if missing_or_duplicate:
        raise serializers.ValidationError({"days": "Each weekday must appear exactly once."})
    if not any(item["is_working"] for item in days):
        raise serializers.ValidationError({"days": "Select at least one working day."})
    return sorted(days, key=lambda item: WEEKDAY_ORDER.index(item["weekday"]))


def day_output(day):
    return {
        "weekday": day.weekday,
        "is_working": day.is_working,
        "start_time": day.start_time,
        "end_time": day.end_time,
        "break_start_time": day.break_start_time,
        "break_end_time": day.break_end_time,
        "scheduled_working_seconds": day.scheduled_working_seconds,
    }


def revision_output(revision):
    if revision is None:
        return None
    days = list(revision.days.all())
    by_weekday = {item.weekday: item for item in days}
    return {
        "id": revision.pk,
        "effective_from": revision.effective_from,
        "created_at": revision.created_at,
        "created_by": _user_brief(revision.created_by),
        "updated_at": revision.updated_at,
        "updated_by": _user_brief(revision.updated_by),
        "days": [day_output(by_weekday[weekday]) for weekday in WEEKDAY_ORDER if weekday in by_weekday],
    }


def _user_brief(user):
    if user is None:
        return None
    return {"id": user.pk, "name": user.full_name}


class ShiftSerializer(serializers.ModelSerializer):
    branch = serializers.PrimaryKeyRelatedField(queryset=Branch.objects.all(), required=True)
    branch_detail = serializers.SerializerMethodField()
    schedule_effective_from = serializers.DateField(write_only=True, required=False)
    days = DayScheduleInputSerializer(many=True, write_only=True, required=False)
    current_schedule = serializers.SerializerMethodField()
    schedule_history = serializers.SerializerMethodField()
    schedule_summary = serializers.SerializerMethodField()
    scheduled_working_seconds_per_week = serializers.SerializerMethodField()
    assigned_employee_count = serializers.IntegerField(read_only=True, required=False)

    class Meta:
        model = Shift
        fields = (
            "id", "branch", "branch_detail", "name", "is_active", "created_at", "updated_at",
            "schedule_effective_from", "days", "current_schedule", "schedule_history", "schedule_summary",
            "scheduled_working_seconds_per_week", "assigned_employee_count",
        )
        read_only_fields = (
            "id", "branch_detail", "created_at", "updated_at", "current_schedule", "schedule_history",
            "schedule_summary", "scheduled_working_seconds_per_week", "assigned_employee_count",
        )

    def get_fields(self):
        fields = super().get_fields()
        if self.instance is not None:
            fields["branch"].read_only = True
        return fields

    def get_branch_detail(self, obj):
        return {"id": obj.branch_id, "name": obj.branch.name}

    def _revision_for_display(self, obj):
        return obj.schedule_for(timezone.localdate())

    def get_current_schedule(self, obj):
        return revision_output(self._revision_for_display(obj))

    def get_schedule_history(self, obj):
        if not self.context.get("include_schedule_history"):
            return None
        revisions = getattr(obj, "_all_schedule_revisions", None)
        if revisions is None:
            revisions = obj.schedule_revisions.all().prefetch_related("days", "created_by", "updated_by")
        return [revision_output(revision) for revision in revisions]

    def get_schedule_summary(self, obj):
        revision = self._revision_for_display(obj)
        if revision is None:
            return "No schedule"
        days = {item.weekday: item for item in revision.days.all()}
        working = [days[day] for day in WEEKDAY_ORDER if day in days and days[day].is_working]
        if not working:
            return "No working days"
        time_ranges = {(item.start_time, item.end_time) for item in working}
        names = [Weekday(day).label[:3] for day in WEEKDAY_ORDER if day in days and days[day].is_working]
        day_summary = names[0] if len(names) == 1 else f"{names[0]}–{names[-1]}" if len(names) == 5 else ", ".join(names)
        if len(time_ranges) == 1:
            start, end = next(iter(time_ranges))
            time_summary = f"{start.strftime('%H:%M')}–{end.strftime('%H:%M')}"
        else:
            time_summary = "Varies by day"
        return f"{day_summary} · {time_summary}"

    def get_scheduled_working_seconds_per_week(self, obj):
        revision = self._revision_for_display(obj)
        if revision is None:
            return 0
        return sum(item.scheduled_working_seconds or 0 for item in revision.days.all())

    def validate_name(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("Shift name is required.")
        if len(value) > 120:
            raise serializers.ValidationError("Shift name cannot exceed 120 characters.")
        return value

    def validate_branch(self, branch):
        request = self.context.get("request")
        if request and not scope_queryset(Branch.objects.filter(pk=branch.pk), request.user, "id").exists():
            raise serializers.ValidationError("You do not have access to this branch.")
        if not branch.is_active:
            raise serializers.ValidationError("Select an active branch.")
        return branch

    def validate(self, attrs):
        days = attrs.get("days")
        if self.instance is None and days is None:
            raise serializers.ValidationError({"days": "Provide a weekly schedule."})
        if days is not None:
            attrs["days"] = validate_week_schedule(days)
        if self.instance is None and "schedule_effective_from" not in attrs:
            attrs["schedule_effective_from"] = timezone.localdate()
        if self.instance is not None and days is not None and "schedule_effective_from" not in attrs:
            raise serializers.ValidationError({"schedule_effective_from": "Choose when the schedule change becomes effective."})
        if days is None and "schedule_effective_from" in attrs:
            raise serializers.ValidationError({"days": "A schedule effective date requires a day-wise schedule."})
        if self.instance is None and "branch" not in attrs:
            raise serializers.ValidationError({"branch": "Branch is required."})
        if self.instance is not None and "branch" in attrs:
            raise serializers.ValidationError({"branch": "A shift cannot be moved to another branch."})
        return attrs

    @staticmethod
    def _persist_days(revision, days):
        ShiftDaySchedule.objects.bulk_create([
            ShiftDaySchedule(revision=revision, **item) for item in days
        ])

    @transaction.atomic
    def create(self, validated_data):
        days = validated_data.pop("days")
        effective_from = validated_data.pop("schedule_effective_from")
        request = self.context.get("request")
        actor = request.user if request and request.user.is_authenticated else None
        if effective_from < timezone.localdate():
            raise serializers.ValidationError({"schedule_effective_from": "A new shift schedule cannot begin in the past."})
        try:
            shift = Shift.objects.create(**validated_data)
        except IntegrityError:
            raise serializers.ValidationError({"name": "A shift with this name already exists in this branch."}) from None
        revision = ShiftScheduleRevision.objects.create(shift=shift, effective_from=effective_from, created_by=actor, updated_by=actor)
        self._persist_days(revision, days)
        return shift

    @transaction.atomic
    def update(self, instance, validated_data):
        days = validated_data.pop("days", None)
        effective_from = validated_data.pop("schedule_effective_from", None)
        request = self.context.get("request")
        actor = request.user if request and request.user.is_authenticated else None
        shift = Shift.objects.select_for_update().get(pk=instance.pk)
        for field, value in validated_data.items():
            setattr(shift, field, value)
        try:
            shift.save()
        except IntegrityError:
            raise serializers.ValidationError({"name": "A shift with this name already exists in this branch."}) from None
        if days is not None:
            today = timezone.localdate()
            existing = ShiftScheduleRevision.objects.select_for_update().filter(
                shift=shift, effective_from=effective_from,
            ).first()
            latest_applicable = ShiftScheduleRevision.objects.filter(
                shift=shift, effective_from__lte=effective_from,
            ).order_by("-effective_from").first()
            if existing is not None and existing.effective_from <= today:
                if not _revision_matches(existing, days):
                    raise serializers.ValidationError({
                        "schedule_effective_from": "A schedule already in effect cannot be changed. Choose a future effective date.",
                    })
            else:
                if effective_from <= today:
                    if latest_applicable is None and existing is None:
                        pass
                    elif latest_applicable is not None and _revision_matches(latest_applicable, days):
                        pass
                    else:
                        raise serializers.ValidationError({
                            "schedule_effective_from": "Schedule changes must take effect after today to preserve history.",
                        })
                if existing is None and latest_applicable is not None and _revision_matches(latest_applicable, days):
                    return shift
                if existing is not None:
                    existing.days.all().delete()
                    existing.updated_by = actor
                    existing.save(update_fields=("updated_by", "updated_at"))
                    revision = existing
                else:
                    revision = ShiftScheduleRevision.objects.create(
                        shift=shift, effective_from=effective_from, created_by=actor, updated_by=actor,
                    )
                self._persist_days(revision, days)
        return shift


def _revision_matches(revision, days):
    existing = {item.weekday: item for item in revision.days.all()}
    if set(existing) != {item["weekday"] for item in days}:
        return False
    for item in days:
        saved = existing[item["weekday"]]
        if any(getattr(saved, key) != item.get(key) for key in (
            "is_working", "start_time", "end_time", "break_start_time", "break_end_time",
        )):
            return False
    return True


class ShiftWeekOffField(serializers.ListField):
    child = serializers.ChoiceField(choices=Weekday.choices)
    allow_empty = False

    def to_internal_value(self, data):
        values = super().to_internal_value(data)
        if len(values) != len(set(values)):
            raise serializers.ValidationError("Week off days must be unique.")
        return [value for value in WEEKDAY_ORDER if value in values]


class AssignmentWriteSerializer(serializers.Serializer):
    employee_id = serializers.IntegerField(min_value=1)
    shift_id = serializers.IntegerField(min_value=1)
    effective_from = serializers.DateField()
    effective_to = serializers.DateField(required=False, allow_null=True)
    week_off_days = ShiftWeekOffField()

    def validate(self, attrs):
        if attrs.get("effective_to") and attrs["effective_to"] < attrs["effective_from"]:
            raise serializers.ValidationError({"effective_to": "Effective To must be on or after Effective From."})
        request = self.context["request"]
        employee = scope_queryset(Employee.objects.select_related("branch", "user"), request.user, "branch").filter(
            pk=attrs["employee_id"], is_active=True, user__is_active=True,
        ).first()
        if employee is None:
            raise serializers.ValidationError({"employee_id": "Select an active employee in your branch scope."})
        shift = scope_queryset(Shift.objects.select_related("branch"), request.user, "branch").filter(pk=attrs["shift_id"]).first()
        if shift is None:
            raise serializers.ValidationError({"shift_id": "Select a shift in your branch scope."})
        if employee.branch_id != shift.branch_id:
            raise serializers.ValidationError({"shift_id": "Employee and shift must belong to the same branch."})
        if not shift.is_active:
            raise serializers.ValidationError({"shift_id": "Inactive shifts cannot receive new assignments."})
        if shift.schedule_for(attrs["effective_from"]) is None:
            raise serializers.ValidationError({"effective_from": "The shift has no schedule in effect on this date."})
        attrs["employee"] = employee
        attrs["shift"] = shift
        return attrs


class BulkAssignmentWriteSerializer(serializers.Serializer):
    employee_ids = serializers.ListField(child=serializers.IntegerField(min_value=1), allow_empty=False)
    shift_id = serializers.IntegerField(min_value=1)
    effective_from = serializers.DateField()
    effective_to = serializers.DateField(required=False, allow_null=True)
    week_off_days = ShiftWeekOffField()

    def validate(self, attrs):
        if len(attrs["employee_ids"]) != len(set(attrs["employee_ids"])):
            raise serializers.ValidationError({"employee_ids": "Employee IDs must be unique."})
        if attrs.get("effective_to") and attrs["effective_to"] < attrs["effective_from"]:
            raise serializers.ValidationError({"effective_to": "Effective To must be on or after Effective From."})
        user = self.context["request"].user
        shift = scope_queryset(Shift.objects.select_related("branch"), user, "branch").filter(pk=attrs["shift_id"]).first()
        if shift is None:
            raise serializers.ValidationError({"shift_id": "Select a shift in your branch scope."})
        if not shift.is_active:
            raise serializers.ValidationError({"shift_id": "Inactive shifts cannot receive new assignments."})
        if shift.schedule_for(attrs["effective_from"]) is None:
            raise serializers.ValidationError({"effective_from": "The shift has no schedule in effect on this date."})
        employees = list(scope_queryset(
            Employee.objects.select_related("branch", "user"), user, "branch",
        ).filter(pk__in=attrs["employee_ids"], is_active=True, user__is_active=True).order_by("pk"))
        if len(employees) != len(attrs["employee_ids"]):
            raise serializers.ValidationError({"employee_ids": "One or more employees are inactive, missing, or outside your branch scope."})
        if any(employee.branch_id != shift.branch_id for employee in employees):
            raise serializers.ValidationError({"employee_ids": "Employee and shift must belong to the same branch."})
        attrs["employees"] = employees
        attrs["shift"] = shift
        return attrs


class AssignmentReadSerializer(serializers.ModelSerializer):
    employee = serializers.SerializerMethodField()
    shift = serializers.SerializerMethodField()
    branch = serializers.SerializerMethodField()
    week_off_days = serializers.ListField(read_only=True)
    assignment_state = serializers.CharField(read_only=True)
    assigned_by = serializers.SerializerMethodField()
    updated_by = serializers.SerializerMethodField()

    class Meta:
        model = ShiftAssignment
        fields = (
            "id", "employee", "shift", "branch", "effective_from", "effective_to", "week_off_days",
            "assignment_state", "assigned_by", "updated_by", "created_at", "updated_at",
        )

    def get_employee(self, obj):
        employee = obj.employee
        return {
            "id": employee.pk,
            "employee_code": employee.employee_code,
            "name": employee.display_name or employee.user.full_name,
            "branch_id": employee.branch_id,
            "department": {"id": employee.department_id, "name": employee.department.name} if employee.department_id else None,
            "designation": {"id": employee.designation_id, "name": employee.designation.name} if employee.designation_id else None,
        }

    def get_shift(self, obj):
        return {"id": obj.shift_id, "name": obj.shift.name, "is_active": obj.shift.is_active}

    def get_branch(self, obj):
        return {"id": obj.employee.branch_id, "name": obj.employee.branch.name if obj.employee.branch_id else ""}

    def get_assigned_by(self, obj):
        return _user_brief(obj.assigned_by)

    def get_updated_by(self, obj):
        return _user_brief(obj.updated_by)


class AssignmentHistorySerializer(AssignmentReadSerializer):
    pass

