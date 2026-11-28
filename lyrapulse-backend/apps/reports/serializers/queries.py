from datetime import timedelta

from django.utils import timezone
from rest_framework import serializers

from apps.accounts.scope import scope_queryset
from apps.branches.models import Branch

MAX_RANGE_DAYS = 92
MAX_PAGE_SIZE = 100
REPORT_ORDERINGS = (
    "employee_name", "-employee_name", "designation", "-designation",
    "attendance_date", "-attendance_date", "check_in", "-check_in",
    "working_hours", "-working_hours", "status", "-status",
)


class ReportQuerySerializer(serializers.Serializer):
    start_date = serializers.DateField(required=False)
    end_date = serializers.DateField(required=False)
    branch = serializers.IntegerField(required=False, min_value=1)
    search = serializers.CharField(required=False, allow_blank=True, max_length=100)
    page = serializers.IntegerField(required=False, min_value=1, default=1)
    page_size = serializers.IntegerField(required=False, min_value=1, max_value=MAX_PAGE_SIZE, default=10)
    ordering = serializers.ChoiceField(choices=REPORT_ORDERINGS, required=False, default="employee_name")
    export_format = serializers.ChoiceField(choices=("xlsx", "pdf"), required=False, default="xlsx")

    def validate_branch(self, value):
        user = self.context["request"].user
        if not scope_queryset(Branch.objects.filter(pk=value), user, "id").exists():
            raise serializers.ValidationError("Invalid branch.")
        return value

    def validate(self, attrs):
        today = timezone.localdate()
        start = attrs.get("start_date")
        end = attrs.get("end_date")
        if start is None and end is None:
            end = today
            start = end - timedelta(days=27)
        elif start is None or end is None:
            raise serializers.ValidationError({"date_range": "start_date and end_date must be provided together."})
        if start > end:
            raise serializers.ValidationError({"end_date": "End date must be on or after start date."})
        if end > today:
            raise serializers.ValidationError({"end_date": "Future report dates are not available."})
        if (end - start).days + 1 > MAX_RANGE_DAYS:
            raise serializers.ValidationError({"end_date": f"Date ranges cannot exceed {MAX_RANGE_DAYS} days."})
        attrs["start_date"], attrs["end_date"] = start, end
        return attrs
