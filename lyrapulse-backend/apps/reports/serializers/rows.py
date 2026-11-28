from rest_framework import serializers


class ReportRowSerializer(serializers.Serializer):
    """Envelope-safe row representation; each report keeps its own JSON columns."""
    employee = serializers.JSONField(required=False)
    employee_id = serializers.IntegerField(required=False)
    employee_code = serializers.CharField(required=False, allow_blank=True)
    name = serializers.CharField(required=False, allow_blank=True)
    role = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    department = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    branch = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    attendance_date = serializers.DateField(required=False, allow_null=True)
    date = serializers.DateField(required=False, allow_null=True)
    day = serializers.CharField(required=False, allow_blank=True)
    values = serializers.ListField(child=serializers.JSONField(), required=False)

    def to_representation(self, instance):
        return instance


class ReportPageSerializer(serializers.Serializer):
    title = serializers.CharField()
    start_date = serializers.DateField()
    end_date = serializers.DateField()
    branch = serializers.IntegerField(allow_null=True)
    count = serializers.IntegerField(min_value=0)
    page = serializers.IntegerField(min_value=1)
    page_size = serializers.IntegerField(min_value=1)
    total_pages = serializers.IntegerField(min_value=1)
    dates = serializers.ListField(child=serializers.DateField(), required=False)
    results = serializers.ListField(child=serializers.JSONField())
    source_available = serializers.BooleanField(required=False)
    leave_holiday_source_available = serializers.BooleanField(required=False)
    message = serializers.CharField(required=False)
