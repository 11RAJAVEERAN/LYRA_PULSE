"""Read-only report builders that reuse the project's attendance and shift rules."""
import datetime as dt
from collections import defaultdict
from dataclasses import dataclass

from django.db.models import Q
from django.utils import timezone

from apps.accounts.scope import scope_queryset
from apps.attendance import admin_services as attendance_services
from apps.attendance.admin_serializers import employee_name
from apps.attendance.bulk_adjustment_api import _week_off_pairs
from apps.attendance.models import Attendance, AttendanceAdjustment
from apps.employees.models import Employee
from apps.shifts.models import ShiftAssignment


REPORT_TITLES = {
    "attendance-master": "Attendance Master",
    "daily-punch": "Daily Punch Report",
    "shift-wise": "Shift Wise Report",
    "working-hours": "Working Hours Report",
    "muster": "Muster Report",
    "branch-wise-punch": "Branch Wise Punch Report",
    "leave-taken": "Leave Taken Report",
}


@dataclass(frozen=True)
class ReportFilters:
    start: dt.date
    end: dt.date
    branch: int | None = None
    search: str = ""
    page: int = 1
    page_size: int = 10
    ordering: str = "employee_name"


def report_dates(filters):
    return [filters.start + dt.timedelta(days=i) for i in range((filters.end - filters.start).days + 1)]


def _employee_queryset(user, filters):
    query = scope_queryset(
        Employee.objects.select_related("user", "branch", "department", "designation"),
        user, "branch",
    )
    if filters.branch:
        query = query.filter(branch_id=filters.branch)
    if filters.search:
        for term in filters.search.strip().split():
            query = query.filter(
                Q(employee_code__icontains=term) | Q(display_name__icontains=term)
                | Q(user__first_name__icontains=term) | Q(user__last_name__icontains=term)
            )
    historical = (
        Q(attendance_records__attendance_date__range=(filters.start, filters.end))
        | Q(attendance_adjustments__attendance_date__range=(filters.start, filters.end))
        | (Q(shift_assignments__effective_from__lte=filters.end)
           & (Q(shift_assignments__effective_to__isnull=True) | Q(shift_assignments__effective_to__gte=filters.start)))
    )
    eligible = Q(is_active=True, user__is_active=True) & (
        Q(joining_date__isnull=True) | Q(joining_date__lte=filters.end)
    )
    query = query.filter(eligible | historical).distinct()
    order = filters.ordering
    descending = order.startswith("-")
    key = order.lstrip("-")
    fields = {
        "employee_name": ("user__first_name", "user__last_name", "employee_code"),
        "designation": ("designation__name", "user__first_name", "employee_code"),
        "attendance_date": ("employee_code",),
    }
    if key in fields:
        sort_fields = fields[key]
        query = query.order_by(*[f"{'-' if descending else ''}{field}" for field in sort_fields])
    else:
        query = query.order_by("employee_code", "pk")
    return query


def _page(items, filters, paginate=True):
    total = len(items)
    total_pages = max(1, (total + filters.page_size - 1) // filters.page_size)
    if paginate:
        offset = (filters.page - 1) * filters.page_size
        items = items[offset:offset + filters.page_size]
    return items, {"count": total, "page": filters.page, "page_size": filters.page_size, "total_pages": total_pages}


def _employees(user, filters, paginate=True):
    queryset = _employee_queryset(user, filters)
    total = queryset.count()
    if paginate:
        offset = (filters.page - 1) * filters.page_size
        employees = list(queryset[offset:offset + filters.page_size])
    else:
        employees = list(queryset)
    total_pages = max(1, (total + filters.page_size - 1) // filters.page_size)
    return employees, {"count": total, "page": filters.page, "page_size": filters.page_size, "total_pages": total_pages}


def _employee_payload(employee):
    return {
        "id": employee.pk,
        "employee_code": employee.employee_code,
        "name": employee_name(employee),
        "role": employee.designation.name if employee.designation_id else "",
        "department": employee.department.name if employee.department_id else "",
        "branch": employee.branch.name if employee.branch_id else "",
        "branch_id": employee.branch_id,
    }


def _attendance_map(employee_ids, filters):
    grouped = defaultdict(list)
    rows = (Attendance.objects.filter(
        employee_id__in=employee_ids, attendance_date__range=(filters.start, filters.end)
    ).prefetch_related("actions").order_by("attendance_date", "check_in_at", "pk"))
    for row in rows:
        grouped[(row.employee_id, row.attendance_date)].append(row)
    return grouped


def _first_last_punches(sessions):
    """Return first check-in and last valid check-out from sessions and punch events."""
    check_ins, check_outs = [], []
    for session in sessions:
        check_ins.append(session.check_in_at)
        if session.check_out_at and session.check_out_at >= session.check_in_at:
            check_outs.append(session.check_out_at)
        for action in session.actions.all():
            if action.action == "CHECK_IN":
                check_ins.append(action.occurred_at)
            elif action.action == "CHECK_OUT" and action.occurred_at >= session.check_in_at:
                check_outs.append(action.occurred_at)
    return (min(check_ins) if check_ins else None,
            max(check_outs or check_ins) if (check_outs or check_ins) else None)


def _total_working_seconds(sessions):
    """Sum completed, valid work sessions; keep incomplete-only days unset."""
    values = []
    for session in sessions:
        if session.check_out_at is None:
            values.append(None)
            continue
        seconds = int((session.check_out_at - session.check_in_at).total_seconds())
        values.append(seconds if seconds >= 0 else None)
    return None if not any(value is not None for value in values) else sum(value or 0 for value in values)


def _format_duration(seconds):
    if seconds is None:
        return None
    hours, remainder = divmod(seconds, 3600)
    return f"{hours}h {remainder // 60}m"


def _punch_times(sessions):
    first, last = _first_last_punches(sessions)
    return (
        timezone.localtime(first).strftime("%I:%M %p") if first else "-",
        timezone.localtime(last).strftime("%I:%M %p") if last else "-",
    )


def _master_row(row):
    attendance = row.attendance
    first, last = _first_last_punches(row.sessions)
    classification = getattr(row, "classification", None)
    employee = row.employee
    seconds = _total_working_seconds(row.sessions)
    return {
        "employee": {"id": employee.pk, "employee_code": employee.employee_code,
                     "name": employee_name(employee)},
        "branch": {"id": employee.branch_id, "name": employee.branch.name} if employee.branch_id else None,
        "department": {"id": employee.department_id, "name": employee.department.name} if employee.department_id else None,
        "designation": {"id": employee.designation_id, "name": employee.designation.name} if employee.designation_id else None,
        "attendance_date": row.attendance_date.isoformat(), "day": row.attendance_date.strftime("%A"),
        "status": row.status, "classification": classification,
        "classification_display": {"FD": "FD", "A": "Absent", "HD": "HD", "WO": "WO"}.get(classification, classification),
        "state": attendance.state.value if attendance else Attendance.State.NOT_CHECKED_IN.value,
        "has_check_in": attendance is not None, "has_check_out": bool(attendance and attendance.check_out_at),
        "check_in_at": timezone.localtime(attendance.check_in_at).isoformat() if attendance else None,
        "check_out_at": timezone.localtime(attendance.check_out_at).isoformat() if attendance and attendance.check_out_at else None,
        "working_seconds": seconds, "working_hours_display": _format_duration(seconds),
        "first_punch_at": timezone.localtime(first).isoformat() if first else None,
        "last_punch_at": timezone.localtime(last).isoformat() if last else None,
        "total_break_seconds": None, "break_hours_display": None,
    }


def _attach_master_classifications(rows):
    """Attach payroll classifications using the attendance app's persisted sources.

    Keep this adapter inside Reports so it also works with attendance service versions
    that do not expose the newer `attendance_master_classifications` helper.
    """
    if not rows:
        return
    employee_ids = {row.employee.pk for row in rows}
    dates = {row.attendance_date for row in rows}
    adjustments = AttendanceAdjustment.objects.filter(
        employee_id__in=employee_ids, attendance_date__in=dates
    ).values_list("employee_id", "attendance_date", "code")
    adjusted = {(employee_id, day): code for employee_id, day, code in adjustments}
    week_offs = _week_off_pairs(employee_ids, dates)
    for row in rows:
        key = (row.employee.pk, row.attendance_date)
        row.classification = adjusted.get(key) or (
            "FD" if row.attendance is not None else "WO" if key in week_offs else "A"
        )


def _report_rows(report, user, filters, paginate=True):
    dates = report_dates(filters)

    if report == "attendance-master":
        service_filters = attendance_services.AttendanceFilters(
            branch=filters.branch, search=filters.search,
            ordering=filters.ordering if filters.ordering in attendance_services.ORDERING_CHOICES else "-attendance_date",
        )
        rows = attendance_services.AttendanceRowSequence(
            user, attendance_services.days_in_range(filters.start, filters.end,
                newest_first=service_filters.ordering != "attendance_date"), service_filters,
        )
        count = len(rows)
        if paginate:
            offset = (filters.page - 1) * filters.page_size
            page_rows = rows[offset:offset + filters.page_size]
        else:
            page_rows = rows[:count]
        _attach_master_classifications(page_rows)
        result_rows = [_master_row(row) for row in page_rows]
        total_pages = max(1, (count + filters.page_size - 1) // filters.page_size)
        return {"results": result_rows, "count": count, "page": filters.page,
                "page_size": filters.page_size, "total_pages": total_pages, "dates": dates}

    if report == "leave-taken":
        # This repository has no leave persistence model or leave API. Do not invent or infer records.
        return {"results": [], "count": 0, "page": filters.page, "page_size": filters.page_size,
                "total_pages": 1, "dates": dates, "source_available": False,
                "message": "Leave records are not available because Leave Management has no backend data source yet."}

    employees, meta = _employees(user, filters, paginate=paginate)
    employee_ids = [employee.pk for employee in employees]
    payloads = {employee.pk: _employee_payload(employee) for employee in employees}
    attendance = _attendance_map(employee_ids, filters) if employee_ids else {}

    if report in ("daily-punch", "branch-wise-punch", "working-hours"):
        output = []
        for employee in employees:
            daily_values = []
            total_seconds = 0
            for day in dates:
                sessions = attendance.get((employee.pk, day), [])
                if report == "daily-punch":
                    daily_values.append(_punch_times(sessions)[0])
                else:
                    seconds = _total_working_seconds(sessions)
                    total_seconds += seconds or 0
                    daily_values.append(_format_duration(seconds) or "-")
            output.append({**payloads[employee.pk], "values": daily_values,
                           "total_working_seconds": total_seconds if report == "working-hours" else None,
                           "total_working_display": _format_duration(total_seconds) if report == "working-hours" else None,
                           "total_break_display": None})
        return {"results": output, **meta, "dates": dates, "source_available": True}

    if report == "shift-wise":
        employees, _ = _employees(user, filters, paginate=False)
        employee_ids = [employee.pk for employee in employees]
        payloads = {employee.pk: _employee_payload(employee) for employee in employees}
        attendance = _attendance_map(employee_ids, filters) if employee_ids else {}
        assignments = list(ShiftAssignment.objects.filter(
            employee_id__in=employee_ids, effective_from__lte=filters.end,
        ).filter(Q(effective_to__isnull=True) | Q(effective_to__gte=filters.start))
         .select_related("shift").prefetch_related("week_offs", "shift__schedule_revisions__days")
         .order_by("employee_id", "-effective_from", "-pk"))
        assignments_by_employee = defaultdict(list)
        revisions = defaultdict(list)
        for assignment in assignments:
            assignments_by_employee[assignment.employee_id].append(assignment)
            for revision in assignment.shift.schedule_revisions.all():
                if revision not in revisions[assignment.shift_id]:
                    revisions[assignment.shift_id].append(revision)
        output = []
        for employee in employees:
            for day in dates:
                assignment = next((item for item in assignments_by_employee[employee.pk]
                                   if item.effective_from <= day and (item.effective_to is None or item.effective_to >= day)), None)
                if assignment is None:
                    continue
                revision = max((item for item in revisions[assignment.shift_id] if item.effective_from <= day),
                               key=lambda item: item.effective_from, default=None)
                weekday = day.strftime("%A").upper()
                schedule = next((item for item in revision.days.all() if item.weekday == weekday), None) if revision else None
                first, _ = _punch_times(attendance.get((employee.pk, day), []))
                output.append({**payloads[employee.pk], "date": day.isoformat(), "day": day.strftime("%A"),
                    "shift": assignment.shift.name, "from": schedule.start_time.strftime("%I:%M %p") if schedule and schedule.start_time else "-",
                    "to": schedule.end_time.strftime("%I:%M %p") if schedule and schedule.end_time else "-",
                    "break_from": schedule.break_start_time.strftime("%I:%M %p") if schedule and schedule.break_start_time else "-",
                    "break_to": schedule.break_end_time.strftime("%I:%M %p") if schedule and schedule.break_end_time else "-",
                    "first_punch": first, "is_working_day": schedule.is_working if schedule else None})
        output, meta = _page(output, filters, paginate)
        return {"results": output, **meta, "dates": dates, "source_available": True}

    if report == "muster":
        dates = report_dates(filters)
        present = {(employee_id, day) for (employee_id, day), sessions in attendance.items() if sessions}
        adjustments = AttendanceAdjustment.objects.filter(
            employee_id__in=employee_ids, attendance_date__range=(filters.start, filters.end)
        ).values_list("employee_id", "attendance_date", "code") if employee_ids else []
        adjusted = {(employee_id, day): code for employee_id, day, code in adjustments}
        week_offs = _week_off_pairs(employee_ids, dates)
        output = []
        for employee in employees:
            statuses, full, half, absent, week_off = [], 0, 0, 0, 0
            for day in dates:
                key = (employee.pk, day)
                code = adjusted.get(key) or ("FD" if key in present else "WO" if key in week_offs else "A")
                statuses.append(code)
                full += code == "FD"
                half += code == "HD"
                absent += code == "A"
                week_off += code == "WO"
            output.append({**payloads[employee.pk], "full_days": full, "half_days": half,
                "absent_days": absent, "week_off_days": week_off, "leave_days": None,
                "holiday_days": None, "values": statuses})
        return {"results": output, **meta, "dates": dates, "source_available": True,
                "leave_holiday_source_available": False}

    raise ValueError(f"Unsupported report: {report}")


def build_report(report, user, query, paginate=True):
    filters = ReportFilters(
        start=query["start_date"], end=query["end_date"], branch=query.get("branch"),
        search=query.get("search", "").strip(), page=query.get("page", 1),
        page_size=query.get("page_size", 10), ordering=query.get("ordering", "employee_name"),
    )
    data = _report_rows(report, user, filters, paginate=paginate)
    data["start_date"] = filters.start
    data["end_date"] = filters.end
    data["branch"] = filters.branch
    return data
