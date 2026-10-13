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
from .services.role_permissions import ensure_role_group

User = get_user_model()
MANAGED_ROLES = {User.Role.ADMIN, User.Role.HR, User.Role.MANAGER}


class AdminUserSerializer(serializers.ModelSerializer):
    permissions = serializers.ListField(child=serializers.CharField(), required=False, write_only=True)
    permission_codenames = serializers.SerializerMethodField()
    is_active = serializers.BooleanField(required=False, default=True)
    # Business scope: `organization` (id) and `branch_ids` (list of branch ids) are optional so the current
    # React form keeps working; users without a scope are fail-closed and see no organization data.
    branch_ids = serializers.PrimaryKeyRelatedField(
        many=True, queryset=Branch.objects.all(), source="allowed_branches", required=False,
    )

    class Meta:
        model = User
        fields = ("id", "phone_number", "email", "first_name", "last_name", "role", "is_active",
                  "organization", "branch_ids", "permissions", "permission_codenames")
        read_only_fields = ("id", "permission_codenames")

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
        organization = attrs["organization"] if "organization" in attrs else (self.instance.organization if self.instance else None)
        if "allowed_branches" in attrs:
            branches = attrs["allowed_branches"]
        else:
            branches = list(self.instance.allowed_branches.all()) if self.instance else []
        try:
            validate_scope(role, organization, branches, require_organization=False)
        except DjangoValidationError as exc:
            raise serializers.ValidationError(exc.message_dict)
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
        return (User.objects.filter(role__in=MANAGED_ROLES).select_related("organization")
                .prefetch_related("allowed_branches").order_by("role", "phone_number"))


class AdminUserDetailView(SuperAdminOnlyMixin, RetrieveUpdateAPIView):
    serializer_class = AdminUserSerializer

    def get_queryset(self):
        return User.objects.filter(role__in=MANAGED_ROLES).select_related("organization").prefetch_related("allowed_branches")
