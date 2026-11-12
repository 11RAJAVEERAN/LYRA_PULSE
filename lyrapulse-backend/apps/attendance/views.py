import hashlib
import json
import mimetypes
import re

from django.http import FileResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import serializers, status
from drf_spectacular.utils import OpenApiParameter, OpenApiResponse, extend_schema, inline_serializer
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.scope import scope_queryset
from apps.accounts.permissions import CanViewEmployees, IsEmployee
from apps.common.responses import success_response

from . import services
from .exceptions import AttendanceError
from .models import Attendance, AttendanceEvent
from .serializers import (
    AttendanceActionSerializer, AttendanceHistorySerializer, CheckInResultSerializer, CheckOutResultSerializer,
    LocationSerializer, TodayStateSerializer, VerifyLocationResultSerializer,
)


def _envelope(name, data_serializer):
    return inline_serializer(name=name, fields={
        "success": serializers.BooleanField(), "message": serializers.CharField(), "data": data_serializer,
    })


_ERROR = inline_serializer(name="AttendanceErrorResponse", fields={
    "success": serializers.BooleanField(),
    "message": serializers.CharField(),
    "errors": serializers.DictField(help_text="Field errors, or {code, ...} for business errors such as OUTSIDE_ATTENDANCE_RADIUS."),
})
_COMMON_ERRORS = {
    401: OpenApiResponse(_ERROR, description="Authentication required"),
    403: OpenApiResponse(_ERROR, description="Employee role required, no active employee profile, no valid branch, or outside radius"),
    409: OpenApiResponse(_ERROR, description="Branch location not configured, or the action conflicts with today's attendance state"),
}


class AttendanceAPIView(APIView):
    """Employee-only. The employee is always request.user's profile and the branch is always chosen by the server."""
    permission_classes = [IsAuthenticated, IsEmployee]

    def handle_exception(self, exc):
        if isinstance(exc, AttendanceError):
            return Response(
                {"success": False, "message": exc.message, "errors": {"code": exc.code, **exc.extra}},
                status=exc.status_code,
            )
        return super().handle_exception(exc)

    def employee_and_branch(self, request):
        employee = services.resolve_employee(request.user)
        if not employee.mobile_gps_attendance_enabled:
            raise AttendanceError("MOBILE_ATTENDANCE_DISABLED", "Mobile GPS attendance is not enabled for this employee.", 403)
        return employee, services.resolve_branch(employee)


class VerifyLocationView(AttendanceAPIView):
    """Pre-camera UX check only. It is NOT an authorisation: check-in and check-out verify the location again."""
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    @extend_schema(
        request=LocationSerializer,
        responses={200: _envelope("VerifyLocationResponse", VerifyLocationResultSerializer),
                   400: OpenApiResponse(_ERROR, description="Invalid latitude, longitude or accuracy"), **_COMMON_ERRORS},
        description="Checks timestamped device location against the authenticated employee's branch. GPS accuracy must be no worse than the branch radius. Returns 200 with `verified=false` when outside the radius.",
    )
    def post(self, request):
        employee, branch = self.employee_and_branch(request)
        if not employee.location_attendance_enabled:
            data = VerifyLocationResultSerializer({
            "verified": None,
                "branch": {"id": branch.pk, "name": branch.name},
                "distance_meters": None,
                "allowed_radius_meters": None,
                "accuracy_meters": None,
            }).data
            return success_response(data, "Location verification is not required for this employee.")
        serializer = LocationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        result = services.verify_attendance_location(branch, **serializer.validated_data)
        data = VerifyLocationResultSerializer({
            "verified": result.verified, "branch": {"id": branch.pk, "name": branch.name},
            "distance_meters": result.distance_meters, "allowed_radius_meters": result.allowed_radius_meters,
            "accuracy_meters": result.accuracy_meters,
        }).data
        message = "Location verified." if result.verified else "You are outside the allowed attendance area."
        return success_response(data, message)


class CheckInView(AttendanceAPIView):
    parser_classes = [MultiPartParser, FormParser]

    @extend_schema(
        request={"multipart/form-data": AttendanceActionSerializer},
        parameters=[OpenApiParameter(
            "Idempotency-Key", str, OpenApiParameter.HEADER, required=False,
            description="Optional stable key for retry-safe duplicate requests.",
        )],
        responses={201: _envelope("CheckInResponse", inline_serializer(name="CheckInData", fields={"attendance": CheckInResultSerializer()})),
                   400: OpenApiResponse(_ERROR, description="Invalid coordinates, accuracy or photo"), **_COMMON_ERRORS},
        description="Opens a new session using SERVER time. Timestamped location is re-verified; employee_id/branch_id/time in the request are ignored.",
    )
    def post(self, request):
        employee, branch = self.employee_and_branch(request)
        payload = request.data.copy()
        if not employee.photo_attendance_enabled:
            payload.pop("photo", None)
        if not employee.location_attendance_enabled:
            for field in ("latitude", "longitude", "accuracy", "location_timestamp"):
                payload.pop(field, None)
        serializer = AttendanceActionSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        if employee.photo_attendance_enabled and not serializer.validated_data.get("photo"):
            raise AttendanceError("PHOTO_REQUIRED", "A photo is required for this attendance action.", 400)
        return _submit_mobile_punch(
            request, employee, serializer, action=AttendanceEvent.Action.CHECK_IN,
            success_message="Check-in successful.", success_status=status.HTTP_201_CREATED,
            result_serializer=CheckInResultSerializer,
            perform=lambda: services.check_in(
                employee=employee, branch=branch,
                location_required=employee.location_attendance_enabled, **serializer.validated_data,
            ),
        )


class CheckOutView(AttendanceAPIView):
    parser_classes = [MultiPartParser, FormParser]

    @extend_schema(
        request={"multipart/form-data": AttendanceActionSerializer},
        parameters=[OpenApiParameter(
            "Idempotency-Key", str, OpenApiParameter.HEADER, required=False,
            description="Optional stable key for retry-safe duplicate requests.",
        )],
        responses={200: _envelope("CheckOutResponse", inline_serializer(name="CheckOutData", fields={"attendance": CheckOutResultSerializer()})),
                   400: OpenApiResponse(_ERROR, description="Invalid coordinates, accuracy or photo"), **_COMMON_ERRORS},
        description="Closes the employee's currently open session using SERVER time. Timestamped location is re-verified.",
    )
    def post(self, request):
        employee, branch = self.employee_and_branch(request)
        payload = request.data.copy()
        if not employee.photo_attendance_enabled:
            payload.pop("photo", None)
        if not employee.location_attendance_enabled:
            for field in ("latitude", "longitude", "accuracy", "location_timestamp"):
                payload.pop(field, None)
        serializer = AttendanceActionSerializer(data=payload)
        serializer.is_valid(raise_exception=True)
        if employee.photo_attendance_enabled and not serializer.validated_data.get("photo"):
            raise AttendanceError("PHOTO_REQUIRED", "A photo is required for this attendance action.", 400)
        return _submit_mobile_punch(
            request, employee, serializer, action=AttendanceEvent.Action.CHECK_OUT,
            success_message="Check-out successful.", success_status=status.HTTP_200_OK,
            result_serializer=CheckOutResultSerializer,
            perform=lambda: services.check_out(
                employee=employee, branch=branch,
                location_required=employee.location_attendance_enabled, **serializer.validated_data,
            ),
        )


class TodayAttendanceView(AttendanceAPIView):
    @extend_schema(
        responses={200: _envelope("TodayAttendanceResponse", TodayStateSerializer), **_COMMON_ERRORS},
        description="Today's attendance state (application time zone): NOT_CHECKED_IN, CHECKED_IN or CHECKED_OUT.",
    )
    def get(self, request):
        employee = services.resolve_employee(request.user)
        return success_response(TodayStateSerializer(services.today_state(employee)).data)


def _request_fingerprint(validated_data):
    payload: dict[str, float | str] = {}
    for field in ("latitude", "longitude", "accuracy"):
        if field in validated_data:
            payload[field] = float(validated_data[field])
    if "location_timestamp" in validated_data:
        payload["location_timestamp"] = validated_data["location_timestamp"].isoformat()
    photo = validated_data.get("photo")
    if photo is not None:
        photo.seek(0)
        photo_hash = hashlib.sha256()
        for chunk in photo.chunks():
            photo_hash.update(chunk)
        photo.seek(0)
        payload["photo_sha256"] = photo_hash.hexdigest()
    return hashlib.sha256(json.dumps(payload, sort_keys=True, separators=(",", ":"), allow_nan=False).encode()).hexdigest()


def _submit_mobile_punch(request, employee, serializer, *, action, success_message, success_status, result_serializer, perform):
    key = request.headers.get("Idempotency-Key")
    if key is not None and not re.fullmatch(r"[\x21-\x7e]{1,128}", key):
        raise serializers.ValidationError({"Idempotency-Key": ["Provide 1 to 128 printable non-space ASCII characters."]})

    if key is None:
        attendance = perform()
        return success_response(
            {"attendance": result_serializer(attendance).data},
            success_message,
            success_status,
        )

    outcome = services.idempotent_mobile_punch(
        key=key,
        employee=employee,
        action=action,
        payload_fingerprint=_request_fingerprint(serializer.validated_data),
        perform=perform,
        serialize_result=lambda attendance: dict(result_serializer(attendance).data),
        success_message=success_message,
        success_status=success_status,
    )
    return Response(outcome.body, status=outcome.status_code)


class AttendanceHistoryQuerySerializer(serializers.Serializer):
    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)
    page = serializers.IntegerField(required=False, min_value=1, default=1)
    page_size = serializers.IntegerField(required=False, min_value=1, max_value=100, default=31)

    def validate(self, attrs):
        start, end = attrs.get("start_date"), attrs.get("end_date")
        if start and end and start > end:
            raise serializers.ValidationError({"start_date": "Must be on or before end_date."})
        return attrs


class EmployeeAttendanceHistoryView(AttendanceAPIView):
    @extend_schema(
        responses={200: _envelope("EmployeeAttendanceHistoryResponse", inline_serializer(
            name="EmployeeAttendanceHistoryData",
            fields={
                "count": serializers.IntegerField(),
                "page": serializers.IntegerField(),
                "page_size": serializers.IntegerField(),
                "has_next": serializers.BooleanField(),
                "results": AttendanceHistorySerializer(many=True),
            },
        )), 400: OpenApiResponse(_ERROR), **_COMMON_ERRORS},
        description="Paginated attendance sessions for the authenticated employee only.",
    )
    def get(self, request):
        employee = services.resolve_employee(request.user)
        query = AttendanceHistoryQuerySerializer(data=request.query_params)
        query.is_valid(raise_exception=True)
        values = query.validated_data
        today = timezone.localdate()
        end_date = values.get("end_date", today)
        start_date = values.get("start_date", end_date.replace(day=1))
        if start_date > end_date:
            raise serializers.ValidationError({"start_date": "Must be on or before end_date."})
        page, page_size = values["page"], values["page_size"]
        rows = Attendance.objects.filter(
            employee=employee,
            attendance_date__gte=start_date,
            attendance_date__lte=end_date,
        ).select_related("branch").order_by("-attendance_date", "-check_in_at", "-pk")
        count = rows.count()
        offset = (page - 1) * page_size
        page_rows = rows[offset:offset + page_size]
        data = {
            "count": count,
            "page": page,
            "page_size": page_size,
            "has_next": offset + page_size < count,
            "results": AttendanceHistorySerializer(page_rows, many=True).data,
        }
        return success_response(data, "Attendance history retrieved.")


class AttendancePhotoView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, attendance_id, kind):
        if kind not in {"check-in", "check-out"}:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)

        rows = Attendance.objects.select_related("employee__branch")
        if request.user.role == User.Role.EMPLOYEE:
            employee = services.resolve_employee(request.user)
            rows = rows.filter(employee=employee)
        elif CanViewEmployees().has_permission(request, self):
            rows = scope_queryset(rows, request.user, "employee__branch")
        else:
            raise PermissionDenied

        attendance = get_object_or_404(rows, pk=attendance_id)
        photo = attendance.check_in_photo if kind == "check-in" else attendance.check_out_photo
        if not photo:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        try:
            photo.open("rb")
        except FileNotFoundError:
            return Response({"detail": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        content_type = mimetypes.guess_type(photo.name)[0] or "application/octet-stream"
        response = FileResponse(photo, content_type=content_type)
        response["Cache-Control"] = "private, no-store"
        response["X-Content-Type-Options"] = "nosniff"
        response["Content-Disposition"] = 'inline; filename="attendance-photo"'
        return response
