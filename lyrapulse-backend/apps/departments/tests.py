from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from apps.employees.models import Employee
from apps.organizations.models import Organization


@override_settings(ROOT_URLCONF="config.urls")
class DepartmentAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Department Org", code="DEPORG")
        self.other_org = Organization.objects.create(name="Other Org", code="OTHER")
        self.branch = Branch.objects.create(organization=self.org, name="Main", code="DEPMAIN")
        self.other_branch = Branch.objects.create(organization=self.other_org, name="Other", code="DEPOUT")
        self.owner = User.objects.create_user("9000001111", role=User.Role.SUPERADMIN, organization=self.org)
        self.client.force_authenticate(self.owner)

    def test_department_crud_counts_and_scope(self):
        department = Department.objects.create(name="Kitchen", branch=self.branch)
        designation = Designation.objects.create(name="Chef", department=department)
        employee_user = User.objects.create_user("9000001112")
        Employee.objects.create(employee_code="DEP-EMP", user=employee_user, branch=self.branch, department=department, designation=designation)

        response = self.client.get("/api/v1/departments/", {"include_inactive": "true"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"][0]["employee_count"], 1)
        self.assertEqual(response.data["data"][0]["designation_count"], 1)
        self.assertEqual(self.client.get("/api/v1/departments/", {"branch": self.other_branch.pk}).data["data"], [])

        response = self.client.post("/api/v1/departments/", {"name": "Front Office", "branch": self.branch.pk}, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        created_id = response.data["data"]["id"]
        self.assertEqual(self.client.patch(f"/api/v1/departments/{created_id}/", {"is_active": False}, format="json").status_code, 200)
        self.assertEqual(self.client.patch(f"/api/v1/departments/{department.pk}/", {"name": "Invalid", "branch": self.other_branch.pk}, format="json").status_code, 404)
        self.assertEqual(self.client.get(f"/api/v1/departments/{department.pk}/").status_code, 405)
        self.assertEqual(self.client.delete(f"/api/v1/departments/{department.pk}/").status_code, 409)
        outside = Department.objects.create(name="Elsewhere", branch=self.other_branch)
        self.assertEqual(self.client.patch(f"/api/v1/departments/{outside.pk}/", {"name": "Changed"}, format="json").status_code, 404)

    def test_department_creation_requires_authentication(self):
        self.client.force_authenticate(user=None)
        self.assertEqual(self.client.get("/api/v1/departments/").status_code, 401)



