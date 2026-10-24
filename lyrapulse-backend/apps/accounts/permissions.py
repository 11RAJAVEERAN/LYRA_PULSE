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
        if not (user and user.is_authenticated and user.is_active and user.role == User.Role.SUPERADMIN):
            return False
        return bool(user.has_global_scope or (
            user.organization_id and user.organization and user.organization.is_active
        ))


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


def can_view_sensitive_employee_data(user):
    """Salary, bank details and legal documents: SUPERADMIN or an explicit group/user permission."""
    return bool(user and user.is_authenticated and user.is_active and (
        user.role == User.Role.SUPERADMIN or user.has_perm("employees.view_employee_sensitive")))


def can_change_sensitive_employee_data(user):
    return bool(user and user.is_authenticated and user.is_active and (
        user.role == User.Role.SUPERADMIN or user.has_perm("employees.change_employee_sensitive")))


class CanViewSensitiveEmployeeData(BasePermission):
    def has_permission(self, request, view):
        return can_view_sensitive_employee_data(request.user)


class CanChangeSensitiveEmployeeData(BasePermission):
    def has_permission(self, request, view):
        return can_change_sensitive_employee_data(request.user)
