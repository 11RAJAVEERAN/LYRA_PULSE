import math

from rest_framework import serializers

from .services import MAX_GPS_ACCURACY_METERS
from .validators import MAX_PHOTO_BYTES, validate_attendance_photo


def _float_field(label, low, high):
    message = f"{label} must be a number between {low} and {high}."
    return serializers.FloatField(min_value=low, max_value=high, error_messages={
        "required": f"{label} is required.", "null": f"{label} is required.", "invalid": message,
        "min_value": message, "max_value": message,
    })


class LocationSerializer(serializers.Serializer):
    """Device location sent by the Flutter app. Employee and branch are NEVER read from the request."""
    latitude = _float_field("Latitude", -90, 90)
    longitude = _float_field("Longitude", -180, 180)
    accuracy = _float_field("GPS accuracy", 0, MAX_GPS_ACCURACY_METERS)

    def _finite(self, value, label):
        if not math.isfinite(value):  # NaN would otherwise slip past min/max validators
            raise serializers.ValidationError(f"{label} must be a finite number.")
        return value

    def validate_latitude(self, value):
        return self._finite(value, "Latitude")

    def validate_longitude(self, value):
        return self._finite(value, "Longitude")

    def validate_accuracy(self, value):
        return self._finite(value, "GPS accuracy")


class AttendanceActionSerializer(LocationSerializer):
    """multipart/form-data body for check-in and check-out."""
    photo = serializers.FileField(
        required=False,
        validators=[validate_attendance_photo],
        help_text=f"JPEG or PNG image, at most {MAX_PHOTO_BYTES // (1024 * 1024)} MB. Content is verified server-side.",
        error_messages={
            "required": "A photo is required.", "empty": "The uploaded photo is empty.",
            "invalid": "Photo must be uploaded as a file.", "no_file": "A photo is required.",
        },
    )


class BranchBriefSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name = serializers.CharField()


class VerifyLocationResultSerializer(serializers.Serializer):
    verified = serializers.BooleanField()
    branch = BranchBriefSerializer()
    distance_meters = serializers.FloatField()
    allowed_radius_meters = serializers.IntegerField()
    accuracy_meters = serializers.FloatField(allow_null=True)


class CheckInResultSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    attendance_date = serializers.DateField()
    check_in_at = serializers.DateTimeField()
    location_verified = serializers.BooleanField(source="check_in_location_verified")
    distance_meters = serializers.FloatField(source="check_in_distance_meters")


class CheckOutResultSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    attendance_date = serializers.DateField()
    check_in_at = serializers.DateTimeField()
    check_out_at = serializers.DateTimeField()
    location_verified = serializers.BooleanField(source="check_out_location_verified")
    distance_meters = serializers.FloatField(source="check_out_distance_meters")


class TodayStateSerializer(serializers.Serializer):
    attendance_date = serializers.DateField()
    state = serializers.ChoiceField(choices=["NOT_CHECKED_IN", "CHECKED_IN", "CHECKED_OUT"])
    check_in_at = serializers.DateTimeField(allow_null=True)
    check_out_at = serializers.DateTimeField(allow_null=True)
    sessions = serializers.ListField(child=serializers.DictField(), required=False)
