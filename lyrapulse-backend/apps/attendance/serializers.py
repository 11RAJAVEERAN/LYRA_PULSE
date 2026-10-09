from collections.abc import Mapping

from rest_framework import serializers


class FingerprintAttendanceSerializer(serializers.Serializer):
    device_id = serializers.CharField(max_length=100)
    fingerprint_slot = serializers.IntegerField(min_value=0)

    def to_internal_value(self, data):
        unknown_fields = set(data) - set(self.fields) if isinstance(data, Mapping) else set()
        if unknown_fields:
            raise serializers.ValidationError({
                "non_field_errors": [
                    "Unknown field(s): %s" % ", ".join(sorted(unknown_fields))
                ]
            })
        return super().to_internal_value(data)


class AttendanceHistoryQuerySerializer(serializers.Serializer):
    employee_id = serializers.IntegerField(min_value=1)
    date = serializers.DateField()
