"""Organization / branch scope rules shared by models, Django Admin, the admin-user API and employee views.

role   -> what a user can do
scope  -> where they can do it (organization + allowed branches)
"""
from django.core.exceptions import ValidationError


def validate_scope(role, organization, branches, require_organization=True):
    """Raise ValidationError (field-keyed) if role/organization/branches are inconsistent.

    A business user's organization is required by internal forms. The JSON API can
    still create an unscoped account for compatibility; it then sees no data until
    an organization and, for non-SUPERADMIN roles, allowed branches are assigned.
    """
    from .models import User

    errors = {}
    if require_organization and role in User.BUSINESS_ROLES and organization is None:
        errors["organization"] = "Organization is required for ADMIN, HR and MANAGER users."
    branches = list(branches)
    if branches:
        if organization is None:
            errors["allowed_branches"] = "Select an organization before assigning branches."
        else:
            outside = [str(b.name) for b in branches if b.organization_id != organization.pk]
            if outside:
                errors["allowed_branches"] = "These branches do not belong to the selected organization: " + ", ".join(outside)
    if errors:
        raise ValidationError(errors)


def scope_queryset(queryset, user, branch_lookup):
    """Restrict `queryset` to the user's scope. Only trusted platform superusers are global.

    `branch_lookup` is the ORM path to the branch, e.g. "branch", "department__branch", or "id" for Branch itself.
    """
    if user.has_global_scope:
        return queryset
    return queryset.filter(**{f"{branch_lookup}__in": user.scoped_branch_ids()})
