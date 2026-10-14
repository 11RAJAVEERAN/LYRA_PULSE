import re
from datetime import date

from rest_framework import serializers
from rest_framework.exceptions import PermissionDenied
from django.contrib.auth import get_user_model
from django.db import transaction

from apps.accounts.permissions import can_change_sensitive_employee_data, can_view_sensitive_employee_data
from apps.accounts.serializers import normalize_phone_number
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from .models import Employee, EmployeeDocument, EmployeeType, PayrollGroup

User = get_user_model()


class EmployeeSerializer(serializers.ModelSerializer):
    phone_number = serializers.CharField(source="user.phone_number", read_only=True)
    name = serializers.CharField(source="user.full_name", read_only=True)

    class Meta:
        model = Employee
        fields = ("id", "employee_code", "phone_number", "name", "branch", "department", "designation", "joining_date", "profile_photo", "date_of_birth", "gender", "emergency_contact", "address", "is_active")


IFSC_PATTERN = re.compile(r"^[A-Z]{4}0[A-Z0-9]{6}$")
ACCOUNT_NUMBER_PATTERN = re.compile(r"^[A-Za-z0-9]{6,34}$")

# Salary and bank data are sensitive: only users with the *_employee_sensitive permissions (or SUPERADMIN) may
# read or write them; they are never part of the list response.
SENSITIVE_FIELDS = (
    "salary_type", "monthly_salary", "payroll_group",
    "bank_name", "bank_branch_name", "bank_account_number", "bank_account_number_masked", "bank_ifsc_code",
    "documents",
)
SENSITIVE_WRITE_FIELDS = (
    "salary_type", "monthly_salary", "payroll_group",
    "bank_name", "bank_branch_name", "bank_account_number", "bank_ifsc_code",
)


def mask_account_number(value):
    if not value:
        return ""
    return "X" * max(len(value) - 4, 0) + value[-4:]


class EmployeeDocumentSerializer(serializers.ModelSerializer):
    download_url = serializers.SerializerMethodField()

    class Meta:
        model = EmployeeDocument
        fields = ("id", "doc_type", "side", "original_name", "content_type", "size", "uploaded_at", "download_url")
        read_only_fields = fields

    def get_download_url(self, obj):
        return f"/api/v1/employees/{obj.employee_id}/documents/{obj.pk}/download/"


class EmployeeManagementSerializer(serializers.ModelSerializer):
    first_name = serializers.CharField(write_only=True, max_length=100)
    last_name = serializers.CharField(write_only=True, max_length=100, required=False, allow_blank=True)
    phone_number = serializers.CharField(max_length=20, write_only=True)
    email = serializers.EmailField(write_only=True, required=False, allow_blank=True)
    emergency_contact_number = serializers.CharField(source="emergency_contact", max_length=20, required=False, allow_blank=True)
    employee_type = serializers.PrimaryKeyRelatedField(queryset=EmployeeType.objects.all(), required=False, allow_null=True)
    payroll_group = serializers.PrimaryKeyRelatedField(queryset=PayrollGroup.objects.all(), required=False, allow_null=True)
    # Write-only; reads return only the masked value so the full account number is never sent back.
    bank_account_number = serializers.CharField(write_only=True, required=False, allow_blank=True, max_length=34)

    class Meta:
        model = Employee
        fields = ("id", "employee_code", "first_name", "last_name", "phone_number", "email",
                  "branch", "department", "designation", "joining_date", "is_active",
                  # Basic details
                  "display_name", "employee_type", "door_lock_permission", "pf_number", "uan_number", "esic_number", "address",
                  # Personal information
                  "date_of_birth",
                  # Emergency contact
                  "emergency_contact_number", "emergency_contact_name", "emergency_contact_relation", "emergency_contact_address",
                  # Salary + bank (sensitive)
                  "salary_type", "monthly_salary", "payroll_group",
                  "bank_name", "bank_branch_name", "bank_account_number", "bank_ifsc_code")
        read_only_fields = ("id",)

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data.update({"first_name": instance.user.first_name, "last_name": instance.user.last_name,
                    "name": instance.user.full_name,
                    "phone_number": instance.user.phone_number, "email": instance.user.email})
        request = self.context.get("request")
        allowed = (not self.context.get("summary")) and can_view_sensitive_employee_data(getattr(request, "user", None))
        if allowed:
            data["bank_account_number_masked"] = mask_account_number(instance.bank_account_number)
            data["documents"] = EmployeeDocumentSerializer(instance.documents.all(), many=True).data
        else:
            for field in SENSITIVE_FIELDS:
                data.pop(field, None)
        return data

    def validate(self, attrs):
        request = self.context.get("request")
        if any(field in attrs for field in SENSITIVE_WRITE_FIELDS) and not can_change_sensitive_employee_data(getattr(request, "user", None)):
            raise PermissionDenied("You do not have permission to change salary or bank details.")
        # Never trust client-supplied branch/department/designation ids: for scoped admins they must all
        # resolve to a branch the admin is allowed to manage (SUPERADMIN is unrestricted).
        request = self.context.get("request")
        user = getattr(request, "user", None)
        if user is None or user.has_global_scope:
            return attrs
        allowed = set(user.scoped_branch_ids())
        errors = {}
        if "branch" in attrs or not self.instance:
            branch = attrs.get("branch")
            if branch is None or branch.pk not in allowed:
                errors["branch"] = "Select a branch you are allowed to manage."
        department = attrs.get("department")
        if department is not None and department.branch_id not in allowed:
            errors["department"] = "This department belongs to a branch outside your scope."
        designation = attrs.get("designation")
        if designation is not None and designation.department.branch_id not in allowed:
            errors["designation"] = "This designation belongs to a branch outside your scope."
        if errors:
            raise serializers.ValidationError(errors)
        return attrs

    def validate_date_of_birth(self, value):
        if value and value >= date.today():
            raise serializers.ValidationError("Date of birth must be in the past.")
        return value

    def validate_emergency_contact_number(self, value):
        return normalize_phone_number(value) if value else ""

    def validate_bank_ifsc_code(self, value):
        value = (value or "").strip().upper()
        if value and not IFSC_PATTERN.match(value):
            raise serializers.ValidationError("Enter a valid 11-character IFSC code (e.g. SBIN0001234).")
        return value

    def validate_bank_account_number(self, value):
        value = re.sub(r"\s+", "", value or "")
        if value and not ACCOUNT_NUMBER_PATTERN.match(value):
            raise serializers.ValidationError("Enter a valid account number (6-34 letters or digits).")
        return value

    def _active_or_current(self, value, current):
        if value is not None and not value.is_active and value != current:
            raise serializers.ValidationError("This option is inactive.")
        return value

    def validate_employee_type(self, value):
        return self._active_or_current(value, getattr(self.instance, "employee_type", None))

    def validate_payroll_group(self, value):
        return self._active_or_current(value, getattr(self.instance, "payroll_group", None))

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
        if validated_data.get("bank_account_number") == "":
            validated_data.pop("bank_account_number")  # blank on edit means "keep the stored value"
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


class EmployeeTypeOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = EmployeeType
        fields = ("id", "name", "is_active")
        read_only_fields = fields


class PayrollGroupOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PayrollGroup
        fields = ("id", "name", "is_active")
        read_only_fields = fields