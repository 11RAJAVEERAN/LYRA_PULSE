import re
import secrets
from datetime import timedelta

from django.conf import settings
from django.db import IntegrityError, transaction
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied, Throttled, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework import serializers
from rest_framework.settings import api_settings

from apps.accounts.models import User
from apps.accounts.permissions import CanViewEmployees
from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch
from apps.common.responses import success_response

from .authentication import DeviceTokenAuthentication
from .models import Device, DeviceDiagnosticLog
from .permissions import IsAuthenticatedDevice


def _device_status(device, now=None):
    if device.last_seen is None:
        return "Offline"
    now = now or timezone.now()
    threshold = timedelta(seconds=settings.DEVICE_ONLINE_THRESHOLD_SECONDS)
    return "Online" if device.last_seen >= now - threshold else "Offline"


class DeviceHealthSerializer(serializers.Serializer):
    sensor_ready = serializers.BooleanField(required=False)
    wifi_rssi = serializers.IntegerField(required=False, min_value=-127, max_value=0)
    free_heap = serializers.IntegerField(required=False, min_value=0)
    pending_events = serializers.IntegerField(required=False, min_value=0)
    firmware_version = serializers.CharField(required=False, max_length=40)
    health_status = serializers.ChoiceField(required=False, choices=("HEALTHY", "DEGRADED", "ERROR"))


class DeviceDiagnosticSerializer(serializers.Serializer):
    severity = serializers.ChoiceField(choices=("INFO", "WARNING", "ERROR"), default="ERROR")
    code = serializers.RegexField(r"^[A-Z0-9_]{1,64}$")
    subsystem = serializers.RegexField(r"^[A-Za-z0-9_.-]{1,40}$")
    message = serializers.CharField(required=False, allow_blank=True, max_length=240)
    details = serializers.DictField(required=False, default=dict)

    def validate_details(self, value):
        if len(value) > 8:
            raise serializers.ValidationError("At most 8 diagnostic detail fields are accepted.")
        for key, item in value.items():
            if not isinstance(key, str) or len(key) > 40:
                raise serializers.ValidationError("Diagnostic detail keys must be short strings.")
            if isinstance(item, (dict, list)) or (item is not None and not isinstance(item, (str, int, float, bool))):
                raise serializers.ValidationError("Diagnostic detail values must be scalar.")
            if isinstance(item, str) and len(item) > 120:
                raise serializers.ValidationError("Diagnostic detail values must be at most 120 characters.")
        return value


class DeviceManagementView(APIView):
    permission_classes = [IsAuthenticated, CanViewEmployees]

    @staticmethod
    def _require_device_manager(user):
        if (
            user.role not in (User.Role.SUPERADMIN, User.Role.ADMIN)
            or not user.has_active_company_access
        ):
            raise PermissionDenied("Only Super Admin and Branch Admin users can manage devices.")

    def get(self, request):
        self._require_device_manager(request.user)
        devices = scope_queryset(Device.objects.select_related("branch"), request.user, "branch")
        branch_id = request.query_params.get("branch")
        if branch_id:
            try:
                devices = devices.filter(branch_id=int(branch_id))
            except (TypeError, ValueError):
                devices = devices.none()
        devices = devices.order_by("device_id")
        return success_response([{"device_id": d.device_id, "name": d.name, "branch_id": d.branch_id,
            "branch_name": d.branch.name, "branch": d.branch.name, "is_active": d.is_active,
            "last_seen": d.last_seen, "status": _device_status(d),
            "health_status": d.health_status, "health_details": d.health_details,
            "last_health_report_at": d.last_health_report_at} for d in devices])

    def post(self, request):
        self._require_device_manager(request.user)
        device_id = str(request.data.get("device_id", ""))
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,99}", device_id):
            raise ValidationError({"device_id": "Use 1-100 letters, digits, dots, underscores or hyphens."})
        branch = None
        replaced_device_id = str(request.data.get("replace_device_id", "")).strip()
        try:
            with transaction.atomic():
                branch = get_object_or_404(
                    scope_queryset(
                        Branch.objects.select_for_update().filter(
                            is_active=True,
                            organization__is_active=True,
                        ),
                        request.user,
                        "id",
                    ),
                    pk=request.data.get("branch_id"),
                )
                if Device.objects.filter(device_id=device_id).exists():
                    raise ValidationError({"device_id": "A device with this ID already exists."})
                active_devices = Device.objects.select_for_update().filter(branch=branch, is_active=True)
                active_device = active_devices.first()
                if active_device:
                    if not replaced_device_id or active_device.device_id != replaced_device_id:
                        raise ValidationError({
                            "branch_id": "This branch already has an active device. Select it explicitly to replace it."
                        })
                    active_device.is_active = False
                    active_device.save(update_fields=("is_active", "updated_at"))
                elif replaced_device_id:
                    raise ValidationError({
                        "replace_device_id": "The selected replacement device is not the active device for this branch."
                    })
                token = secrets.token_urlsafe(32)
                device = Device(
                    device_id=device_id,
                    name=str(request.data.get("name", ""))[:150],
                    branch=branch,
                )
                device.set_token(token)
                device.save()
        except IntegrityError:
            if Device.objects.filter(device_id=device_id).exists():
                raise ValidationError({"device_id": "A device with this ID already exists."}) from None
            if branch is not None and Device.objects.filter(branch_id=branch.pk, is_active=True).exists():
                raise ValidationError({
                    "branch_id": "This branch already has a registered fingerprint device."
                }) from None
            raise
        return success_response({"device_id": device.device_id, "name": device.name, "branch_id": device.branch_id,
            "is_active": device.is_active, "provisioning_token": token},
            "Device provisioned. Copy the token now; it will not be shown again.", 201)

    def patch(self, request):
        self._require_device_manager(request.user)
        device = get_object_or_404(scope_queryset(Device.objects.select_related("branch"), request.user, "branch"), device_id=request.data.get("device_id"))
        if set(request.data.keys()) - {"device_id", "is_active", "name"}:
            raise ValidationError("Only device name and active state can be changed.")
        if "name" in request.data:
            device.name = str(request.data["name"])[:150]
        if "is_active" in request.data:
            if not isinstance(request.data["is_active"], bool):
                raise ValidationError({"is_active": "Must be a boolean."})
            device.is_active = request.data["is_active"]
        device.save(update_fields=("name", "is_active", "updated_at"))
        return success_response({"device_id": device.device_id, "name": device.name,
            "branch_id": device.branch_id, "is_active": device.is_active}, "Device updated.")


class DeviceTokenRotationView(APIView):
    permission_classes = [IsAuthenticated, CanViewEmployees]

    def post(self, request, device_id):
        DeviceManagementView._require_device_manager(request.user)
        devices = scope_queryset(
    Device.objects.select_for_update(of=("self",)).filter(
        branch__is_active=True,
    ).filter(Q(branch__organization__isnull=True) | Q(branch__organization__is_active=True)),
    request.user,
    "branch",
)
        with transaction.atomic():
            device = get_object_or_404(devices, device_id=device_id)
            token = secrets.token_urlsafe(32)
            device.set_token(token)
            device.save(update_fields=("token_hash", "updated_at"))
        return success_response(
            {"device_id": device.device_id, "rotated_token": token},
            "Device token rotated. Copy it now; it will not be shown again.",
        )


class DeviceHeartbeatView(APIView):
    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsAuthenticatedDevice]

    def post(self, request, device_id):
        now = timezone.now()
        serializer = DeviceHealthSerializer(data=request.data if request.data else {})
        serializer.is_valid(raise_exception=True)
        health = serializer.validated_data
        health_status = health.pop("health_status", "UNKNOWN")
        updated = Device.objects.filter(
            pk=request.user.pk,
            device_id=device_id,
            is_active=True,
            branch__is_active=True,
        ).filter(Q(branch__organization__isnull=True) | Q(branch__organization__is_active=True)).update(
            last_seen=now, last_health_report_at=now, health_status=health_status,
            health_details=health,
        )
        if not updated:
            raise PermissionDenied("Device, branch, or organization is inactive.")
        return success_response(
            {"device_id": device_id, "last_seen": now, "status": "Online"},
            "Device heartbeat recorded.",
        )


class DeviceDiagnosticView(APIView):
    authentication_classes = [DeviceTokenAuthentication, *api_settings.DEFAULT_AUTHENTICATION_CLASSES]

    def get_permissions(self):
        if self.request.method == "POST":
            return [IsAuthenticatedDevice()]
        return [IsAuthenticated(), CanViewEmployees()]

    def post(self, request, device_id):
        device = request.auth
        if device.device_id != device_id:
            raise PermissionDenied("The credential is not authorized for this device.")
        recent_count = DeviceDiagnosticLog.objects.filter(
            device=device, created_at__gte=timezone.now() - timedelta(minutes=1),
        ).count()
        if recent_count >= 10:
            raise Throttled(detail="Diagnostic rate limit reached; retry in one minute.")
        serializer = DeviceDiagnosticSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        item = DeviceDiagnosticLog.objects.create(device=device, **serializer.validated_data)
        return success_response({"id": item.pk, "received_at": item.created_at}, "Diagnostic recorded.", 201)

    def get(self, request, device_id):
        DeviceManagementView._require_device_manager(request.user)
        device = get_object_or_404(
            scope_queryset(Device.objects.all(), request.user, "branch"), device_id=device_id,
        )
        try:
            limit = min(max(int(request.query_params.get("limit", 50)), 1), 100)
            offset = max(int(request.query_params.get("offset", 0)), 0)
        except (TypeError, ValueError):
            raise ValidationError("limit and offset must be integers.") from None
        rows = DeviceDiagnosticLog.objects.filter(device=device).order_by("-created_at")[offset:offset + limit]
        return success_response([{
            "id": row.pk, "severity": row.severity, "code": row.code,
            "subsystem": row.subsystem, "message": row.message,
            "details": row.details, "created_at": row.created_at,
            "resolved_at": row.resolved_at,
        } for row in rows])
