from rest_framework import serializers

from apps.accounts.models import User
from apps.organizations.models import Organization

from .models import (
    MAX_ATTENDANCE_RADIUS_METERS,
    MIN_ATTENDANCE_RADIUS_METERS,
    Branch,
)


class AttendanceRadiusUpdateSerializer(serializers.Serializer):
    attendance_radius_meters = serializers.IntegerField(min_value=MIN_ATTENDANCE_RADIUS_METERS,
                                                       max_value=MAX_ATTENDANCE_RADIUS_METERS)

    def to_internal_value(self, data):
        if not isinstance(data, dict):
            raise serializers.ValidationError("Expected an object containing only attendance_radius_meters.")
        unexpected = set(data) - {"attendance_radius_meters"}
        if unexpected:
            raise serializers.ValidationError({
                key: "Unexpected field; only attendance_radius_meters may be updated."
                for key in unexpected
            })
        value = data.get("attendance_radius_meters")
        if type(value) is not int:
            raise serializers.ValidationError({
                "attendance_radius_meters": "A whole-number integer is required."
            })
        return super().to_internal_value(data)


class BranchSerializer(serializers.ModelSerializer):
    organization_id = serializers.PrimaryKeyRelatedField(
        source="organization",
        queryset=Organization.objects.filter(is_active=True),
        required=False,
        write_only=True,
    )
    organization = serializers.SerializerMethodField(read_only=True)
    location_configured = serializers.BooleanField(source="has_attendance_location", read_only=True)

    class Meta:
        model = Branch
        fields = (
            "id", "organization", "organization_id", "name", "code", "address",
            "latitude", "longitude", "attendance_radius_meters", "location_configured",
            "is_active", "created_at", "updated_at",
        )
        read_only_fields = ("id", "organization", "location_configured", "created_at", "updated_at")

    def get_organization(self, obj):
        if obj.organization_id is None:
            return None
        return {"id": obj.organization_id, "name": obj.organization.name, "is_active": obj.organization.is_active}

    def validate_name(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("Branch name is required.")
        return value

    def validate_code(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("Branch code is required.")
        return value

    def validate_attendance_radius_meters(self, value):
        if not MIN_ATTENDANCE_RADIUS_METERS <= value <= MAX_ATTENDANCE_RADIUS_METERS:
            raise serializers.ValidationError(
                f"Attendance radius must be between {MIN_ATTENDANCE_RADIUS_METERS} and "
                f"{MAX_ATTENDANCE_RADIUS_METERS} metres."
            )
        return value

    def validate(self, attrs):
        request = self.context["request"]
        user = request.user
        proposed_organization = attrs.get("organization")

        if user.is_platform_superadmin:
            if self.instance is None and proposed_organization is None:
                raise serializers.ValidationError({"organization_id": "Select an active company for this branch."})
            if (self.instance and self.instance.organization_id is not None and proposed_organization is not None
                    and proposed_organization.pk != self.instance.organization_id):
                raise serializers.ValidationError({"organization_id": "An assigned branch cannot be moved to another company."})
        else:
            if (user.role != User.Role.SUPERADMIN or not user.organization_id or not user.organization.is_active):
                raise serializers.ValidationError("Only a Platform or Company Super Admin can manage branches.")
            if proposed_organization is not None and proposed_organization.pk != user.organization_id:
                raise serializers.ValidationError({"organization_id": "You can manage branches only in your company."})
            attrs["organization"] = user.organization
            if self.instance and self.instance.organization_id != user.organization_id:
                raise serializers.ValidationError("Branch not found in your company.")

        latitude = attrs.get("latitude", getattr(self.instance, "latitude", None))
        longitude = attrs.get("longitude", getattr(self.instance, "longitude", None))
        if (latitude is None) != (longitude is None):
            raise serializers.ValidationError({"latitude": "Set both latitude and longitude, or leave both empty."})
        return attrs
