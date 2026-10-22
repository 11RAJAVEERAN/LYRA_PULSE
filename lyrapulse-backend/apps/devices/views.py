import re
import secrets

from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView

from apps.accounts.models import User
from apps.accounts.permissions import CanViewEmployees
from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch
from apps.common.responses import success_response

from .models import Device


class DeviceManagementView(APIView):
    permission_classes = [IsAuthenticated, CanViewEmployees]

    def get(self, request):
        devices = scope_queryset(Device.objects.select_related("branch"), request.user, "branch").order_by("device_id")
        return success_response([{"device_id": d.device_id, "name": d.name, "branch_id": d.branch_id,
            "branch_name": d.branch.name, "is_active": d.is_active} for d in devices])

    def post(self, request):
        if request.user.role not in (User.Role.SUPERADMIN, User.Role.ADMIN):
            raise PermissionDenied("Only Super Admin and Admin users can provision devices.")
        device_id = str(request.data.get("device_id", ""))
        if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,99}", device_id):
            raise ValidationError({"device_id": "Use 1-100 letters, digits, dots, underscores or hyphens."})
        branch = get_object_or_404(scope_queryset(Branch.objects.filter(is_active=True), request.user, "id"), pk=request.data.get("branch_id"))
        if Device.objects.filter(device_id=device_id).exists():
            raise ValidationError({"device_id": "A device with this ID already exists."})
        token = secrets.token_urlsafe(32)
        device = Device(device_id=device_id, name=str(request.data.get("name", ""))[:150], branch=branch)
        device.set_token(token)
        device.save()
        return success_response({"device_id": device.device_id, "name": device.name, "branch_id": device.branch_id,
            "is_active": device.is_active, "provisioning_token": token},
            "Device provisioned. Copy the token now; it will not be shown again.", 201)

    def patch(self, request):
        if request.user.role not in (User.Role.SUPERADMIN, User.Role.ADMIN):
            raise PermissionDenied("Only Super Admin and Admin users can change devices.")
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
