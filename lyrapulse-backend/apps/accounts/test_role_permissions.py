from django.test import TestCase
from django.utils import timezone
from django.contrib.auth.models import Permission
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import User
from apps.accounts.services.role_permissions import ensure_role_group
from apps.attendance.models import Attendance
from apps.branches.models import Branch
from apps.employees.models import Employee
from apps.organizations.models import Organization


class BranchRolePermissionTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.company_a = Organization.objects.create(name="Disposable A", code="ROLE-A")
        self.company_b = Organization.objects.create(name="Disposable B", code="ROLE-B")
        self.a_branch_1 = Branch.objects.create(organization=self.company_a, name="A Branch 1", code="ROLE-A1")
        self.a_branch_2 = Branch.objects.create(organization=self.company_a, name="A Branch 2", code="ROLE-A2")
        self.b_branch = Branch.objects.create(organization=self.company_b, name="B Branch", code="ROLE-B1")

        self.platform = self.make_user("9900000000", User.Role.SUPERADMIN, superuser=True)
        self.company_admin = self.make_user(
            "9900000001", User.Role.SUPERADMIN, organization=self.company_a,
        )
        self.branch_admin = self.make_user(
            "9900000002", User.Role.ADMIN, self.company_a, [self.a_branch_1],
        )
        self.hr = self.make_user("9900000003", User.Role.HR, self.company_a, [self.a_branch_1])
        self.manager = self.make_user("9900000004", User.Role.MANAGER, self.company_a, [self.a_branch_1])
        self.employee_user_a = self.make_user("9900000005", User.Role.EMPLOYEE)
        self.employee_user_b = self.make_user("9900000006", User.Role.EMPLOYEE)
        self.employee_a = Employee.objects.create(
            employee_code="ROLE-EMP-A",
            user=self.employee_user_a,
            branch=self.a_branch_1,
        )
        self.employee_b = Employee.objects.create(
            employee_code="ROLE-EMP-B",
            user=self.employee_user_b,
            branch=self.b_branch,
        )
        Attendance.objects.create(
            employee=self.employee_a,
            branch=self.a_branch_1,
            attendance_date=timezone.localdate(),
            check_in_at=timezone.now(),
        )

    def make_user(self, phone, role, organization=None, branches=None, superuser=False):
        user = User.objects.create_user(
            phone_number=phone,
            role=role,
            organization=organization,
            is_superuser=superuser,
            is_staff=superuser,
        )
        if branches:
            user.allowed_branches.set(branches)
        if role in (User.Role.ADMIN, User.Role.HR, User.Role.MANAGER):
            user.groups.add(ensure_role_group(role))
        return user

    def authenticate(self, user):
        token = str(RefreshToken.for_user(user).access_token)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

    def test_platform_superadmin_sees_employees_across_companies(self):
        self.authenticate(self.platform)
        response = self.client.get("/api/v1/employees/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            {row["employee_code"] for row in response.data["data"]},
            {"ROLE-EMP-A", "ROLE-EMP-B"},
        )

    def test_company_superadmin_is_limited_to_its_organization(self):
        self.authenticate(self.company_admin)
        response = self.client.get("/api/v1/branches/", {"status": "all"})
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            {row["id"] for row in response.data["data"]},
            {self.a_branch_1.pk, self.a_branch_2.pk},
        )
        self.assertEqual(self.client.get(f"/api/v1/branches/{self.b_branch.pk}/").status_code, 404)
        employee_list = self.client.get("/api/v1/employees/")
        self.assertEqual(
            {row["employee_code"] for row in employee_list.data["data"]},
            {"ROLE-EMP-A"},
        )

    def test_branch_admin_is_scoped_to_assigned_branches(self):
        self.authenticate(self.branch_admin)
        response = self.client.get("/api/v1/employees/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual([row["employee_code"] for row in response.data["data"]], ["ROLE-EMP-A"])
        self.assertEqual(self.client.get(f"/api/v1/employees/{self.employee_b.pk}/").status_code, 404)
        self.assertEqual(self.client.get(f"/api/v1/branches/{self.a_branch_2.pk}/").status_code, 404)
        self.assertEqual(
            self.client.post("/api/v1/employees/", {}).status_code,
            400,
        )

    def test_hr_can_manage_employees_and_view_attendance_within_assignment(self):
        self.authenticate(self.hr)
        response = self.client.get("/api/v1/employees/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual([row["employee_code"] for row in response.data["data"]], ["ROLE-EMP-A"])
        attendance = self.client.get("/api/v1/attendance/admin/")
        self.assertEqual(attendance.status_code, 200)
        detail = self.client.get(f"/api/v1/attendance/admin/{self.employee_b.pk}/")
        self.assertEqual(detail.status_code, 404)
        export = self.client.get("/api/v1/attendance/admin/export/")
        self.assertEqual(export.status_code, 200)
        exported = b"".join(export.streaming_content).decode("utf-8-sig")
        self.assertIn("ROLE-EMP-A", exported)
        self.assertNotIn("ROLE-EMP-B", exported)

    def test_manager_is_limited_to_assigned_branches_and_read_actions(self):
        self.authenticate(self.manager)
        response = self.client.get("/api/v1/employees/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual([row["employee_code"] for row in response.data["data"]], ["ROLE-EMP-A"])
        self.assertEqual(self.client.get(f"/api/v1/employees/{self.employee_b.pk}/").status_code, 404)
        self.assertEqual(self.client.post("/api/v1/employees/", {}).status_code, 403)
        self.assertEqual(self.client.get("/api/v1/auth/admin/users/").status_code, 403)
        self.manager.user_permissions.add(Permission.objects.get(
            codename="add_employee",
            content_type__app_label="employees",
        ))
        self.assertEqual(self.client.post("/api/v1/employees/", {}).status_code, 403)
        self.assertEqual(self.client.get("/api/v1/devices/").status_code, 403)

    def test_employee_cannot_access_administrative_apis(self):
        self.authenticate(self.employee_user_a)
        self.assertEqual(self.client.get("/api/v1/employees/").status_code, 403)
        self.assertEqual(self.client.get("/api/v1/branches/").status_code, 403)
        self.assertEqual(self.client.get("/api/v1/attendance/admin/").status_code, 403)

    def test_company_superadmin_creates_staff_with_own_branch_scope(self):
        self.authenticate(self.company_admin)
        response = self.client.post("/api/v1/auth/admin/users/", {
            "phone_number": "9900000010",
            "role": "HR",
            "organization": self.company_a.pk,
            "branch_ids": [self.a_branch_1.pk],
        }, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        account = User.objects.get(phone_number="9900000010")
        self.assertEqual(account.organization_id, self.company_a.pk)
        self.assertEqual(list(account.allowed_branches.values_list("pk", flat=True)), [self.a_branch_1.pk])
        self.assertEqual(
            self.client.patch(f"/api/v1/auth/admin/users/{account.pk}/", {
                "first_name": "Updated",
            }, format="json").status_code,
            200,
        )
        self.assertEqual(User.objects.filter(phone_number="9900000010").count(), 1)

    def test_staff_creation_rejects_escalation_and_cross_company_branches(self):
        self.authenticate(self.company_admin)
        base = {
            "phone_number": "9900000011",
            "role": "HR",
            "organization": self.company_a.pk,
            "branch_ids": [self.a_branch_1.pk],
        }
        escalation = self.client.post(
            "/api/v1/auth/admin/users/",
            {**base, "role": "SUPERADMIN", "is_superuser": True},
            format="json",
        )
        self.assertEqual(escalation.status_code, 400)
        permission_escalation = self.client.post(
            "/api/v1/auth/admin/users/",
            {**base, "phone_number": "9900000014", "role": "MANAGER", "permissions": ["employees.change_employee"]},
            format="json",
        )
        self.assertEqual(permission_escalation.status_code, 400)
        cross_branch = self.client.post(
            "/api/v1/auth/admin/users/",
            {**base, "phone_number": "9900000012", "branch_ids": [self.b_branch.pk]},
            format="json",
        )
        self.assertEqual(cross_branch.status_code, 400)
        self.assertFalse(User.objects.filter(phone_number__in=("9900000011", "9900000012", "9900000014")).exists())

    def test_company_admin_cannot_list_or_assign_staff_outside_organization(self):
        self.authenticate(self.company_admin)
        response = self.client.get("/api/v1/auth/admin/users/")
        self.assertEqual(response.status_code, 200)
        created = self.client.post("/api/v1/auth/admin/users/", {
            "phone_number": "9900000013",
            "role": "MANAGER",
            "organization": self.company_b.pk,
            "branch_ids": [self.b_branch.pk],
        }, format="json")
        self.assertEqual(created.status_code, 400)
        self.assertFalse(User.objects.filter(phone_number="9900000013").exists())
