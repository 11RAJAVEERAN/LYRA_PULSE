"""Payroll-facing attendance day overrides. Original check-in/out evidence remains untouched."""
import datetime as dt
from io import BytesIO

from django.db import transaction
from django.db.models import Q
from django.http import HttpResponse
from django.utils import timezone
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter
from rest_framework import serializers
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from apps.accounts.permissions import CanChangeEmployees, CanViewEmployees
from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch
from apps.common.responses import success_response
from apps.employees.models import Employee
from apps.shifts.models import ShiftAssignment

from .models import Attendance, AttendanceAdjustment, AttendanceAdjustmentAudit

MAX_GRID_DAYS = 31
MAX_PAGE_SIZE = 100
MAX_BATCH = 5000


class GridQuerySerializer(serializers.Serializer):
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    branch = serializers.IntegerField(required=False, min_value=1)
    page = serializers.IntegerField(required=False, min_value=1, default=1)
    page_size = serializers.IntegerField(required=False, min_value=1, max_value=MAX_PAGE_SIZE, default=50)

    def validate(self, attrs):
        start, end = attrs["start_date"], attrs["end_date"]
        if start > end:
            raise serializers.ValidationError({"end_date": "End date must be on or after start date."})
        if end > timezone.localdate():
            raise serializers.ValidationError({"end_date": "Future attendance dates cannot be adjusted."})
        if (end - start).days + 1 > MAX_GRID_DAYS:
            raise serializers.ValidationError({"end_date": f"Choose a range of {MAX_GRID_DAYS} days or fewer."})
        branch = attrs.get("branch")
        if branch and not scope_queryset(Branch.objects.filter(pk=branch), self.context["request"].user, "id").exists():
            raise serializers.ValidationError({"branch": "Invalid branch."})
        return attrs


class UpdateItemSerializer(serializers.Serializer):
    employee_id = serializers.IntegerField(min_value=1)
    attendance_date = serializers.DateField()
    code = serializers.ChoiceField(choices=AttendanceAdjustment.Code.choices)
    reason = serializers.CharField(required=False, allow_blank=True, max_length=500)


class BulkUpdateSerializer(serializers.Serializer):
    changes = UpdateItemSerializer(many=True, allow_empty=False, max_length=MAX_BATCH)

    def validate_changes(self, changes):
        keys = [(item["employee_id"], item["attendance_date"]) for item in changes]
        if len(keys) != len(set(keys)):
            raise serializers.ValidationError("A batch cannot contain the same employee/date more than once.")
        today = timezone.localdate()
        invalid = [str(day) for _, day in keys if day > today]
        if invalid:
            raise serializers.ValidationError("Future attendance dates cannot be adjusted.")
        return changes


def _employee_name(employee):
    name = employee.user.full_name.strip()
    return name if name and name != employee.user.phone_number else (employee.display_name or employee.employee_code)


def _excel_text(value):
    value = "" if value is None else str(value)
    return "'" + value if value[:1] in ("=", "+", "-", "@", "\t", "\r") else value


def _scoped_employees(user, branch=None):
    query = scope_queryset(
        Employee.objects.select_related("user", "branch", "department", "designation"), user, "branch"
    )
    if branch:
        query = query.filter(branch_id=branch)
    return query


def _week_off_pairs(employee_ids, days):
    days = list(days)
    if not employee_ids or not days:
        return set()
    start, end = min(days), max(days)
    assignments = {}
    query = ShiftAssignment.objects.filter(employee_id__in=employee_ids, effective_from__lte=end).filter(
        Q(effective_to__isnull=True) | Q(effective_to__gte=start)
    ).prefetch_related("week_offs").order_by("employee_id", "-effective_from", "-pk")
    for assignment in query:
        assignments.setdefault(assignment.employee_id, []).append((
            assignment.effective_from, assignment.effective_to,
            {week_off.weekday for week_off in assignment.week_offs.all()},
        ))
    return {
        (employee_id, day)
        for employee_id in employee_ids
        for day in days
        if any(
            effective_from <= day and (effective_to is None or effective_to >= day) and day.strftime("%A").upper() in week_offs
            for effective_from, effective_to, week_offs in assignments.get(employee_id, [])
        )
    }


def _payload_for_employees(employees, start, end):
    employee_ids = [employee.pk for employee in employees]
    attendances = Attendance.objects.filter(employee_id__in=employee_ids, attendance_date__range=(start, end)).order_by("check_in_at", "pk")
    present = { (row.employee_id, row.attendance_date) for row in attendances }
    adjustments = AttendanceAdjustment.objects.filter(employee_id__in=employee_ids, attendance_date__range=(start, end))
    adjusted = {(row.employee_id, row.attendance_date): row for row in adjustments}
    dates = [start + dt.timedelta(days=offset) for offset in range((end - start).days + 1)]
    week_offs = _week_off_pairs(employee_ids, dates)
    rows = []
    for employee in employees:
        cells = []
        for day in dates:
            if employee.joining_date and day < employee.joining_date:
                cells.append({"date": day.isoformat(), "code": None, "adjusted": False, "editable": False})
                continue
            adjustment = adjusted.get((employee.pk, day))
            is_present = (employee.pk, day) in present
            is_week_off = (employee.pk, day) in week_offs
            default_code = AttendanceAdjustment.Code.FULL_DAY if is_present else AttendanceAdjustment.Code.WEEK_OFF if is_week_off else AttendanceAdjustment.Code.ABSENT
            code = adjustment.code if adjustment else default_code
            cells.append({"date": day.isoformat(), "code": code, "adjusted": adjustment is not None, "editable": True})
        rows.append({
            "employee_id": employee.pk,
            "employee_code": employee.employee_code,
            "employee_name": _employee_name(employee),
            "department": employee.department.name if employee.department else "—",
            "designation": employee.designation.name if employee.designation else "—",
            "cells": cells,
        })
    return dates, rows


def _employee_queryset(user, branch, start, end):
    base = _scoped_employees(user, branch)
    history = Q(attendance_records__attendance_date__range=(start, end)) | Q(attendance_adjustments__attendance_date__range=(start, end))
    eligible = Q(is_active=True, user__is_active=True) & (Q(joining_date__isnull=True) | Q(joining_date__lte=end))
    return base.filter(eligible | history).distinct().order_by("employee_code", "pk")


class AttendanceAdjustmentCodesView(APIView):
    permission_classes = [IsAuthenticated, CanViewEmployees]

    def get(self, request):
        editable = request.user.role == request.user.Role.SUPERADMIN or request.user.has_perm("employees.change_employee")
        data = [
            {"code": AttendanceAdjustment.Code.FULL_DAY, "label": "Full Day", "description": "Full-day attendance classification.", "editable": editable},
            {"code": AttendanceAdjustment.Code.ABSENT, "label": "Absent", "description": "No attendance recorded or marked absent by an administrator.", "editable": editable},
            {"code": AttendanceAdjustment.Code.HALF_DAY, "label": "Half Day", "description": "Half-day attendance classification.", "editable": editable},
            {"code": AttendanceAdjustment.Code.WEEK_OFF, "label": "Week Off", "description": "Weekly off from the employee's effective shift assignment, or manually marked by an administrator.", "editable": editable},
        ]
        return success_response(data)


class AttendanceAdjustmentGridView(APIView):
    permission_classes = [IsAuthenticated, CanViewEmployees]

    def get(self, request):
        serializer = GridQuerySerializer(data=request.query_params, context={"request": request})
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        start, end = data["start_date"], data["end_date"]
        branch = data.get("branch")
        queryset = _employee_queryset(request.user, branch, start, end)
        total = queryset.count()
        page, size = data["page"], data["page_size"]
        employees = list(queryset[(page - 1) * size:page * size])
        dates, rows = _payload_for_employees(employees, start, end)
        return success_response({
            "start_date": start.isoformat(), "end_date": end.isoformat(),
            "dates": [{"date": day.isoformat(), "weekday": day.strftime("%a")} for day in dates],
            "codes": AttendanceAdjustment.Code.choices,
            "results": rows, "count": total, "page": page, "page_size": size,
        })


class AttendanceAdjustmentBulkUpdateView(APIView):
    permission_classes = [IsAuthenticated, CanChangeEmployees]

    def post(self, request):
        serializer = BulkUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        changes = serializer.validated_data["changes"]
        employee_ids = {item["employee_id"] for item in changes}
        employees = _scoped_employees(request.user).filter(pk__in=employee_ids)
        employee_map = {employee.pk: employee for employee in employees}
        missing = employee_ids - employee_map.keys()
        if missing:
            raise ValidationError({"employees": "One or more employees do not exist or are outside your branch access."})
        pre_joining = [
            {"employee_id": item["employee_id"], "attendance_date": item["attendance_date"].isoformat(), "message": "This employee had not joined yet."}
            for item in changes
            if employee_map[item["employee_id"]].joining_date and item["attendance_date"] < employee_map[item["employee_id"]].joining_date
        ]
        if pre_joining:
            raise ValidationError({"changes": pre_joining})

        with transaction.atomic():
            # Employee row locks also serialize creation when no adjustment row exists yet.
            locked_employees = list(_scoped_employees(request.user).select_for_update(of=("self",)).filter(pk__in=employee_ids).order_by("pk"))
            if len(locked_employees) != len(employee_ids):
                raise ValidationError({"employees": "One or more employees are no longer available in your branch access."})
            # Lock existing override rows so concurrent editors cannot silently replace one another.
            existing = {
                (item.employee_id, item.attendance_date): item
                for item in AttendanceAdjustment.objects.select_for_update().filter(
                    employee_id__in=employee_ids,
                    attendance_date__in={item["attendance_date"] for item in changes},
                )
            }
            present_keys = set(Attendance.objects.filter(
                employee_id__in=employee_ids,
                attendance_date__in={item["attendance_date"] for item in changes},
            ).values_list("employee_id", "attendance_date"))
            week_off_keys = _week_off_pairs(employee_ids, {item["attendance_date"] for item in changes})
            changed = 0
            for item in changes:
                key = (item["employee_id"], item["attendance_date"])
                adjustment = existing.get(key)
                old_code = adjustment.code if adjustment else (
                    AttendanceAdjustment.Code.FULL_DAY if key in present_keys else AttendanceAdjustment.Code.WEEK_OFF if key in week_off_keys else AttendanceAdjustment.Code.ABSENT
                )
                if old_code == item["code"]:
                    continue
                if adjustment:
                    adjustment.code = item["code"]
                    adjustment.updated_by = request.user
                    adjustment.reason = item.get("reason", "")
                    adjustment.save(update_fields=("code", "updated_by", "reason", "updated_at"))
                else:
                    adjustment = AttendanceAdjustment.objects.create(
                        employee=employee_map[item["employee_id"]], attendance_date=item["attendance_date"],
                        code=item["code"], updated_by=request.user, reason=item.get("reason", ""),
                    )
                    existing[key] = adjustment
                AttendanceAdjustmentAudit.objects.create(
                    adjustment=adjustment, employee=employee_map[item["employee_id"]],
                    attendance_date=item["attendance_date"], previous_code=old_code, new_code=item["code"],
                    actor=request.user, reason=item.get("reason", ""),
                )
                changed += 1
        return success_response({"saved": changed}, f"Saved {changed} attendance adjustment(s).")


class AttendanceAdjustmentExportView(APIView):
    permission_classes = [IsAuthenticated, CanViewEmployees]

    def get(self, request):
        serializer = GridQuerySerializer(data={**request.query_params.dict(), "page": 1, "page_size": MAX_PAGE_SIZE}, context={"request": request})
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        start, end = data["start_date"], data["end_date"]
        branch = data.get("branch")
        dates = [start + dt.timedelta(days=offset) for offset in range((end - start).days + 1)]
        employees = _employee_queryset(request.user, branch, start, end)

        workbook = Workbook(write_only=True)
        sheet = workbook.create_sheet("Attendance Adjustments")
        header = ["Employee ID", "Employee Name", "Department", "Designation"] + [f"{day:%d-%b-%Y} ({day:%A})" for day in dates]
        from openpyxl.cell import WriteOnlyCell
        styled_header = []
        for value in header:
            cell = WriteOnlyCell(sheet, value=value)
            cell.font = Font(bold=True, color="FFFFFF")
            cell.fill = PatternFill("solid", fgColor="172554")
            cell.alignment = Alignment(horizontal="center")
            styled_header.append(cell)
        sheet.append(styled_header)
        for column, width in (("A", 16), ("B", 28), ("C", 22), ("D", 24)):
            sheet.column_dimensions[column].width = width
        for index in range(5, len(header) + 1):
            sheet.column_dimensions[get_column_letter(index)].width = 17
        sheet.freeze_panes = "E2"
        for offset in range(0, employees.count(), 500):
            chunk = list(employees[offset:offset + 500])
            _, rows = _payload_for_employees(chunk, start, end)
            for row in rows:
                sheet.append([_excel_text(row["employee_code"]), _excel_text(row["employee_name"]), _excel_text(row["department"]), _excel_text(row["designation"])] + [cell["code"] for cell in row["cells"]])
        stream = BytesIO()
        workbook.save(stream)
        filename = f"Bulk_Attendance_Adjustments_{start:%Y-%m}.xlsx"
        response = HttpResponse(stream.getvalue(), content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        response["Content-Disposition"] = f'attachment; filename="{filename}"'
        response["Cache-Control"] = "no-store"
        return response
