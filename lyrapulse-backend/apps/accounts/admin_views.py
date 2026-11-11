from django.contrib.auth import get_user_model
from django.contrib.auth.models import Group, Permission
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import transaction
from rest_framework import serializers, status
from rest_framework.generics import ListCreateAPIView, RetrieveUpdateAPIView
from rest_framework.permissions import IsAuthenticated

from apps.branches.models import Branch
from apps.common.responses import success_response
from .permissions import IsSuperAdmin
from .scope import validate_scope
from .services.role_permissions import ROLE_PERMISSION_CODES, ensure_role_group

User = get_user_model()
MANAGED_ROLES = {User.Role.ADMIN, User.Role.HR, User.Role.MANAGER}


class AdminUserSerializer(serializers.ModelSerializer):
    permissions = serializers.ListField(child=serializers.CharField(), required=False, write_only=True)
    permission_codenames = serializers.SerializerMethodField()
    organization_name = serializers.CharField(source="organization.name", read_only=True)
    branch_details = serializers.SerializerMethodField()
    is_active = serializers.BooleanField(required=False, default=True)
    branch_ids = serializers.PrimaryKeyRelatedField(
        many=True, queryset=Branch.objects.all(), source="allowed_branches", required=False,
    )

    class Meta:
        model = User
        fields = ("id", "phone_number", "email", "first_name", "last_name", "role", "is_active",
                  "organization", "organization_name", "branch_ids", "branch_details",
                  "permissions", "permission_codenames")
        read_only_fields = ("id", "organization_name", "branch_details", "permission_codenames")

    def validate_role(self, value):
        if value not in MANAGED_ROLES:
            raise serializers.ValidationError("Only ADMIN, HR, and MANAGER accounts can be managed here.")
        return value

    def validate_phone_number(self, value):
        from .serializers import normalize_phone_number
        value = normalize_phone_number(value)
        qs = User.objects.filter(phone_number=value)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if qs.exists():
            raise serializers.ValidationError("This mobile number is already in use.")
        return value

    def validate_email(self, value):
        value = value.strip().lower()
        qs = User.objects.filter(email__iexact=value)
        if self.instance:
            qs = qs.exclude(pk=self.instance.pk)
        if value and qs.exists():
            raise serializers.ValidationError("This email is already in use.")
        return value

    def validate_organization(self, value):
        current = self.instance.organization if self.instance else None
        if value is not None and not value.is_active and value != current:
            raise serializers.ValidationError("This organization is inactive.")
        return value

    def validate(self, attrs):
        # Resolve the final role/organization/branches (request values, else the stored ones) and check they agree.
        role = attrs.get("role", self.instance.role if self.instance else None)
        if role not in MANAGED_ROLES:
            raise serializers.ValidationError({"role": "Select an ADMIN, HR, or MANAGER role."})
        organization = attrs["organization"] if "organization" in attrs else (self.instance.organization if self.instance else None)
        if "allowed_branches" in attrs:
            branches = attrs["allowed_branches"]
        else:
            branches = list(self.instance.allowed_branches.all()) if self.instance else []
        actor = self.context["request"].user
        if not actor.has_global_scope:
            if organization is not None and organization.pk != actor.organization_id:
                raise serializers.ValidationError({"organization": "You can manage users only in your organization."})
            organization = actor.organization
            attrs["organization"] = organization
        if organization is None:
            raise serializers.ValidationError({"organization": "Select a company for this account."})
        if not organization.is_active:
            raise serializers.ValidationError({"organization": "Select an active company."})
        if not branches:
            raise serializers.ValidationError({"branch_ids": "Assign at least one branch to this account."})
        if any(
            branch.organization_id != organization.pk
            or not branch.is_active
            or not branch.organization.is_active
            for branch in branches
        ):
            raise serializers.ValidationError({
                "branch_ids": "Select active branches that belong to the selected company."
            })
        try:
            validate_scope(role, organization, branches)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.message_dict)
        permission_codes = attrs.get("permissions")
        if permission_codes is not None:
            allowed_permissions = set(ROLE_PERMISSION_CODES.get(role, set()))
            if role in (User.Role.ADMIN, User.Role.HR):
                allowed_permissions.update({
                    "employees.view_employee_sensitive",
                    "employees.change_employee_sensitive",
                })
            if set(permission_codes) - allowed_permissions:
                raise serializers.ValidationError({
                    "permissions": f"One or more permissions are not allowed for the {role} role."
                })
        return attrs

    def validate_permissions(self, values):
        parsed = [value.split(".", 1) for value in values]
        allowed_apps = {"accounts", "employees", "branches", "departments", "designations"}
        if any(len(item) != 2 or item[0] not in allowed_apps for item in parsed):
            raise serializers.ValidationError("Permissions must use the app_label.codename format.")
        found = set(Permission.objects.filter(
            content_type__app_label__in=allowed_apps,
            codename__in=[item[1] for item in parsed],
        ).values_list("content_type__app_label", "codename"))
        if len(found) != len({tuple(item) for item in parsed}):
            raise serializers.ValidationError("One or more permissions are unavailable.")
        return list(dict.fromkeys(values))

    def get_permission_codenames(self, obj):
        return [f"{app}.{code}" for app, code in obj.user_permissions.values_list("content_type__app_label", "codename")]

    def get_branch_details(self, obj):
        return [
            {"id": branch.pk, "name": branch.name, "code": branch.code}
            for branch in obj.allowed_branches.all()
        ]

    @transaction.atomic
    def create(self, validated_data):
        permission_codes = validated_data.pop("permissions", [])
        branches = validated_data.pop("allowed_branches", [])
        validated_data.setdefault("is_active", True)
        user = User.objects.create_user(password=None, **validated_data)
        user.groups.add(ensure_role_group(user.role))
        if branches:
            user.allowed_branches.set(branches)
        self._set_permissions(user, permission_codes)
        return user

    @transaction.atomic
    def update(self, instance, validated_data):
        permission_codes = validated_data.pop("permissions", None)
        branches = validated_data.pop("allowed_branches", None)
        previous_role = instance.role
        for key, value in validated_data.items():
            setattr(instance, key, value)
        instance.save()
        if previous_role != instance.role:
            previous_group = Group.objects.filter(name=previous_role).first()
            if previous_group:
                instance.groups.remove(previous_group)
        instance.groups.add(ensure_role_group(instance.role))
        if branches is not None:
            instance.allowed_branches.set(branches)
        if permission_codes is not None:
            self._set_permissions(instance, permission_codes)
        return instance

    @staticmethod
    def _set_permissions(user, codes):
        pairs = [value.split(".", 1) for value in codes]
        permissions = Permission.objects.none()
        for app_label, codename in pairs:
            permissions = permissions | Permission.objects.filter(content_type__app_label=app_label, codename=codename)
        user.user_permissions.set(permissions)


class SuperAdminOnlyMixin:
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def list(self, request, *args, **kwargs):
        data = self.get_serializer(self.get_queryset(), many=True).data
        return success_response(data)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return success_response(serializer.save() and serializer.data, "User created successfully", status.HTTP_201_CREATED)

    def retrieve(self, request, *args, **kwargs):
        return success_response(self.get_serializer(self.get_object()).data)

    def partial_update(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_object(), data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        return success_response(serializer.save() and serializer.data, "User updated successfully")


class AdminUserListCreateView(SuperAdminOnlyMixin, ListCreateAPIView):
    serializer_class = AdminUserSerializer

    def get_queryset(self):
        queryset = User.objects.filter(role__in=MANAGED_ROLES).select_related("organization")
        if not self.request.user.has_global_scope:
            queryset = queryset.filter(organization_id=self.request.user.organization_id)
        return queryset.prefetch_related("allowed_branches").order_by("role", "phone_number")


class AdminUserDetailView(SuperAdminOnlyMixin, RetrieveUpdateAPIView):
    serializer_class = AdminUserSerializer

    def get_queryset(self):
        queryset = User.objects.filter(role__in=MANAGED_ROLES).select_related("organization")
        if not self.request.user.has_global_scope:
            queryset = queryset.filter(organization_id=self.request.user.organization_id)
        return queryset.prefetch_related("allowed_branches")
