"""Scoped administrative API for per-employee attendance permissions."""
from django.db import transaction
from django.db.models import Prefetch, Q
from rest_framework import serializers
from rest_framework.exceptions import NotFound, PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.accounts.scope import scope_queryset
from apps.common.responses import success_response
from apps.fingerprints.models import EmployeeFingerprint

from .models import AttendancePermissionAudit, Employee


PERMISSION_FIELDS = (
    "mobile_gps_attendance_enabled",
    "photo_attendance_enabled",
    "location_attendance_enabled",
    "biometric_attendance_enabled",
    "auto_punch_out_enabled",
)


class PermissionUpdateSerializer(serializers.Serializer):
    mobile_gps_attendance_enabled = serializers.BooleanField(required=False)
    photo_attendance_enabled = serializers.BooleanField(required=False)
    location_attendance_enabled = serializers.BooleanField(required=False)
    biometric_attendance_enabled = serializers.BooleanField(required=False)
    auto_punch_out_enabled = serializers.BooleanField(required=False)

    def to_internal_value(self, data):
        unknown = set(data) - set(PERMISSION_FIELDS) if isinstance(data, dict) else set()
        if unknown:
            raise serializers.ValidationError({key: "Unknown attendance permission." for key in unknown})
        return super().to_internal_value(data)

    def validate(self, attrs):
        if not attrs:
            raise serializers.ValidationError("Provide at least one attendance permission to update.")
        return attrs


def _admin_allowed(user):
    if user.role not in (user.Role.SUPERADMIN, user.Role.ADMIN):
        raise PermissionDenied("Only Super Admin and Admin users can manage attendance permissions.")


def _scoped_employees(user):
    return scope_queryset(
        Employee.objects.select_related("user", "branch", "designation", "department").prefetch_related(
            Prefetch("fingerprints", queryset=EmployeeFingerprint.objects.filter(is_active=True, device__is_active=True).select_related("device", "device__branch"))
        ),
        user,
        "branch",
    )


def _representation(employee):
    devices = []
    seen = set()
    for fingerprint in employee.fingerprints.all():
        device = fingerprint.device
        if device.pk not in seen:
            seen.add(device.pk)
            devices.append({"id": device.pk, "name": device.name or device.device_id, "branch": device.branch.name})
    data = {
        "id": employee.pk,
        "employee_code": employee.employee_code,
        "name": employee.display_name or employee.user.full_name,
        "role": employee.designation.name if employee.designation_id else "",
        "branch": {"id": employee.branch_id, "name": employee.branch.name} if employee.branch_id else None,
        "attendance_method": " + ".join(
            label for enabled, label in (
                (employee.mobile_gps_attendance_enabled, "Mobile"),
                (employee.biometric_attendance_enabled, "Biometric"),
            ) if enabled
        ) or "None",
        "biometric_devices": devices,
    }
    data.update({field: getattr(employee, field) for field in PERMISSION_FIELDS})
    return data


def _save_permissions(employee, actor, values):
    previous = {field: getattr(employee, field) for field in values}
    changed = {field: value for field, value in values.items() if previous[field] != value}
    if not changed:
        return False
    for field, value in changed.items():
        setattr(employee, field, value)
    employee.save(update_fields=(*changed.keys(), "updated_at"))
    AttendancePermissionAudit.objects.create(
        employee=employee,
        actor=actor,
        previous_values={field: previous[field] for field in changed},
        new_values=changed,
    )
    return True


class AttendancePermissionListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        _admin_allowed(request.user)
        queryset = _scoped_employees(request.user).filter(is_active=True)
        branch_id = request.query_params.get("branch")
        if branch_id:
            queryset = queryset.filter(branch_id=branch_id)
        search = request.query_params.get("search", "").strip()
        if search:
            queryset = queryset.filter(
                Q(employee_code__icontains=search)
                | Q(display_name__icontains=search)
                | Q(user__first_name__icontains=search)
                | Q(user__last_name__icontains=search)
            )
        method = request.query_params.get("method")
        if method == "mobile":
            queryset = queryset.filter(mobile_gps_attendance_enabled=True)
        elif method == "biometric":
            queryset = queryset.filter(biometric_attendance_enabled=True)
        elif method == "none":
            queryset = queryset.filter(mobile_gps_attendance_enabled=False, biometric_attendance_enabled=False)
        elif method not in (None, "", "all"):
            raise serializers.ValidationError({"method": "Use mobile, biometric, none, or all."})

        try:
            page = max(int(request.query_params.get("page", 1)), 1)
            page_size = min(max(int(request.query_params.get("page_size", 25)), 1), 100)
        except (TypeError, ValueError):
            raise serializers.ValidationError({"page": "Page and page_size must be integers."}) from None
        count = queryset.count()
        rows = queryset.order_by("employee_code")[(page - 1) * page_size:page * page_size]
        return success_response({"results": [_representation(row) for row in rows], "count": count,
                                 "page": page, "page_size": page_size})


class AttendancePermissionDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get_object(self, request, pk, *, lock=False):
        _admin_allowed(request.user)
        queryset = _scoped_employees(request.user)
        if lock:
            # This queryset joins nullable relations for the response payload. Lock only
            # Employee so PostgreSQL does not attempt to lock the nullable side of a JOIN.
            queryset = queryset.select_for_update(of=("self",))
        try:
            return queryset.get(pk=pk)
        except Employee.DoesNotExist:
            raise NotFound("Employee not found in your branch scope.") from None

    def get(self, request, pk):
        return success_response(_representation(self.get_object(request, pk)))

    def patch(self, request, pk):
        serializer = PermissionUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        with transaction.atomic():
            employee = self.get_object(request, pk, lock=True)
            _save_permissions(employee, request.user, serializer.validated_data)
        return success_response(_representation(employee), "Attendance permissions updated.")


class AttendancePermissionBulkView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        _admin_allowed(request.user)
        employee_ids = request.data.get("employee_ids")
        if (not isinstance(employee_ids, list) or not employee_ids or len(employee_ids) > 200
                or any(isinstance(value, bool) or not isinstance(value, int) or value < 1 for value in employee_ids)):
            raise serializers.ValidationError({"employee_ids": "Provide between 1 and 200 employee IDs."})
        if len(set(map(str, employee_ids))) != len(employee_ids):
            raise serializers.ValidationError({"employee_ids": "Employee IDs must be unique."})
        serializer = PermissionUpdateSerializer(data=request.data.get("permissions", {}))
        serializer.is_valid(raise_exception=True)
        with transaction.atomic():
            rows = list(
                _scoped_employees(request.user)
                .select_for_update(of=("self",))
                .filter(pk__in=employee_ids)
                .order_by("pk")
            )
            if len(rows) != len(employee_ids):
                raise NotFound("One or more employees were not found in your branch scope.")
            for employee in rows:
                _save_permissions(employee, request.user, serializer.validated_data)
        return success_response({"updated": len(rows)}, "Attendance permissions updated for selected employees.")
