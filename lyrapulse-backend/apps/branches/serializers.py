from rest_framework import serializers

from .models import Branch


class BranchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Branch
        fields = (
            "id",
            "name",
            "code",
            "address",
            "latitude",
            "longitude",
            "attendance_radius_meters",
            "is_active",
        )
        read_only_fields = fields
