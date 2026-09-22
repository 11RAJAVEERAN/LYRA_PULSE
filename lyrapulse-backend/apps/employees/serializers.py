from rest_framework import serializers

from .models import Employee


class EmployeeSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source="user.phone_number", read_only=True)
    name = serializers.CharField(source="user.full_name", read_only=True)

    class Meta:
        model = Employee
        fields = ("id", "employee_code", "phone_number", "name", "branch", "department", "designation", "joining_date", "profile_photo", "date_of_birth", "gender", "emergency_contact", "address", "is_active")