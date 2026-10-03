from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.db import transaction

from apps.accounts.serializers import normalize_phone_number
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from .models import Employee

User = get_user_model()


class EmployeeSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source="user.phone_number", read_only=True)
    name = serializers.CharField(source="user.full_name", read_only=True)

    class Meta:
        model = Employee
        fields = ("id", "employee_code", "phone_number", "name", "branch", "department", "designation", "joining_date", "profile_photo", "date_of_birth", "gender", "emergency_contact", "address", "is_active")


class EmployeeManagementSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(write_only=True, max_length=100)
    last_name = serializers.CharField(write_only=True, max_length=100)
    phone_number = serializers.CharField(max_length=20, write_only=True)
    email = serializers.EmailField(write_only=True)

    class Meta:
        model = Employee
        fields = ("id", "employee_code", "first_name", "last_name", "phone_number", "email",
                  "branch", "department", "designation", "joining_date", "is_active")
        read_only_fields = ("id",)

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data.update({"first_name": instance.user.first_name, "last_name": instance.user.last_name,
                    "phone_number": instance.user.phone_number, "email": instance.user.email})
        return data

    def validate_phone_number(self, value):
        phone = normalize_phone_number(value)
        users = User.objects.filter(phone_number=phone)
        if self.instance:
            users = users.exclude(pk=self.instance.user_id)
        if users.exists():
            raise serializers.ValidationError("A user with this phone number already exists.")
        return phone

    @transaction.atomic
    def create(self, validated_data):
        first_name = validated_data.pop("first_name")
        last_name = validated_data.pop("last_name", "")
        phone_number = validated_data.pop("phone_number")
        email = validated_data.pop("email", "")
        is_active = validated_data.get("is_active", True)
        user = User.objects.create_user(
            phone_number=phone_number, email=email, first_name=first_name,
            last_name=last_name, role=User.Role.EMPLOYEE, is_active=is_active,
        )
        return Employee.objects.create(user=user, **validated_data)

    @transaction.atomic
    def update(self, instance, validated_data):
        user_fields = ("first_name", "last_name", "phone_number", "email")
        for field in user_fields:
            if field in validated_data:
                setattr(instance.user, field, validated_data.pop(field))
        if "is_active" in validated_data:
            instance.user.is_active = validated_data["is_active"]
            instance.user.save(update_fields=["first_name", "last_name", "phone_number", "email", "is_active", "updated_at"])
        elif any(field in self.initial_data for field in user_fields):
            instance.user.save(update_fields=["first_name", "last_name", "phone_number", "email", "updated_at"])
        return super().update(instance, validated_data)


class BranchOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Branch
        fields = ("id", "name", "code", "is_active")
        read_only_fields = fields


class DepartmentOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Department
        fields = ("id", "name", "branch", "is_active")
        read_only_fields = fields


class DesignationOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Designation
        fields = ("id", "name", "department", "is_active")
        read_only_fields = fields