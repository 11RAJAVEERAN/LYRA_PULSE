from collections.abc import Mapping

from django.contrib.auth import get_user_model
from django.db import IntegrityError, transaction
from rest_framework import serializers

from apps.accounts.models import User
from apps.accounts.serializers import normalize_phone_number
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation

from .models import Employee

AuthUser = get_user_model()


class EmployeeSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source="user.phone_number", read_only=True)
    name = serializers.CharField(source="user.full_name", read_only=True)

    class Meta:
        model = Employee
        fields = ("id", "employee_code", "phone_number", "name", "branch", "department", "designation", "joining_date", "profile_photo", "date_of_birth", "gender", "emergency_contact", "address", "is_active")


class EmployeeRegistrationResponseSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source="user.phone_number", read_only=True)
    name = serializers.CharField(source="user.full_name", read_only=True)

    class Meta:
        model = Employee
        fields = (
            "id",
            "employee_code",
            "phone_number",
            "name",
            "branch",
            "department",
            "designation",
            "joining_date",
            "is_active",
        )
        read_only_fields = fields


class EmployeeRegistrationSerializer(serializers.Serializer):
    employee_code = serializers.CharField(max_length=30)
    phone_number = serializers.CharField(max_length=20)
    first_name = serializers.CharField(max_length=100, required=False, allow_blank=True)
    last_name = serializers.CharField(max_length=100, required=False, allow_blank=True)
    email = serializers.EmailField(required=False, allow_blank=True)
    branch_id = serializers.PrimaryKeyRelatedField(
        source="branch",
        queryset=Branch.objects.all(),
    )
    department_id = serializers.PrimaryKeyRelatedField(
        source="department",
        queryset=Department.objects.all(),
        required=False,
        allow_null=True,
    )
    designation_id = serializers.PrimaryKeyRelatedField(
        source="designation",
        queryset=Designation.objects.all(),
        required=False,
        allow_null=True,
    )
    joining_date = serializers.DateField(required=False, allow_null=True)
    date_of_birth = serializers.DateField(required=False, allow_null=True)
    gender = serializers.ChoiceField(
        choices=Employee.Gender.choices,
        required=False,
        allow_blank=True,
    )
    emergency_contact = serializers.CharField(max_length=20, required=False, allow_blank=True)
    address = serializers.CharField(required=False, allow_blank=True)
    is_active = serializers.BooleanField(required=False, default=True)

    def to_internal_value(self, data):
        allowed_fields = set(self.fields)
        unknown_fields = set(data) - allowed_fields if isinstance(data, Mapping) else set()
        if unknown_fields:
            raise serializers.ValidationError({
                "non_field_errors": [
                    "Unknown field(s): %s" % ", ".join(sorted(unknown_fields))
                ]
            })
        return super().to_internal_value(data)

    def validate_employee_code(self, value):
        value = value.strip()
        if not value:
            raise serializers.ValidationError("This field may not be blank.")
        if Employee.objects.filter(employee_code=value).exists():
            raise serializers.ValidationError("An employee with this employee code already exists.")
        return value

    def validate_phone_number(self, value):
        value = normalize_phone_number(value)
        if AuthUser.objects.filter(phone_number=value).exists():
            raise serializers.ValidationError("A user with this phone number already exists.")
        return value

    def validate_branch_id(self, branch):
        if not branch.is_active:
            raise serializers.ValidationError("The selected branch is inactive.")
        return branch

    def validate(self, attrs):
        department = attrs.get("department")
        designation = attrs.get("designation")
        branch = attrs["branch"]

        if department and not department.is_active:
            raise serializers.ValidationError({"department_id": "The selected department is inactive."})
        if department and department.branch_id != branch.id:
            raise serializers.ValidationError({
                "department_id": "The selected department does not belong to the selected branch."
            })

        if designation and not designation.is_active:
            raise serializers.ValidationError({"designation_id": "The selected designation is inactive."})
        if designation and department is None:
            raise serializers.ValidationError({
                "department_id": "A department is required when a designation is selected."
            })
        if designation and designation.department_id != department.id:
            raise serializers.ValidationError({
                "designation_id": "The selected designation does not belong to the selected department."
            })

        return attrs

    def create(self, validated_data):
        branch = validated_data.pop("branch")
        department = validated_data.pop("department", None)
        designation = validated_data.pop("designation", None)
        is_active = validated_data.pop("is_active", True)
        phone_number = validated_data.pop("phone_number")
        first_name = validated_data.pop("first_name", "")
        last_name = validated_data.pop("last_name", "")
        email = validated_data.pop("email", "")

        try:
            with transaction.atomic():
                user = AuthUser.objects.create_user(
                    phone_number=phone_number,
                    first_name=first_name,
                    last_name=last_name,
                    email=email,
                    role=User.Role.EMPLOYEE,
                    is_active=is_active,
                )
                return Employee.objects.create(
                    user=user,
                    branch=branch,
                    department=department,
                    designation=designation,
                    is_active=is_active,
                    **validated_data,
                )
        except IntegrityError as exc:
            if Employee.objects.filter(employee_code=validated_data.get("employee_code")).exists():
                raise serializers.ValidationError({
                    "employee_code": "An employee with this employee code already exists."
                }) from exc
            if AuthUser.objects.filter(phone_number=phone_number).exists():
                raise serializers.ValidationError({
                    "phone_number": "A user with this phone number already exists."
                }) from exc
            raise

    def to_representation(self, instance):
        return EmployeeRegistrationResponseSerializer(instance, context=self.context).data