from rest_framework import serializers

from datetime import datetime, timezone


class DeviceAttendanceEventSerializer(serializers.Serializer):
    event_id = serializers.UUIDField()
    fingerprint_slot = serializers.IntegerField(min_value=0, max_value=999)
    occurred_at = serializers.DateTimeField()

    def validate_occurred_at(self, value):
        from django.utils import timezone as django_timezone
        if value < datetime(2020, 1, 1, tzinfo=timezone.utc):
            raise serializers.ValidationError("Device timestamp is invalid; synchronize the device clock.")
        if value > django_timezone.now():
            raise serializers.ValidationError("Device timestamp is ahead of the backend clock; synchronize the device clock.")
        return value
