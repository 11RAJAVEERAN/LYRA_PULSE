from django.contrib.auth import get_user_model
from rest_framework import serializers

from apps.accounts.serializers import normalize_phone_number

from .models import Organization

User = get_user_model()


class OrganizationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Organization
        fields = ("id", "name", "code", "is_active", "created_at", "updated_at")
        read_only_fields = ("id", "created_at", "updated_at")

    def validate_name(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("Company name is required.")
        return value

    def validate_code(self, value):
        value = value.strip().upper()
        if not value:
            raise serializers.ValidationError("Company code is required.")
        existing = Organization.objects.filter(code__iexact=value)
        if self.instance:
            existing = existing.exclude(pk=self.instance.pk)
        if existing.exists():
            raise serializers.ValidationError("A company with this code already exists.")
        return value


class CompanySuperAdminSerializer(serializers.ModelSerializer):
    organization_id = serializers.PrimaryKeyRelatedField(
        source="organization",
        queryset=Organization.objects.filter(is_active=True),
        required=False,
        write_only=True,
    )

    class Meta:
        model = User
        fields = ("id", "organization_id", "phone_number", "email", "first_name", "last_name", "is_active")
        read_only_fields = ("id",)
        extra_kwargs = {
            "email": {"required": False, "allow_blank": True},
            "first_name": {"required": False, "allow_blank": True},
            "last_name": {"required": False, "allow_blank": True},
            "is_active": {"required": False},
        }

    def validate_phone_number(self, value):
        value = normalize_phone_number(value)
        users = User.objects.filter(phone_number=value)
        if self.instance:
            users = users.exclude(pk=self.instance.pk)
        if users.exists():
            raise serializers.ValidationError("A user with this phone number already exists.")
        return value

    def validate_email(self, value):
        value = value.strip().lower()
        users = User.objects.filter(email__iexact=value)
        if self.instance:
            users = users.exclude(pk=self.instance.pk)
        if value and users.exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return value

    def validate(self, attrs):
        organization = attrs.get(
            "organization",
            self.instance.organization if self.instance else self.context["organization"],
        )
        actor = self.context["request"].user
        if not self.instance and organization.pk != self.context["organization"].pk:
            raise serializers.ValidationError({"organization_id": "Use the company in the request URL."})
        if not actor.is_platform_superadmin and organization.pk != self.context["organization"].pk:
            raise serializers.ValidationError({"organization_id": "You can manage Super Admins only in your company."})
        attrs["organization"] = organization
        return attrs

    def create(self, validated_data):
        organization = validated_data.pop("organization", self.context["organization"])
        validated_data.setdefault("is_active", True)
        return User.objects.create_user(
            password=None,
            role=User.Role.SUPERADMIN,
            organization=organization,
            is_staff=False,
            is_superuser=False,
            **validated_data,
        )