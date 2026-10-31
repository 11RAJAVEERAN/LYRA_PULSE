from rest_framework.permissions import BasePermission

from apps.accounts.models import User


class _ShiftPermission(BasePermission):
    permission_code = None

    def has_permission(self, request, view):
        user = request.user
        return bool(
            user and user.is_authenticated and user.is_active
            and (user.role == User.Role.SUPERADMIN or user.has_perm(self.permission_code))
        )


class CanViewShiftManagement(_ShiftPermission):
    permission_code = "shifts.view_shift"


class CanManageShifts(_ShiftPermission):
    permission_code = "shifts.manage_shifts"


class CanAssignShifts(_ShiftPermission):
    permission_code = "shifts.assign_shiftassignment"

