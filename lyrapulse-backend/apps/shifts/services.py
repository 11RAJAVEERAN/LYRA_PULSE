from datetime import date, timedelta

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch
from apps.employees.models import Employee

from .models import AssignmentWeekOff, Shift, ShiftAssignment


@transaction.atomic
def assign_shift(*, employee_id, shift_id, effective_from, effective_to, week_off_days, actor):
    """Create one assignment, safely closing the prior period while preserving its history row."""
    # Employee.branch is nullable, so select_related("branch") introduces an outer join.
    # Lock only the Employee row; that row lock serializes assignments for this employee.
    employee = Employee.objects.select_for_update(of=("self",)).filter(
        pk=employee_id, is_active=True, user__is_active=True,
    ).first()
    if employee is None or employee.branch_id is None:
        raise ValidationError({"employee_id": "Select an active employee with a branch."})
    # Only the Shift row is needed to serialize deactivation against assignment creation.
    shift = Shift.objects.select_for_update(of=("self",)).filter(pk=shift_id).first()
    if shift is None:
        raise ValidationError({"shift_id": "Select a shift in your branch scope."})
    if not scope_queryset(Branch.objects.filter(pk=employee.branch_id), actor, "id").exists():
        raise ValidationError({"employee_id": "Employee is outside your branch scope."})
    if not scope_queryset(Shift.objects.filter(pk=shift.pk), actor, "branch").exists():
        raise ValidationError({"shift_id": "Shift is outside your branch scope."})
    if employee.branch_id != shift.branch_id:
        raise ValidationError({"shift_id": "Employee and shift must belong to the same branch."})
    if not shift.is_active:
        raise ValidationError({"shift_id": "Inactive shifts cannot receive new assignments."})
    if effective_to is not None and effective_to < effective_from:
        raise ValidationError({"effective_to": "Effective To must be on or after Effective From."})
    if shift.schedule_for(effective_from) is None:
        raise ValidationError({"effective_from": "The shift has no schedule in effect on this date."})

    # Build the inclusive date overlap query explicitly. The employee row lock serializes assignments
    # for this employee on PostgreSQL; the checks are repeated inside the transaction for every bulk row.
    from django.db.models import Q
    overlaps_query = ShiftAssignment.objects.select_for_update(of=("self",)).filter(
        employee=employee,
        effective_from__lte=effective_to if effective_to is not None else date.max,
    ).filter(Q(effective_to__isnull=True) | Q(effective_to__gte=effective_from)).order_by("effective_from", "pk")
    overlaps = list(overlaps_query)
    conflicts = [row for row in overlaps if row.effective_from >= effective_from]
    if conflicts:
        raise ValidationError({"effective_from": "This employee already has an overlapping shift assignment."})
    if len(overlaps) > 1:
        raise ValidationError({"effective_from": "Existing assignment history overlaps; resolve it before assigning a shift."})
    if overlaps:
        previous = overlaps[0]
        previous.effective_to = effective_from - timedelta(days=1)
        if previous.effective_to < previous.effective_from:
            raise ValidationError({"effective_from": "This assignment overlaps an existing assignment that starts on the same date."})
        previous.updated_by = actor
        previous.save(update_fields=("effective_to", "updated_by", "updated_at"))

    assignment = ShiftAssignment.objects.create(
        employee=employee, shift=shift, effective_from=effective_from, effective_to=effective_to,
        assigned_by=actor, updated_by=actor,
    )
    AssignmentWeekOff.objects.bulk_create([
        AssignmentWeekOff(assignment=assignment, weekday=weekday) for weekday in week_off_days
    ])
    return assignment


@transaction.atomic
def bulk_assign_shifts(*, employees, shift, effective_from, effective_to, week_off_days, actor):
    """All-or-nothing bulk assignment. Locks employee rows in a stable order to reduce deadlocks."""
    result = []
    for employee in sorted(employees, key=lambda item: item.pk):
        result.append(assign_shift(
            employee_id=employee.pk, shift_id=shift.pk, effective_from=effective_from,
            effective_to=effective_to, week_off_days=week_off_days, actor=actor,
        ))
    return result

