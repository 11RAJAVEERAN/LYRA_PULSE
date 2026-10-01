from rest_framework.permissions import BasePermission

from .models import User


class HasModelPermission(BasePermission):
    """Use Django's Group and per-user permissions; SUPERADMIN bypasses checks."""
    permission_code = None

    def has_permission(self, request, view):
        user = request.user
        return bool(
            user and user.is_authenticated and user.is_active
            and (user.role == User.Role.SUPERADMIN or
                 (self.permission_code and user.has_perm(self.permission_code)))
        )


class IsSuperAdmin(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.is_active and user.role == User.Role.SUPERADMIN)


class IsEmployee(BasePermission):
    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.is_active and user.role == User.Role.EMPLOYEE)


class IsHROrAdmin(BasePermission):
    """Compatibility permission for views that need employee read access."""
    def has_permission(self, request, view):
        user = request.user
        return bool(user and user.is_authenticated and user.is_active and (
            user.role == User.Role.SUPERADMIN or user.has_perm("employees.view_employee")
        ))


class CanViewEmployees(HasModelPermission):
    permission_code = "employees.view_employee"


class CanAddEmployees(HasModelPermission):
    permission_code = "employees.add_employee"


class CanChangeEmployees(HasModelPermission):
    permission_code = "employees.change_employee"
