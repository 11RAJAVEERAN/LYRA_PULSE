from drf_spectacular.utils import OpenApiResponse, extend_schema, inline_serializer
from rest_framework import serializers, status
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.permissions import IsEmployee
from apps.common.responses import success_response

from . import services
from .exceptions import AttendanceError
from .serializers import (
    AttendanceActionSerializer, CheckInResultSerializer, CheckOutResultSerializer, LocationSerializer,
    TodayStateSerializer, VerifyLocationResultSerializer,
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
        return employee, services.resolve_branch(employee)


class VerifyLocationView(AttendanceAPIView):
    """Pre-camera UX check only. It is NOT an authorisation: check-in and check-out verify the location again."""
    parser_classes = [JSONParser, FormParser, MultiPartParser]

    @extend_schema(
        request=LocationSerializer,
        responses={200: _envelope("VerifyLocationResponse", VerifyLocationResultSerializer),
                   400: OpenApiResponse(_ERROR, description="Invalid latitude, longitude or accuracy"), **_COMMON_ERRORS},
        description="Checks the device location against the authenticated employee's branch. Returns 200 with `verified=false` when outside the radius.",
    )
    def post(self, request):
        employee, branch = self.employee_and_branch(request)
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
        responses={201: _envelope("CheckInResponse", inline_serializer(name="CheckInData", fields={"attendance": CheckInResultSerializer()})),
                   400: OpenApiResponse(_ERROR, description="Invalid coordinates, accuracy or photo"), **_COMMON_ERRORS},
        description="Creates today's attendance record using SERVER time. Location is re-verified; employee_id/branch_id/time in the request are ignored.",
    )
    def post(self, request):
        employee, branch = self.employee_and_branch(request)
        serializer = AttendanceActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        attendance = services.check_in(employee=employee, branch=branch, **serializer.validated_data)
        return success_response({"attendance": CheckInResultSerializer(attendance).data}, "Check-in successful.", status.HTTP_201_CREATED)


class CheckOutView(AttendanceAPIView):
    parser_classes = [MultiPartParser, FormParser]

    @extend_schema(
        request={"multipart/form-data": AttendanceActionSerializer},
        responses={200: _envelope("CheckOutResponse", inline_serializer(name="CheckOutData", fields={"attendance": CheckOutResultSerializer()})),
                   400: OpenApiResponse(_ERROR, description="Invalid coordinates, accuracy or photo"), **_COMMON_ERRORS},
        description="Completes today's existing attendance record (no new row) using SERVER time. Location is re-verified.",
    )
    def post(self, request):
        employee, branch = self.employee_and_branch(request)
        serializer = AttendanceActionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        attendance = services.check_out(employee=employee, branch=branch, **serializer.validated_data)
        return success_response({"attendance": CheckOutResultSerializer(attendance).data}, "Check-out successful.")


class TodayAttendanceView(AttendanceAPIView):
    @extend_schema(
        responses={200: _envelope("TodayAttendanceResponse", TodayStateSerializer), **_COMMON_ERRORS},
        description="Today's attendance state (application time zone): NOT_CHECKED_IN, CHECKED_IN or CHECKED_OUT.",
    )
    def get(self, request):
        employee = services.resolve_employee(request.user)
        return success_response(TodayStateSerializer(services.today_state(employee)).data)
