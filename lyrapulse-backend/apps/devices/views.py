import re
import secrets
from datetime import timedelta

from django.conf import settings
from django.db import IntegrityError, transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.permissions import CanViewEmployees
from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch
from apps.common.responses import success_response

from .authentication import DeviceTokenAuthentication
from .models import Device
from .permissions import IsAuthenticatedDevice


def _device_status(device, now=None):
    if device.last_seen is None:
        return "Offline"
    now = now or timezone.now()
    threshold = timedelta(seconds=settings.DEVICE_ONLINE_THRESHOLD_SECONDS)
    return "Online" if device.last_seen >= now - threshold else "Offline"


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
            "last_seen": d.last_seen, "status": _device_status(d)} for d in devices])

    def post(self, request):
        self._require_device_manager(request.user)
        device_id = str(request.data.get("device_id", ""))
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,99}", device_id):
            raise ValidationError({"device_id": "Use 1-100 letters, digits, dots, underscores or hyphens."})
        branch = None
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
                if Device.objects.filter(branch=branch).exists():
                    raise ValidationError({
                        "branch_id": "This branch already has a registered fingerprint device."
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
            if branch is not None and Device.objects.filter(branch_id=branch.pk).exists():
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
            Device.objects.select_for_update().select_related("branch__organization").filter(
                branch__is_active=True,
                branch__organization__is_active=True,
            ),
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
        updated = Device.objects.filter(
            pk=request.user.pk,
            device_id=device_id,
            is_active=True,
            branch__is_active=True,
            branch__organization__is_active=True,
        ).update(last_seen=now)
        if not updated:
            raise PermissionDenied("Device, branch, or organization is inactive.")
        return success_response(
            {"device_id": device_id, "last_seen": now, "status": "Online"},
            "Device heartbeat recorded.",
        )
