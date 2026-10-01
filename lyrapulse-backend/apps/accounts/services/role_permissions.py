from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group, Permission

User = get_user_model()

ROLE_PERMISSION_CODES = {
    User.Role.ADMIN: {"employees.view_employee", "employees.add_employee", "employees.change_employee"},
    User.Role.HR: {"employees.view_employee", "employees.add_employee", "employees.change_employee"},
    User.Role.MANAGER: {"employees.view_employee"},
}


def ensure_role_group(role):
    group, _ = Group.objects.get_or_create(name=role)
    for permission_code in ROLE_PERMISSION_CODES.get(role, set()):
        app_label, codename = permission_code.split(".", 1)
        permission = Permission.objects.filter(
            content_type__app_label=app_label,
            codename=codename,
        ).first()
        if permission:
            group.permissions.add(permission)
    return group


def sync_existing_role_groups():
    for role in ROLE_PERMISSION_CODES:
        group = ensure_role_group(role)
        for user in User.objects.filter(role=role).exclude(groups=group):
            user.groups.add(group)