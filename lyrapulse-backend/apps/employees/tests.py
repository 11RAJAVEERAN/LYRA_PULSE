from unittest.mock import patch

from django.test import TestCase
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from apps.employees.models import Employee


class EmployeeRegistrationAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            "9000000001",
            role=User.Role.SUPERADMIN,
            is_staff=True,
            is_superuser=True,
        )
        self.hr = User.objects.create_user("9000000002", role=User.Role.HR)
        self.employee_user = User.objects.create_user("9000000003", role=User.Role.EMPLOYEE)
        self.branch = Branch.objects.create(name="Main", code="MAIN")
        self.other_branch = Branch.objects.create(name="Other", code="OTHER")
        self.department = Department.objects.create(name="Development", branch=self.branch)
        self.other_department = Department.objects.create(name="Sales", branch=self.other_branch)
        self.designation = Designation.objects.create(name="Developer", department=self.department)
        self.other_designation = Designation.objects.create(name="Salesperson", department=self.other_department)

    def payload(self, **overrides):
        data = {
            "branch_id": self.branch.id,
            "employee_code": "EMP001",
            "first_name": "Raj",
            "last_name": "Kumar",
            "phone_number": "9876543210",
            "email": "raj@example.com",
            "department_id": self.department.id,
            "designation_id": self.designation.id,
            "joining_date": "2026-10-08",
            "is_active": True,
        }
        data.update(overrides)
        return data

    def assert_field_error(self, response, field):
        self.assertIn(field, response.data["errors"])

    def test_hr_can_register_employee_and_returns_employee_id(self):
        self.client.force_authenticate(self.hr)

        response = self.client.post("/api/v1/employees/", self.payload(), format="json")

        self.assertEqual(response.status_code, 201)
        self.assertTrue(response.data["success"])
        self.assertEqual(response.data["message"], "Employee created successfully")
        data = response.data["data"]
        employee = Employee.objects.get(pk=data["id"])
        self.assertEqual(data["employee_code"], "EMP001")
        self.assertEqual(data["name"], "Raj Kumar")
        self.assertEqual(data["phone_number"], "9876543210")
        self.assertEqual(employee.user.role, User.Role.EMPLOYEE)
        self.assertFalse(employee.user.has_usable_password())
        self.assertEqual(employee.branch, self.branch)
        self.assertEqual(employee.department, self.department)
        self.assertEqual(employee.designation, self.designation)
        self.assertEqual(employee.user.is_active, employee.is_active)

    def test_superadmin_can_register_employee(self):
        self.client.force_authenticate(self.admin)

        response = self.client.post("/api/v1/employees/", self.payload(), format="json")

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["data"]["employee_code"], "EMP001")

    def test_duplicate_employee_code_is_rejected(self):
        existing_user = User.objects.create_user("9876543211")
        Employee.objects.create(employee_code="EMP001", user=existing_user)
        self.client.force_authenticate(self.hr)

        response = self.client.post("/api/v1/employees/", self.payload(phone_number="9876543212"), format="json")

        self.assertEqual(response.status_code, 400)
        self.assert_field_error(response, "employee_code")

    def test_duplicate_phone_number_is_rejected(self):
        User.objects.create_user("9876543210")
        self.client.force_authenticate(self.hr)

        response = self.client.post("/api/v1/employees/", self.payload(), format="json")

        self.assertEqual(response.status_code, 400)
        self.assert_field_error(response, "phone_number")

    def test_duplicate_email_is_allowed(self):
        User.objects.create_user("9876543211", email="raj@example.com")
        self.client.force_authenticate(self.hr)

        response = self.client.post("/api/v1/employees/", self.payload(), format="json")

        self.assertEqual(response.status_code, 201)

    def test_inactive_employee_and_user_states_remain_synchronized(self):
        self.client.force_authenticate(self.hr)

        response = self.client.post("/api/v1/employees/", self.payload(is_active=False), format="json")

        self.assertEqual(response.status_code, 201)
        employee = Employee.objects.get(pk=response.data["data"]["id"])
        self.assertFalse(employee.is_active)
        self.assertFalse(employee.user.is_active)

    def test_arbitrary_user_fields_are_rejected(self):
        self.client.force_authenticate(self.hr)

        response = self.client.post(
            "/api/v1/employees/",
            self.payload(role=User.Role.SUPERADMIN, is_superuser=True),
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("errors", response.data)
        self.assertFalse(User.objects.filter(phone_number="9876543210").exists())

    def test_invalid_branch_is_rejected(self):
        self.client.force_authenticate(self.hr)

        response = self.client.post("/api/v1/employees/", self.payload(branch_id=99999), format="json")

        self.assertEqual(response.status_code, 400)
        self.assert_field_error(response, "branch_id")

    def test_inactive_branch_is_rejected(self):
        inactive_branch = Branch.objects.create(name="Inactive", code="INACTIVE", is_active=False)
        self.client.force_authenticate(self.hr)

        response = self.client.post("/api/v1/employees/", self.payload(branch_id=inactive_branch.id), format="json")

        self.assertEqual(response.status_code, 400)
        self.assert_field_error(response, "branch_id")

    def test_invalid_department_is_rejected(self):
        self.client.force_authenticate(self.hr)

        response = self.client.post("/api/v1/employees/", self.payload(department_id=99999), format="json")

        self.assertEqual(response.status_code, 400)
        self.assert_field_error(response, "department_id")

    def test_department_must_belong_to_selected_branch(self):
        self.client.force_authenticate(self.hr)

        response = self.client.post(
            "/api/v1/employees/",
            self.payload(department_id=self.other_department.id, designation_id=None),
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assert_field_error(response, "department_id")

    def test_invalid_designation_is_rejected(self):
        self.client.force_authenticate(self.hr)

        response = self.client.post("/api/v1/employees/", self.payload(designation_id=99999), format="json")

        self.assertEqual(response.status_code, 400)
        self.assert_field_error(response, "designation_id")

    def test_designation_must_belong_to_selected_department(self):
        self.client.force_authenticate(self.hr)

        response = self.client.post(
            "/api/v1/employees/",
            self.payload(designation_id=self.other_designation.id),
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assert_field_error(response, "designation_id")

    def test_employee_role_cannot_register_employee(self):
        self.client.force_authenticate(self.employee_user)

        response = self.client.post("/api/v1/employees/", self.payload(), format="json")

        self.assertEqual(response.status_code, 403)
        self.assertEqual(User.objects.filter(phone_number="9876543210").count(), 0)

    def test_registration_requires_authentication(self):
        response = self.client.post("/api/v1/employees/", self.payload(), format="json")

        self.assertEqual(response.status_code, 401)

    def test_user_creation_rolls_back_if_employee_creation_fails(self):
        self.client.force_authenticate(self.hr)

        with patch.object(Employee.objects, "create", side_effect=RuntimeError("forced employee failure")):
            with self.assertRaises(RuntimeError):
                self.client.post("/api/v1/employees/", self.payload(), format="json")

        self.assertFalse(User.objects.filter(phone_number="9876543210").exists())
        self.assertFalse(Employee.objects.filter(employee_code="EMP001").exists())


class BranchListAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.hr = User.objects.create_user("9000000011", role=User.Role.HR)
        self.employee = User.objects.create_user("9000000012", role=User.Role.EMPLOYEE)
        self.active_branch = Branch.objects.create(name="Main", code="MAIN")
        Branch.objects.create(name="Inactive", code="INACTIVE", is_active=False)

    def test_hr_sees_only_active_branches(self):
        self.client.force_authenticate(self.hr)

        response = self.client.get("/api/v1/branches/")

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["success"])
        self.assertEqual(response.data["message"], "Branches retrieved successfully")
        self.assertEqual([branch["id"] for branch in response.data["data"]], [self.active_branch.id])
        self.assertEqual(response.data["data"][0]["code"], "MAIN")

    def test_branch_list_rejects_employee_role(self):
        self.client.force_authenticate(self.employee)

        response = self.client.get("/api/v1/branches/")

        self.assertEqual(response.status_code, 403)

    def test_branch_list_requires_authentication(self):
        response = self.client.get("/api/v1/branches/")

        self.assertEqual(response.status_code, 401)

    def test_empty_branch_list_returns_empty_array(self):
        Branch.objects.all().delete()
        self.client.force_authenticate(self.hr)

        response = self.client.get("/api/v1/branches/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"], [])
