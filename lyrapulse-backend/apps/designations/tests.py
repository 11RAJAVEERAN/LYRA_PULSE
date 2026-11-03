from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from apps.employees.models import Employee
from apps.organizations.models import Organization


@override_settings(ROOT_URLCONF="config.urls")
class DesignationAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Designation Org", code="DESORG")
        self.other_org = Organization.objects.create(name="Other Org", code="DESOTHER")
        self.branch = Branch.objects.create(organization=self.org, name="Main", code="DESMAIN")
        self.other_branch = Branch.objects.create(organization=self.other_org, name="Other", code="DESOUT")
        self.department = Department.objects.create(name="Kitchen", branch=self.branch)
        self.owner = User.objects.create_user("9000002221", role=User.Role.SUPERADMIN, organization=self.org)
        self.client.force_authenticate(self.owner)

    def test_designation_crud_filters_counts_and_scope(self):
        designation = Designation.objects.create(name="Chef", department=self.department)
        employee_user = User.objects.create_user("9000002222")
        Employee.objects.create(employee_code="DES-EMP", user=employee_user, branch=self.branch, department=self.department, designation=designation)
        response = self.client.get("/api/v1/designations/", {"department": self.department.pk})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"][0]["employee_count"], 1)
        self.assertEqual(self.client.get("/api/v1/designations/", {"branch": self.other_branch.pk}).data["data"], [])

        response = self.client.post("/api/v1/designations/", {"name": "Cook", "department": self.department.pk}, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        created_id = response.data["data"]["id"]
        self.assertEqual(self.client.patch(f"/api/v1/designations/{created_id}/", {"is_active": False}, format="json").status_code, 200)
        other_department = Department.objects.create(name="Other Dept", branch=self.other_branch)
        self.assertEqual(self.client.post("/api/v1/designations/", {"name": "Other", "department": other_department.pk}, format="json").status_code, 404)
        self.assertEqual(self.client.patch(f"/api/v1/designations/{designation.pk}/", {"department": other_department.pk}, format="json").status_code, 404)
        self.assertEqual(self.client.delete(f"/api/v1/designations/{designation.pk}/").status_code, 409)
        other_designation = Designation.objects.create(name="Outside", department=other_department)
        self.assertEqual(self.client.patch(f"/api/v1/designations/{other_designation.pk}/", {"name": "Changed"}, format="json").status_code, 404)

    def test_designation_creation_requires_authentication(self):
        self.client.force_authenticate(user=None)
        self.assertEqual(self.client.get("/api/v1/designations/").status_code, 401)


