from django import forms
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.forms import UserChangeForm
from django.contrib.auth.models import Group
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import PermissionDenied, ValidationError
from rest_framework import serializers as drf_serializers

from apps.employees.models import Employee

from .models import OTPVerification, User
from .scope import validate_scope
from .serializers import normalize_phone_number
from .services.role_permissions import ROLE_PERMISSION_CODES, ensure_role_group


class ScopeValidationMixin:
    """Server-side check that allowed branches belong to the selected organization (not just dropdown filtering)."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if "organization" in self.fields:
            self.fields["organization"].help_text = (
                "Organization this account can manage. Only trusted internal platform superusers have global access."
            )

    def clean_phone_number(self):
        value = self.cleaned_data["phone_number"]
        if self.instance.pk and "phone_number" not in self.changed_data:
            return value  # leave legacy stored values untouched
        try:
            return normalize_phone_number(value)
        except drf_serializers.ValidationError as exc:
            raise ValidationError(exc.detail[0])

    def clean(self):
        cleaned = super().clean()
        if "organization" in cleaned and "allowed_branches" in cleaned:
            validate_scope(cleaned.get("role"), cleaned["organization"], cleaned["allowed_branches"], require_organization=False)
        return cleaned


class UserAdminChangeForm(ScopeValidationMixin, UserChangeForm):
    class Meta(UserChangeForm.Meta):
        model = User
        fields = "__all__"


class UserAdminCreationForm(ScopeValidationMixin, forms.ModelForm):
    """Add-user form. Password is optional: React admins sign in with OTP, so by default no usable password is set.

    Provide a password only for accounts that must sign in to /admin/ (is_staff). It is always hashed.
    """
    password1 = forms.CharField(label="Password", required=False, strip=False, widget=forms.PasswordInput(attrs={"autocomplete": "new-password"}),
                                help_text="Optional. Leave blank for OTP-only users.")
    password2 = forms.CharField(label="Password confirmation", required=False, strip=False, widget=forms.PasswordInput(attrs={"autocomplete": "new-password"}))

    class Meta:
        model = User
        fields = ("phone_number", "email", "first_name", "last_name", "role", "organization", "allowed_branches",
                  "is_active", "is_staff", "is_superuser")

    def clean_password2(self):
        password1, password2 = self.cleaned_data.get("password1"), self.cleaned_data.get("password2")
        if password1 or password2:
            if password1 != password2:
                raise ValidationError("The two password fields didn't match.")
            validate_password(password1)
        return password2

    def save(self, commit=True):
        user = super().save(commit=False)
        password = self.cleaned_data.get("password1")
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        if commit:
            user.save()
            self.save_m2m()
        return user


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    model = User
    form = UserAdminChangeForm
    add_form = UserAdminCreationForm
    list_display = ("phone_number", "full_name", "role", "organization", "is_active", "is_staff")
    list_select_related = ("organization",)
    search_fields = ("phone_number", "first_name", "last_name", "email")
    list_filter = ("role", "organization", "is_active", "is_staff")
    ordering = ("phone_number",)
    filter_horizontal = ("allowed_branches", "groups", "user_permissions")
    fieldsets = (
        (None, {"fields": ("phone_number", "password")}),
        ("Personal info", {"fields": ("first_name", "last_name", "email")}),
        ("Lyra Pulse role & business scope", {"fields": ("role", "organization", "allowed_branches", "is_active")}),
        ("Django admin access (/admin/)", {"fields": ("is_staff", "is_superuser")}),
        ("Django permissions", {"fields": ("groups", "user_permissions")}),
    )
    add_fieldsets = (
        (None, {"classes": ("wide",), "fields": ("phone_number", "first_name", "last_name", "email", "password1", "password2")}),
        ("Lyra Pulse role & business scope", {"classes": ("wide",), "fields": ("role", "organization", "allowed_branches", "is_active")}),
        ("Django admin access (/admin/)", {"classes": ("wide",), "fields": ("is_staff", "is_superuser")}),
    )

    def has_delete_permission(self, request, obj=None):
        if obj is not None and Employee.objects.filter(user_id=obj.pk).exists():
            return False
        return super().has_delete_permission(request, obj)

    def get_deleted_objects(self, objs, request):
        users = list(objs)
        linked_users = list(
            Employee.objects.filter(user_id__in=[user.pk for user in users])
            .select_related("user")
        )
        if linked_users:
            deleted_objects = [str(user) for user in users]
            model_count = {User._meta.verbose_name_plural: len(users)}
            protected = [
                "Delete employee-linked user accounts from the Employees admin: %s"
                % ", ".join(employee.employee_code for employee in linked_users)
            ]
            return deleted_objects, model_count, set(), protected
        return super().get_deleted_objects(users, request)

    def delete_model(self, request, obj):
        if Employee.objects.filter(user_id=obj.pk).exists():
            raise PermissionDenied(
                "Delete this employee and its account from the Employees admin."
            )
        super().delete_model(request, obj)

    def delete_queryset(self, request, queryset):
        linked_employee_exists = Employee.objects.filter(
            user_id__in=queryset.values_list("pk", flat=True)
        ).exists()
        if linked_employee_exists:
            raise PermissionDenied(
                "Delete employee-linked user accounts from the Employees admin."
            )
        super().delete_queryset(request, queryset)

    def save_related(self, request, form, formsets, change):
        super().save_related(request, form, formsets, change)
        # Keep the role -> Django Group sync that the admin-users API already performs.
        user = form.instance
        if user.role in ROLE_PERMISSION_CODES:
            user.groups.add(ensure_role_group(user.role))
        stale = [role for role in ROLE_PERMISSION_CODES if role != user.role]
        user.groups.remove(*Group.objects.filter(name__in=stale))


@admin.register(OTPVerification)
class OTPVerificationAdmin(admin.ModelAdmin):
    list_display = ("phone_number", "purpose", "attempts", "expires_at", "is_verified")
    search_fields = ("phone_number",)
    list_filter = ("purpose", "is_verified")
    ordering = ("-created_at",)
