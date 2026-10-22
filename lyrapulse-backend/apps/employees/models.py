import uuid
from decimal import Decimal

from django.conf import settings
from django.core.validators import MinValueValidator, RegexValidator
from django.db import models

from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from apps.employees.storage import private_document_storage


class EmployeeType(models.Model):
    """Dropdown master for "Employee Type". Options are managed in Django Admin (none are assumed)."""
    name = models.CharField(max_length=100, unique=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class PayrollGroup(models.Model):
    """Dropdown master for "Payroll Group". Options are managed in Django Admin (none are assumed)."""
    name = models.CharField(max_length=100, unique=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Employee(models.Model):
    class Gender(models.TextChoices):
        MALE = "MALE", "Male"
        FEMALE = "FEMALE", "Female"
        OTHER = "OTHER", "Other"

    class SalaryType(models.TextChoices):
        MONTHLY = "MONTHLY", "Monthly"
        HOURLY = "HOURLY", "Hourly"
        COMPLIANCE = "COMPLIANCE", "Compliance"

    employee_code = models.CharField(max_length=30, unique=True)
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="employee")
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, related_name="employees", null=True, blank=True)
    department = models.ForeignKey(Department, on_delete=models.PROTECT, related_name="employees", null=True, blank=True)
    designation = models.ForeignKey(Designation, on_delete=models.PROTECT, related_name="employees", null=True, blank=True)
    joining_date = models.DateField(null=True, blank=True)
    profile_photo = models.ImageField(upload_to="employees/", null=True, blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=10, choices=Gender.choices, blank=True)
    emergency_contact = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    # Self-attendance is opt-in for all employees, including existing rows after migration.
    biometric_attendance_enabled = models.BooleanField(default=False)
    mobile_gps_attendance_enabled = models.BooleanField(default=False)
    photo_attendance_enabled = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    # --- Basic Details (Add Details form) ---
    display_name = models.CharField(max_length=150, blank=True)
    employee_type = models.ForeignKey(EmployeeType, on_delete=models.PROTECT, related_name="employees", null=True, blank=True)
    door_lock_permission = models.BooleanField(default=True)
    pf_number = models.CharField(max_length=30, blank=True)
    uan_number = models.CharField(max_length=12, blank=True, validators=[RegexValidator(r"^\d{12}$", "UAN must be exactly 12 digits.")])
    esic_number = models.CharField(max_length=10, blank=True, validators=[RegexValidator(r"^\d{10}$", "ESIC IP number must be exactly 10 digits.")])

    # --- Salary Details (sensitive) ---
    salary_type = models.CharField(max_length=12, choices=SalaryType.choices, default=SalaryType.MONTHLY)
    monthly_salary = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True, validators=[MinValueValidator(Decimal("0"))])
    payroll_group = models.ForeignKey(PayrollGroup, on_delete=models.PROTECT, related_name="employees", null=True, blank=True)

    # --- Bank Details (sensitive) ---
    bank_name = models.CharField(max_length=150, blank=True)
    bank_branch_name = models.CharField(max_length=150, blank=True)
    bank_account_number = models.CharField(max_length=34, blank=True)
    bank_ifsc_code = models.CharField(max_length=11, blank=True)

    # --- Emergency Contact Information (`emergency_contact` above is the contact number) ---
    emergency_contact_name = models.CharField(max_length=150, blank=True)
    emergency_contact_relation = models.CharField(max_length=100, blank=True)
    emergency_contact_address = models.TextField(blank=True)

    class Meta:
        ordering = ["employee_code"]
        permissions = [
            ("view_employee_sensitive", "Can view employee salary, bank details and legal documents"),
            ("change_employee_sensitive", "Can change employee salary, bank details and legal documents"),
        ]

    def __str__(self):
        return f"{self.employee_code} - {self.user.full_name}"


def employee_document_path(instance, filename):
    # Random name: the original filename is kept in `original_name`, never used on disk.
    extension = filename.rsplit(".", 1)[-1].lower() if "." in filename else "bin"
    return f"employee_documents/{instance.employee_id}/{uuid.uuid4().hex}.{extension}"


class EmployeeDocument(models.Model):
    class DocType(models.TextChoices):
        AADHAAR = "AADHAAR", "Aadhar Card"
        DRIVING_LICENCE = "DRIVING_LICENCE", "Driving Licence"
        PAN = "PAN", "Pan Card"
        PHOTO = "PHOTO", "Passport Size Photo"

    class Side(models.TextChoices):
        FRONT = "FRONT", "Front Side"
        BACK = "BACK", "Back Side"
        SINGLE = "SINGLE", "Single"

    employee = models.ForeignKey(Employee, on_delete=models.CASCADE, related_name="documents")
    doc_type = models.CharField(max_length=20, choices=DocType.choices)
    side = models.CharField(max_length=10, choices=Side.choices, default=Side.SINGLE)
    file = models.FileField(upload_to=employee_document_path, storage=private_document_storage)
    original_name = models.CharField(max_length=255)
    content_type = models.CharField(max_length=100)
    size = models.PositiveIntegerField()
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["doc_type", "side"]
        constraints = [
            models.UniqueConstraint(fields=["employee", "doc_type", "side"], name="unique_employee_document_slot"),
        ]

    def __str__(self):
        return f"{self.employee_id} {self.doc_type} {self.side}"


class AttendancePermissionAudit(models.Model):
    employee = models.ForeignKey(Employee, on_delete=models.PROTECT, related_name="attendance_permission_audits")
    actor = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.PROTECT, related_name="attendance_permission_changes")
    previous_values = models.JSONField()
    new_values = models.JSONField()
    changed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-changed_at"]
