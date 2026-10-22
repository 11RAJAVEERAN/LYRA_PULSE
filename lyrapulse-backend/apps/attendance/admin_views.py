"""Admin Attendance APIs (read-only, additive). The mobile check-in/check-out views are not touched.

Access = the project's existing rules: JWT + the `employees.view_employee` permission (ADMIN / HR / MANAGER roles
get it from their role group; SUPERADMIN always) + `scope_queryset` organization/branch scoping. EMPLOYEE-role
users have no such permission and get 403.
"""
import csv
import json

from django.http import StreamingHttpResponse
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, OpenApiResponse, extend_schema
from rest_framework.exceptions import NotFound
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from apps.accounts.permissions import CanViewEmployees
from apps.common.responses import success_response

from . import admin_services as services
from .admin_serializers import (
    AdminAttendanceDetailSerializer, AdminAttendanceRowSerializer, DetailQuerySerializer, ExportQuerySerializer,
    ListQuerySerializer, SummaryQuerySerializer, employee_name, media_url,
)
from .pagination import AdminAttendancePagination

_FILTER_PARAMS = [
    OpenApiParameter("date", str, description="Single day (YYYY-MM-DD). Defaults to today. Not future."),
    OpenApiParameter("start_date", str, description="Range start (YYYY-MM-DD); requires end_date."),
    OpenApiParameter("end_date", str, description="Range end (YYYY-MM-DD); requires start_date."),
    OpenApiParameter("branch", int, description="Branch id (must be inside your scope)."),
    OpenApiParameter("department", int, description="Department id (must be inside your scope)."),
    OpenApiParameter("designation", int, description="Designation id (must be inside your scope)."),
    OpenApiParameter("search", str, description="Employee name or employee code."),
]
_STATUS_PARAM = OpenApiParameter("status", str, enum=["present", "absent"], description="Only present / absent are supported.")
_ORDERING_PARAM = OpenApiParameter(
    "ordering", str, description="attendance_date, employee_name, check_in, check_out (prefix - for descending). "
                                 "Rows stay grouped by date; non-date keys sort inside each date.",
)
_ERRORS = {
    400: OpenApiResponse(description="Invalid query parameter"),
    401: OpenApiResponse(description="Authentication required"),
    403: OpenApiResponse(description="Employee view permission required"),
}


class AdminAttendanceBaseView(APIView):
    permission_classes = [IsAuthenticated, CanViewEmployees]

    def query(self, serializer_class):
        serializer = serializer_class(data=self.request.query_params, context={"request": self.request})
        serializer.is_valid(raise_exception=True)
        return serializer


class AdminAttendanceListView(AdminAttendanceBaseView):
    @extend_schema(
        operation_id="attendance_admin_list",
        parameters=[*_FILTER_PARAMS, _STATUS_PARAM, _ORDERING_PARAM,
                    OpenApiParameter("page", int), OpenApiParameter("page_size", int, description="Default 25, max 100.")],
        responses={200: OpenApiResponse(description="Paginated attendance rows"), **_ERRORS},
        description="One row per employee per day (present AND absent employees). Absent rows are derived, not stored.",
    )
    def get(self, request):
        query = self.query(ListQuerySerializer)
        start, end = query.validated_data["start_date"], query.validated_data["end_date"]
        filters = query.filters()
        newest_first = not filters.ordering == "attendance_date"
        rows = services.AttendanceRowSequence(request.user, services.days_in_range(start, end, newest_first), filters)

        paginator = AdminAttendancePagination()
        page = paginator.paginate_queryset(rows, request, view=self)
        data = AdminAttendanceRowSerializer(page, many=True, context={"request": request}).data
        return paginator.get_paginated_response(data, extra={"start_date": start, "end_date": end})


class AdminAttendanceSummaryView(AdminAttendanceBaseView):
    @extend_schema(
        operation_id="attendance_admin_summary",
        parameters=_FILTER_PARAMS,
        responses={200: OpenApiResponse(description="total_employees, present, absent"), **_ERRORS},
        description="Counts for the caller's scope. Single date = per-day counts; a range counts distinct employees "
                    "(present = at least one attendance record in the range). `status` is not applicable here.",
    )
    def get(self, request):
        query = self.query(SummaryQuerySerializer)
        start, end = query.validated_data["start_date"], query.validated_data["end_date"]
        counts = services.build_summary(request.user, start, end, query.filters())
        return success_response({"date": start if start == end else None, "start_date": start, "end_date": end, **counts})


class AdminAttendanceDetailView(AdminAttendanceBaseView):
    @extend_schema(
        operation_id="attendance_admin_detail",
        parameters=[OpenApiParameter("date", str, description="YYYY-MM-DD. Defaults to today.")],
        responses={200: OpenApiResponse(description="Employee attendance detail"),
                   404: OpenApiResponse(description="Employee not found in your scope"), **_ERRORS},
        description="Detail panel data: check-in/check-out time, GPS, accuracy, distance, verification and photo URLs. "
                    "An absent employee returns status ABSENT with null check_in / check_out.",
    )
    def get(self, request, employee_id):
        query = self.query(DetailQuerySerializer)
        day = query.validated_data.get("date") or timezone.localdate()
        row = services.get_day_row(request.user, employee_id, day)
        if row is None:
            raise NotFound("Employee not found.")
        return success_response(AdminAttendanceDetailSerializer(row, context={"request": request}).data)


# ----------------------------------------------------------------------------------------------------------------
# CSV export
# ----------------------------------------------------------------------------------------------------------------
CSV_HEADER = [
    "Date", "Employee ID", "Employee Name", "Branch", "Department", "Designation", "Status",
    "Check In", "Check Out", "Working Hours",
    "Check-in Latitude", "Check-in Longitude", "Check-in Accuracy (m)", "Check-in Distance (m)",
    "Check-in Verified", "Check-in Photo",
    "Check-out Latitude", "Check-out Longitude", "Check-out Accuracy (m)", "Check-out Distance (m)",
    "Check-out Verified", "Check-out Photo",
    "Session Count", "Sessions JSON",
]


class _Echo:
    def write(self, value):
        return value


def _text(value):
    """Neutralise spreadsheet formula injection in free-text cells (names, codes, branch/department names)."""
    value = "" if value is None else str(value)
    return "'" + value if value[:1] in ("=", "+", "-", "@", "\t", "\r") else value


def _local(moment):
    return "" if moment is None else timezone.localtime(moment).strftime("%Y-%m-%d %H:%M:%S")


def _yes_no(value):
    return "" if value is None else ("Yes" if value else "No")


def _plain(value):
    return "" if value is None else value


def csv_row(row, request):
    employee, attendance = row.employee, row.attendance
    has_out = attendance is not None and attendance.check_out_at is not None
    return [
        row.attendance_date.isoformat(), _text(employee.employee_code), _text(employee_name(employee)),
        _text(employee.branch.name if employee.branch else ""),
        _text(employee.department.name if employee.department else ""),
        _text(employee.designation.name if employee.designation else ""),
        row.status,
        _local(attendance.check_in_at) if attendance else "",
        _local(attendance.check_out_at) if attendance else "",
        _plain(services.format_duration(services.total_working_seconds(row.sessions))),
        _plain(attendance.check_in_latitude) if attendance else "",
        _plain(attendance.check_in_longitude) if attendance else "",
        _plain(attendance.check_in_accuracy) if attendance else "",
        _plain(attendance.check_in_distance_meters) if attendance else "",
        _yes_no(attendance.check_in_location_verified) if attendance else "",
        _plain(media_url(request, attendance.check_in_photo)) if attendance else "",
        _plain(attendance.check_out_latitude) if has_out else "",
        _plain(attendance.check_out_longitude) if has_out else "",
        _plain(attendance.check_out_accuracy) if has_out else "",
        _plain(attendance.check_out_distance_meters) if has_out else "",
        _yes_no(attendance.check_out_location_verified) if has_out else "",
        _plain(media_url(request, attendance.check_out_photo)) if has_out else "",
        len(row.sessions),
        json.dumps([{"check_in": _local(s.check_in_at), "check_out": _local(s.check_out_at), "source": s.source,
                     "actions": [{"action": action.action, "method": action.method, "actor_id": action.actor_id, "at": _local(action.occurred_at)} for action in s.actions.all()],
                     "working_seconds": services.working_seconds(s)} for s in row.sessions], separators=(",", ":")),
    ]


class AdminAttendanceExportView(AdminAttendanceBaseView):
    @extend_schema(
        operation_id="attendance_admin_export",
        parameters=[*_FILTER_PARAMS, _STATUS_PARAM, _ORDERING_PARAM],
        responses={(200, "text/csv"): OpenApiResponse(description="CSV attachment"), **_ERRORS},
        description="CSV of the same rows the list returns (same filters and scope, not paginated). One row per "
                    "employee per day. Only factual columns: no late / early / overtime.",
    )
    def get(self, request):
        query = self.query(ExportQuerySerializer)
        start, end = query.validated_data["start_date"], query.validated_data["end_date"]
        filters = query.filters()
        days = services.days_in_range(start, end, newest_first=filters.ordering == "-attendance_date")

        def stream():
            writer = csv.writer(_Echo())
            yield "﻿" + writer.writerow(CSV_HEADER)  # BOM so Excel reads UTF-8 (e.g. Tamil names) correctly
            for row in services.iter_rows(request.user, days, filters):
                yield writer.writerow(csv_row(row, request))

        response = StreamingHttpResponse(stream(), content_type="text/csv; charset=utf-8")
        response["Content-Disposition"] = f'attachment; filename="attendance-report-{start.isoformat()}-to-{end.isoformat()}.csv"'
        response["Cache-Control"] = "no-store"
        return response
