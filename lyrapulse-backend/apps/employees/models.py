from django.conf import settings
from django.db import models

from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation


class Employee(models.Model):
    class Gender(models.TextChoices):
        MALE = "MALE", "Male"
        FEMALE = "FEMALE", "Female"
        OTHER = "OTHER", "Other"

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
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["employee_code"]

    def __str__(self):
        return f"{self.employee_code} - {self.user.full_name}"