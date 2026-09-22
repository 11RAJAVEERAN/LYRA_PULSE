from datetime import date

from django.core.management.base import BaseCommand

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from apps.employees.models import Employee


class Command(BaseCommand):
    help = "Create the documented Lyra Pulse development records."

    def handle(self, *args, **options):
        branch, _ = Branch.objects.get_or_create(code="MAIN", defaults={"name": "Main Branch", "attendance_radius_meters": 3})
        department, _ = Department.objects.get_or_create(branch=branch, name="Development")
        designation, _ = Designation.objects.get_or_create(department=department, name="Python Developer")
        user, _ = User.objects.get_or_create(phone_number="9876543210", defaults={"role": User.Role.EMPLOYEE, "first_name": "Demo", "last_name": "Employee"})
        user.role = User.Role.EMPLOYEE
        user.is_active = True
        user.set_unusable_password()
        user.save(update_fields=["role", "is_active", "password"])
        employee, _ = Employee.objects.get_or_create(
            employee_code="EMP001",
            defaults={"user": user, "branch": branch, "department": department, "designation": designation, "joining_date": date.today()},
        )
        self.stdout.write(self.style.SUCCESS(f"Demo employee ready: {employee.employee_code} / {user.phone_number}"))