import uuid
from datetime import timedelta

from django.conf import settings
from django.utils import timezone
from rest_framework import serializers

from apps.devices.models import Device

from .models import EmployeeFingerprint, FingerprintEnrollment
from .services import cancel_queued_finger


class FingerprintEnrollmentStartSerializer(serializers.Serializer):
    device_id = serializers.SlugRelatedField(
        slug_field="device_id",
        queryset=Device.objects.filter(is_active=True),
    )
    finger = serializers.ChoiceField(
        choices=FingerprintEnrollment.Finger.choices,
        required=False,
    )
    fingers = serializers.ListField(
        child=serializers.ChoiceField(choices=FingerprintEnrollment.Finger.choices),
        min_length=2,
        max_length=2,
        required=False,
    )

    def to_internal_value(self, data):
        unknown = set(data) - set(self.fields) if hasattr(data, "keys") else set()
        if unknown:
            raise serializers.ValidationError({
                "non_field_errors": ["Unknown field(s): %s" % ", ".join(sorted(unknown))]
            })
        has_finger = "finger" in data
        has_fingers = "fingers" in data
        if has_finger == has_fingers:
            raise serializers.ValidationError({
                "non_field_errors": ["Provide either finger or exactly two fingers."]
            })
        return super().to_internal_value(data)

    def validate_device_id(self, device):
        employee = self.context["employee"]
        if not device.branch.is_active:
            raise serializers.ValidationError("The device branch is inactive.")
        if employee.branch_id != device.branch_id:
            raise serializers.ValidationError("The device and employee must belong to the same branch.")
        return device

    def validate(self, attrs):
        employee = self.context["employee"]
        device = attrs["device_id"]
        fingers = attrs["fingers"] if "fingers" in attrs else [attrs["finger"]]
        if len(set(fingers)) != len(fingers):
            raise serializers.ValidationError({
                "fingers": "The two enrolled fingers must be different."
            })
        if len(fingers) == 2 and EmployeeFingerprint.objects.filter(
            employee=employee,
            device=device,
            is_active=True,
        ).exists():
            raise serializers.ValidationError({
                "fingers": "A two-finger enrollment requires no existing active mappings on this device."
            })

        existing_fingers = EmployeeFingerprint.objects.filter(
            employee=employee,
            device=device,
            finger__in=fingers,
            is_active=True,
        ).values_list("finger", flat=True)
        already_mapped = set(existing_fingers)
        if already_mapped:
            field = "finger" if "finger" in attrs else "fingers"
            raise serializers.ValidationError({
                field: "Finger(s) already have an active mapping on this device: %s"
                % ", ".join(sorted(already_mapped))
            })

        now = timezone.now()
        expired_enrollments = FingerprintEnrollment.objects.filter(
            device=device,
            status__in=FingerprintEnrollment.ACTIVE_STATUSES,
            expires_at__lte=now,
        )
        for enrollment in expired_enrollments:
            FingerprintEnrollment.objects.filter(pk=enrollment.pk).update(
                status=FingerprintEnrollment.Status.EXPIRED,
                completed_at=now,
                failure_reason="EXPIRED",
                updated_at=now,
            )
            cancel_queued_finger(enrollment, now, "PAIR_PREVIOUS_FINGER_EXPIRED")
        if FingerprintEnrollment.objects.filter(
            device=device,
            status__in=FingerprintEnrollment.ACTIVE_STATUSES,
        ).exists():
            raise serializers.ValidationError({
                "device_id": "This device already has an enrollment in progress."
            })
        return attrs

    def create(self, validated_data):
        employee = self.context["employee"]
        ttl_seconds = getattr(settings, "FINGERPRINT_ENROLLMENT_TTL_SECONDS", 300)
        fingers = (
            validated_data["fingers"]
            if "fingers" in validated_data
            else [validated_data["finger"]]
        )
        pair_id = uuid.uuid4()
        now = timezone.now()
        enrollments = []
        for index, finger in enumerate(fingers, start=1):
            enrollments.append(
                FingerprintEnrollment.objects.create(
                    employee=employee,
                    device=validated_data["device_id"],
                    finger=finger,
                    pair_id=pair_id,
                    finger_index=index,
                    total_fingers=len(fingers),
                    status=(
                        FingerprintEnrollment.Status.PENDING
                        if index == 1
                        else FingerprintEnrollment.Status.QUEUED
                    ),
                    created_by=self.context["request"].user,
                    expires_at=now + timedelta(seconds=ttl_seconds),
                )
            )
        return enrollments


class DeviceEnrollmentResultSerializer(serializers.Serializer):
    FAILURE_CODES = (
        "NO_MATCH",
        "IMAGE_CAPTURE_FAILED",
        "POOR_IMAGE",
        "TEMPLATE_CREATE_FAILED",
        "SENSOR_FULL",
        "STORAGE_FAILED",
        "SENSOR_TIMEOUT",
        "SENSOR_COMMUNICATION_ERROR",
        "SENSOR_TEMPLATE_READ_ERROR",
        "DUPLICATE_FINGERPRINT",
        "INVALID_SLOT",
        "SLOT_VERIFICATION_FAILED",
        "DEVICE_API_ERROR",
        "UNKNOWN",
    )

    status = serializers.ChoiceField(
        choices=(
            FingerprintEnrollment.Status.WAITING_FOR_SECOND_SCAN,
            FingerprintEnrollment.Status.PROCESSING,
            FingerprintEnrollment.Status.STORING,
            FingerprintEnrollment.Status.SUCCESS,
            FingerprintEnrollment.Status.FAILED,
        )
    )
    fingerprint_slot = serializers.IntegerField(
        min_value=0,
        max_value=getattr(settings, "R307_MAX_TEMPLATE_COUNT", 1000) - 1,
        required=False,
    )
    error_code = serializers.ChoiceField(choices=FAILURE_CODES, required=False)

    def to_internal_value(self, data):
        unknown = set(data) - set(self.fields) if hasattr(data, "keys") else set()
        if unknown:
            raise serializers.ValidationError({
                "non_field_errors": ["Unknown field(s): %s" % ", ".join(sorted(unknown))]
            })
        return super().to_internal_value(data)

    def validate(self, attrs):
        state = attrs["status"]
        if state in (
            FingerprintEnrollment.Status.STORING,
            FingerprintEnrollment.Status.SUCCESS,
        ) and "fingerprint_slot" not in attrs:
            raise serializers.ValidationError({"fingerprint_slot": "This field is required on success."})
        if state == FingerprintEnrollment.Status.FAILED and "error_code" not in attrs:
            raise serializers.ValidationError({"error_code": "This field is required on failure."})
        if state not in (
            FingerprintEnrollment.Status.STORING,
            FingerprintEnrollment.Status.SUCCESS,
        ) and "fingerprint_slot" in attrs:
            raise serializers.ValidationError({
                "fingerprint_slot": "This field is only valid while storing or on success."
            })
        if state != FingerprintEnrollment.Status.FAILED and "error_code" in attrs:
            raise serializers.ValidationError({"error_code": "This field is only valid on failure."})
        return attrs


class FingerprintEnrollmentStatusSerializer(serializers.ModelSerializer):
    enrollment_id = serializers.UUIDField(source="id", read_only=True)
    employee_id = serializers.IntegerField(read_only=True)
    device_id = serializers.CharField(source="device.device_id", read_only=True)
    fingerprint_slot = serializers.IntegerField(source="actual_slot", read_only=True)

    class Meta:
        model = FingerprintEnrollment
        fields = (
            "enrollment_id",
            "employee_id",
            "device_id",
            "finger",
            "pair_id",
            "finger_index",
            "total_fingers",
            "status",
            "fingerprint_slot",
            "expires_at",
            "failure_reason",
        )
        read_only_fields = fields
