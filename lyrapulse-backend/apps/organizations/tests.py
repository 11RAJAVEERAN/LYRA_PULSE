from datetime import date
from unittest.mock import patch

from django.core.exceptions import ValidationError
from django.core.management import call_command, CommandError
from django.db import IntegrityError, transaction
from django.contrib.auth.models import Permission
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import OTPVerification, User
from apps.attendance.models import Attendance
from apps.branches.models import Branch
from apps.devices.models import Device
from apps.employees.models import Employee

from .models import Organization


class CompanyManagementTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.platform = User.objects.create_user(
            "9000000000", role=User.Role.SUPERADMIN, is_staff=True, is_superuser=True,
        )
        self.client.force_authenticate(self.platform)

    def create_company(self, name="Company", code="COMPANY"):
        response = self.client.post("/api/v1/organizations/", {"name": name, "code": code}, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        return Organization.objects.get(pk=response.data["data"]["id"])

    def create_branch(self, organization, name, code):
        return Branch.objects.create(organization=organization, name=name, code=code)

    def test_device_provisioning_returns_a_working_one_time_token(self):
        organization = self.create_company("Device Company", "DEVICE-COMPANY")
        branch = self.create_branch(organization, "Device Branch", "DEVICE-BRANCH")

        response = self.client.post(
            "/api/v1/devices/",
            {"device_id": "DEVICE-ONE", "branch_id": branch.pk},
            format="json",
        )

        self.assertEqual(response.status_code, 201, response.data)
        token = response.data["data"]["provisioning_token"]
        device = Device.objects.get(device_id="DEVICE-ONE")
        self.assertTrue(device.verify_token(token))
        self.assertNotIn("token_hash", response.data["data"])
        self.assertNotIn(token, str(self.client.get("/api/v1/devices/").data))

    def test_device_provisioning_rejects_a_second_device_for_the_branch(self):
        organization = self.create_company("Single Device Company", "SINGLE-DEVICE")
        branch = self.create_branch(organization, "Single Device Branch", "SINGLE-DEVICE-BRANCH")
        existing = Device(device_id="DEVICE-EXISTING", branch=branch)
        existing.set_token("test-only-device-token")
        existing.save()

        response = self.client.post(
            "/api/v1/devices/",
            {"device_id": "DEVICE-SECOND", "branch_id": branch.pk},
            format="json",
        )

        self.assertEqual(response.status_code, 400, response.data)
        self.assertIn("branch_id", response.data["errors"])
        self.assertEqual(Device.objects.filter(branch=branch).count(), 1)

    def test_branch_admin_can_provision_only_for_an_assigned_branch(self):
        organization = self.create_company("Scoped Device Company", "SCOPED-DEVICE")
        allowed_branch = self.create_branch(organization, "Allowed Branch", "SCOPED-ALLOWED")
        other_branch = self.create_branch(organization, "Other Branch", "SCOPED-OTHER")
        branch_admin = User.objects.create_user(
            "9000000091",
            role=User.Role.ADMIN,
            organization=organization,
        )
        permission = Permission.objects.get(
            content_type__app_label="employees",
            codename="view_employee",
        )
        branch_admin.user_permissions.add(permission)
        branch_admin.allowed_branches.add(allowed_branch)
        self.client.force_authenticate(branch_admin)

        allowed = self.client.post(
            "/api/v1/devices/",
            {"device_id": "SCOPED-ALLOWED-DEVICE", "branch_id": allowed_branch.pk},
            format="json",
        )
        outside_scope = self.client.post(
            "/api/v1/devices/",
            {"device_id": "SCOPED-OUTSIDE-DEVICE", "branch_id": other_branch.pk},
            format="json",
        )

        self.assertEqual(allowed.status_code, 201, allowed.data)
        self.assertEqual(outside_scope.status_code, 404, outside_scope.data)
        self.assertFalse(Device.objects.filter(device_id="SCOPED-OUTSIDE-DEVICE").exists())

    def test_device_branch_constraint_rejects_direct_duplicate_assignment(self):
        organization = self.create_company("Constraint Company", "CONSTRAINT-COMPANY")
        branch = self.create_branch(organization, "Constraint Branch", "CONSTRAINT-BRANCH")
        first = Device(device_id="CONSTRAINT-ONE", branch=branch)
        first.set_token("test-only-first-token")
        first.save()
        second = Device(device_id="CONSTRAINT-TWO", branch=branch)
        second.set_token("test-only-second-token")

        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                second.save()

        self.assertEqual(Device.objects.filter(branch=branch).count(), 1)

    def test_branch_unique_constraint_race_returns_validation_error(self):
        organization = self.create_company("Race Company", "RACE-COMPANY")
        branch = self.create_branch(organization, "Race Branch", "RACE-BRANCH")
        existing = Device(device_id="RACE-EXISTING", branch=branch)
        existing.set_token("test-only-race-token")
        existing.save()

        manager = Device.objects
        original_filter = manager.filter
        stale_preflight = [True]

        def filter_with_stale_branch_read(*args, **kwargs):
            queryset = original_filter(*args, **kwargs)
            if kwargs == {"branch": branch} and stale_preflight[0]:
                stale_preflight[0] = False
                return queryset.none()
            return queryset

        with patch.object(manager, "filter", side_effect=filter_with_stale_branch_read):
            response = self.client.post(
                "/api/v1/devices/",
                {"device_id": "RACE-SECOND", "branch_id": branch.pk},
                format="json",
            )

        self.assertFalse(stale_preflight[0])
        self.assertEqual(response.status_code, 400, response.data)
        self.assertIn("branch_id", response.data["errors"])
        self.assertEqual(Device.objects.filter(branch=branch).count(), 1)

    def test_provision_command_rejects_a_branch_that_already_has_a_device(self):
        organization = self.create_company("Command Company", "COMMAND-COMPANY")
        branch = self.create_branch(organization, "Command Branch", "COMMAND-BRANCH")
        existing = Device(device_id="COMMAND-EXISTING", branch=branch)
        existing.set_token("test-only-command-token")
        existing.save()

        with self.assertRaisesMessage(CommandError, "already has a registered"):
            call_command(
                "provision_device",
                device_id="COMMAND-SECOND",
                branch_code=branch.code,
            )

        self.assertEqual(Device.objects.filter(branch=branch).count(), 1)

    def test_new_branch_radius_defaults_to_40_and_api_accepts_range_endpoints(self):
        organization = self.create_company("Radius Company", "RADIUS")
        created = self.client.post(
            "/api/v1/branches/",
            {"name": "Default Radius", "code": "RADIUS-DEFAULT", "organization_id": organization.pk},
            format="json",
        )
        self.assertEqual(created.status_code, 201, created.data)
        default_branch = Branch.objects.get(pk=created.data["data"]["id"])
        self.assertEqual(default_branch.attendance_radius_meters, 40)

        for radius in (10, 100):
            with self.subTest(updated_radius=radius):
                response = self.client.patch(
                    f"/api/v1/branches/{default_branch.pk}/",
                    {"attendance_radius_meters": radius},
                    format="json",
                )
                self.assertEqual(response.status_code, 200, response.data)
                default_branch.refresh_from_db()
                self.assertEqual(default_branch.attendance_radius_meters, radius)

        minimum = self.client.post(
            "/api/v1/branches/",
            {
                "name": "Minimum Radius", "code": "RADIUS-MIN",
                "organization_id": organization.pk, "attendance_radius_meters": 10,
            },
            format="json",
        )
        maximum = self.client.post(
            "/api/v1/branches/",
            {
                "name": "Maximum Radius", "code": "RADIUS-MAX",
                "organization_id": organization.pk, "attendance_radius_meters": 100,
            },
            format="json",
        )
        self.assertEqual(minimum.status_code, 201, minimum.data)
        self.assertEqual(maximum.status_code, 201, maximum.data)

        for code, radius in (("RADIUS-LOW", 9), ("RADIUS-HIGH", 101)):
            with self.subTest(radius=radius):
                response = self.client.post(
                    "/api/v1/branches/",
                    {
                        "name": "Invalid Radius", "code": code,
                        "organization_id": organization.pk, "attendance_radius_meters": radius,
                    },
                    format="json",
                )
                self.assertEqual(response.status_code, 400, response.data)
                self.assertFalse(Branch.objects.filter(code=code).exists())

    def test_legacy_radius_is_preserved_on_unrelated_edit_and_rejected_when_resubmitted(self):
        organization = self.create_company("Legacy Radius Company", "LEGACY-RADIUS")
        branch = self.create_branch(organization, "Legacy Radius", "LEGACY-RADIUS-1")
        Branch.objects.filter(pk=branch.pk).update(attendance_radius_meters=150)

        unrelated_edit = self.client.patch(
            f"/api/v1/branches/{branch.pk}/",
            {"name": "Renamed Legacy Radius"},
            format="json",
        )
        self.assertEqual(unrelated_edit.status_code, 200, unrelated_edit.data)
        branch.refresh_from_db()
        self.assertEqual(branch.name, "Renamed Legacy Radius")
        self.assertEqual(branch.attendance_radius_meters, 150)

        invalid_radius_edit = self.client.patch(
            f"/api/v1/branches/{branch.pk}/",
            {"attendance_radius_meters": 150},
            format="json",
        )
        self.assertEqual(invalid_radius_edit.status_code, 400, invalid_radius_edit.data)
        branch.refresh_from_db()
        self.assertEqual(branch.attendance_radius_meters, 150)

    def test_model_preserves_unchanged_legacy_radius_but_validates_changes(self):
        organization = self.create_company("Model Radius Company", "MODEL-RADIUS")
        branch = self.create_branch(organization, "Legacy Model Radius", "MODEL-RADIUS-1")
        Branch.objects.filter(pk=branch.pk).update(attendance_radius_meters=150)
        branch.refresh_from_db()
        branch.name = "Updated Name"
        branch.full_clean()
        branch.save()
        self.assertEqual(Branch.objects.get(pk=branch.pk).attendance_radius_meters, 150)

        branch.attendance_radius_meters = 101
        with self.assertRaises(ValidationError) as context:
            branch.full_clean()
        self.assertIn("attendance_radius_meters", context.exception.message_dict)
        with self.assertRaises(ValidationError):
            branch.save()

    def test_platform_superadmin_can_create_multiple_companies(self):
        first = self.create_company("First Company", "FIRST")
        second = self.create_company("Second Company", "SECOND")
        self.assertNotEqual(first.pk, second.pk)
        response = self.client.get("/api/v1/organizations/", {"search": "Company", "status": "active"})
        self.assertEqual({row["id"] for row in response.data["data"]}, {first.pk, second.pk})
        self.assertEqual(self.client.get(f"/api/v1/organizations/{first.pk}/").status_code, 200)

    def test_company_superadmin_is_scoped_to_own_company(self):
        own = self.create_company("Own", "OWN")
        other = self.create_company("Other", "OTHER")
        own_branch = self.create_branch(own, "Own Branch", "OWN-1")
        other_branch = self.create_branch(other, "Other Branch", "OTHER-1")
        company_admin = User.objects.create_user("9000000001", role=User.Role.SUPERADMIN, organization=own)
        self.client.force_authenticate(company_admin)

        self.assertEqual(self.client.get(f"/api/v1/organizations/{own.pk}/").status_code, 200)
        self.assertEqual(self.client.get(f"/api/v1/organizations/{other.pk}/").status_code, 404)
        branches = self.client.get("/api/v1/branches/", {"status": "all"})
        self.assertEqual({row["id"] for row in branches.data["data"]}, {own_branch.pk})
        self.assertEqual(self.client.get(f"/api/v1/branches/{other_branch.pk}/").status_code, 404)

    def test_company_supports_multiple_company_superadmins_and_safe_deactivation(self):
        organization = self.create_company()
        first = User.objects.create_user("9000000001", role=User.Role.SUPERADMIN, organization=organization)
        self.client.force_authenticate(first)
        created = self.client.post(
            f"/api/v1/organizations/{organization.pk}/super-admins/",
            {"phone_number": "9000000002", "first_name": "Second"},
            format="json",
        )
        self.assertEqual(created.status_code, 201, created.data)
        second = User.objects.get(pk=created.data["data"]["id"])
        self.assertEqual(second.organization, organization)
        self.assertFalse(second.is_superuser)
        self.assertEqual(second.role, User.Role.SUPERADMIN)
        listing = self.client.get(f"/api/v1/organizations/{organization.pk}/super-admins/")
        self.assertEqual(len(listing.data["data"]), 2)

        disabled = self.client.patch(
            f"/api/v1/organizations/{organization.pk}/super-admins/{second.pk}/",
            {"is_active": False}, format="json",
        )
        self.assertEqual(disabled.status_code, 200)
        last_admin = self.client.patch(
            f"/api/v1/organizations/{organization.pk}/super-admins/{first.pk}/",
            {"is_active": False}, format="json",
        )
        self.assertEqual(last_admin.status_code, 400)

    def test_only_platform_superadmin_can_reassign_company_superadmin(self):
        source = self.create_company("Source", "SOURCE")
        target = self.create_company("Target", "TARGET")
        account = User.objects.create_user("9000000004", role=User.Role.SUPERADMIN, organization=source)
        company_admin = User.objects.create_user("9000000005", role=User.Role.SUPERADMIN, organization=source)
        self.client.force_authenticate(company_admin)
        denied = self.client.patch(
            f"/api/v1/organizations/{source.pk}/super-admins/{account.pk}/",
            {"organization_id": target.pk}, format="json",
        )
        self.assertEqual(denied.status_code, 400)
        account.refresh_from_db()
        self.assertEqual(account.organization, source)

        self.client.force_authenticate(self.platform)
        moved = self.client.patch(
            f"/api/v1/organizations/{source.pk}/super-admins/{account.pk}/",
            {"organization_id": target.pk}, format="json",
        )
        self.assertEqual(moved.status_code, 200, moved.data)
        account.refresh_from_db()
        self.assertEqual(account.organization, target)
        self.assertFalse(account.is_superuser)

    def test_company_superadmin_can_manage_only_own_branches(self):
        own = self.create_company("Own", "OWN")
        other = self.create_company("Other", "OTHER")
        company_admin = User.objects.create_user("9000000001", role=User.Role.SUPERADMIN, organization=own)
        self.client.force_authenticate(company_admin)

        created = self.client.post("/api/v1/branches/", {"name": "New", "code": "OWN-NEW"}, format="json")
        self.assertEqual(created.status_code, 201, created.data)
        branch = Branch.objects.get(pk=created.data["data"]["id"])
        self.assertEqual(branch.organization, own)
        second = self.client.post("/api/v1/branches/", {"name": "Second", "code": "OWN-2"}, format="json")
        self.assertEqual(second.status_code, 201, second.data)
        self.assertEqual(len(self.client.get("/api/v1/branches/", {"status": "all"}).data["data"]), 2)

        inactive = self.client.patch(f"/api/v1/branches/{branch.pk}/", {"is_active": False}, format="json")
        self.assertEqual(inactive.status_code, 200)
        self.assertFalse(Branch.objects.get(pk=branch.pk).is_active)
        other_branch = self.create_branch(other, "Outside", "OTHER-1")
        self.assertEqual(self.client.patch(f"/api/v1/branches/{other_branch.pk}/", {"name": "Hack"}, format="json").status_code, 404)
        cross_company = self.client.post("/api/v1/branches/", {
            "name": "Cross", "code": "CROSS", "organization_id": other.pk,
        }, format="json")
        self.assertEqual(cross_company.status_code, 400)

    def test_platform_rejects_invalid_company_and_can_assign_legacy_branch(self):
        invalid = self.client.post("/api/v1/branches/", {
            "name": "Invalid", "code": "INVALID", "organization_id": 999999,
        }, format="json")
        self.assertEqual(invalid.status_code, 400)

        organization = self.create_company()
        branch = Branch.objects.create(name="Main Branch", code="MAIN")
        employee_user = User.objects.create_user("9000000003", role=User.Role.EMPLOYEE)
        employee = Employee.objects.create(employee_code="EMP-LEGACY", user=employee_user, branch=branch)
        attendance = Attendance.objects.create(
            employee=employee,
            branch=branch,
            attendance_date=date.today(),
            check_in_at=timezone.now(),
        )
        response = self.client.patch(
            f"/api/v1/branches/{branch.pk}/",
            {"organization_id": organization.pk},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.data)
        branch.refresh_from_db()
        attendance.refresh_from_db()
        self.assertEqual(branch.organization, organization)
        self.assertEqual(employee.branch_id, branch.pk)
        self.assertEqual(attendance.branch_id, branch.pk)
        self.assertTrue(Attendance.objects.filter(pk=attendance.pk).exists())

    def test_inactive_company_cannot_accept_device_punches(self):
        organization = Organization.objects.create(name="Suspended", code="SUSP", is_active=False)
        branch = self.create_branch(organization, "Suspended Branch", "SUSP-1")
        device = Device(device_id="SUSP-DEVICE", branch=branch, token_hash="")
        device.set_token("test-device-token")
        device.save()
        device_client = APIClient()
        response = device_client.post(
            "/api/v1/attendance/fingerprint/events/",
            {
                "device_id": device.device_id,
                "event_id": "4e8cc430-7d82-4f4b-a953-a13eaad9838b",
                "fingerprint_slot": 1,
                "occurred_at": timezone.now().isoformat(),
            },
            format="json",
            HTTP_AUTHORIZATION="Device test-device-token",
        )
        self.assertEqual(response.status_code, 401)
        self.assertEqual(Attendance.objects.count(), 0)

    def test_inactive_company_cannot_issue_employee_or_admin_otp_or_profile_access(self):
        organization = self.create_company()
        branch = self.create_branch(organization, "Inactive Branch", "INACTIVE-1")
        employee_user = User.objects.create_user("9000000010", role=User.Role.EMPLOYEE)
        Employee.objects.create(employee_code="INACTIVE-EMP", user=employee_user, branch=branch)
        company_admin = User.objects.create_user(
            "9000000011", role=User.Role.SUPERADMIN, organization=organization,
        )
        organization.is_active = False
        organization.save(update_fields=("is_active",))

        employee_otp = self.client.post("/api/v1/auth/employee/send-otp/", {"phone_number": employee_user.phone_number})
        admin_otp = self.client.post("/api/v1/auth/admin/send-otp/", {"identifier": company_admin.phone_number})
        self.assertEqual(employee_otp.status_code, 200)
        self.assertEqual(admin_otp.status_code, 200)
        self.assertFalse(OTPVerification.objects.filter(phone_number=employee_user.phone_number).exists())
        self.assertFalse(OTPVerification.objects.filter(phone_number=company_admin.phone_number).exists())

        employee_client = APIClient()
        employee_client.force_authenticate(employee_user)
        self.assertEqual(employee_client.get("/api/v1/mobile/me/").status_code, 404)
        self.assertEqual(employee_client.get("/api/v1/auth/me/").status_code, 403)

    def test_inactive_company_cannot_create_new_branch_owned_operations(self):
        from apps.departments.models import Department

        organization = Organization.objects.create(name="Suspended", code="SUSP", is_active=False)
        branch = self.create_branch(organization, "Suspended Branch", "SUSP-1")
        department = Department.objects.create(name="Suspended Department", branch=branch)

        employee = self.client.post("/api/v1/employees/", {
            "employee_code": "SUSP-EMP",
            "first_name": "Test",
            "phone_number": "9000000020",
            "branch": branch.pk,
        }, format="json")
        self.assertEqual(employee.status_code, 400)
        self.assertFalse(Employee.objects.filter(employee_code="SUSP-EMP").exists())

        self.assertEqual(self.client.post("/api/v1/departments/", {
            "name": "New Department", "branch": branch.pk,
        }, format="json").status_code, 404)
        self.assertEqual(self.client.post("/api/v1/designations/", {
            "name": "New Designation", "department": department.pk,
        }, format="json").status_code, 404)
        self.assertEqual(self.client.post("/api/v1/shifts/", {
            "name": "Suspended Shift", "branch": branch.pk,
        }, format="json").status_code, 400)
        self.assertEqual(self.client.post("/api/v1/devices/", {
            "device_id": "SUSP-NEW", "branch_id": branch.pk,
        }, format="json").status_code, 404)

        employee_user = User.objects.create_user("9000000021", role=User.Role.EMPLOYEE)
        employee_record = Employee.objects.create(
            employee_code="SUSP-EXISTING", user=employee_user, branch=branch,
        )
        manual = self.client.post("/api/v1/attendance/admin/manual/", {
            "employee_id": employee_record.pk,
        }, format="json")
        self.assertEqual(manual.status_code, 403)
        self.assertEqual(Attendance.objects.filter(employee=employee_record).count(), 0)

    def test_unauthenticated_company_and_branch_requests_are_rejected(self):
        self.client.force_authenticate(user=None)
        self.assertEqual(self.client.get("/api/v1/organizations/").status_code, 401)
        self.assertEqual(self.client.get("/api/v1/branches/").status_code, 401)


class BranchAttendanceRadiusApiTests(TestCase):
    endpoint = "/api/v1/branches/{}/attendance-radius/"

    def setUp(self):
        self.client = APIClient()
        self.platform = User.objects.create_user(
            "9100000000", role=User.Role.SUPERADMIN, is_staff=True, is_superuser=True,
        )
        self.company_a = Organization.objects.create(name="Radius A", code="RAD-A")
        self.company_b = Organization.objects.create(name="Radius B", code="RAD-B")
        self.branch_a1 = Branch.objects.create(
            organization=self.company_a, name="A1", code="RAD-A1", attendance_radius_meters=40,
        )
        self.branch_a2 = Branch.objects.create(
            organization=self.company_a, name="A2", code="RAD-A2", attendance_radius_meters=40,
        )
        self.branch_b1 = Branch.objects.create(
            organization=self.company_b, name="B1", code="RAD-B1", attendance_radius_meters=40,
        )

    def update_radius(self, branch, value, **extra):
        return self.client.patch(
            self.endpoint.format(branch.pk),
            {"attendance_radius_meters": value, **extra},
            format="json",
        )

    def test_platform_superadmin_can_update_branches_across_companies(self):
        self.client.force_authenticate(self.platform)
        for branch in (self.branch_a1, self.branch_b1):
            with self.subTest(branch=branch.code):
                response = self.update_radius(branch, 55)
                self.assertEqual(response.status_code, 200, response.data)
                self.assertEqual(response.data["data"], {
                    "id": branch.pk, "attendance_radius_meters": 55,
                })
                branch.refresh_from_db()
                self.assertEqual(branch.attendance_radius_meters, 55)

    def test_company_superadmin_can_update_own_company_but_not_another(self):
        company_admin = User.objects.create_user("9100000001", role=User.Role.SUPERADMIN, organization=self.company_a)
        self.client.force_authenticate(company_admin)
        own = self.update_radius(self.branch_a1, 60)
        denied = self.update_radius(self.branch_b1, 61)
        self.assertEqual(own.status_code, 200, own.data)
        self.assertEqual(denied.status_code, 404, denied.data)
        self.branch_b1.refresh_from_db()
        self.assertEqual(self.branch_b1.attendance_radius_meters, 40)

    def test_branch_admin_can_update_only_an_assigned_branch(self):
        branch_admin = User.objects.create_user(
            "9100000002", role=User.Role.ADMIN, organization=self.company_a,
        )
        branch_admin.allowed_branches.add(self.branch_a1)
        self.client.force_authenticate(branch_admin)

        assigned = self.update_radius(self.branch_a1, 70)
        same_company_unassigned = self.update_radius(self.branch_a2, 71)
        other_company = self.update_radius(self.branch_b1, 72)
        self.assertEqual(assigned.status_code, 200, assigned.data)
        self.assertEqual(same_company_unassigned.status_code, 404, same_company_unassigned.data)
        self.assertEqual(other_company.status_code, 404, other_company.data)
        self.branch_a1.refresh_from_db()
        self.assertEqual(self.branch_a1.attendance_radius_meters, 70)
        for branch in (self.branch_a2, self.branch_b1):
            branch.refresh_from_db()
            self.assertEqual(branch.attendance_radius_meters, 40)

    def test_hr_manager_employee_and_other_roles_cannot_update_radius(self):
        for index, role in enumerate((User.Role.HR, User.Role.MANAGER, User.Role.EMPLOYEE), start=3):
            with self.subTest(role=role):
                user = User.objects.create_user(
                    f"910000000{index}", role=role, organization=self.company_a,
                )
                user.allowed_branches.add(self.branch_a1)
                self.client.force_authenticate(user)
                response = self.update_radius(self.branch_a1, 80)
                self.assertEqual(response.status_code, 403, response.data)
        self.branch_a1.refresh_from_db()
        self.assertEqual(self.branch_a1.attendance_radius_meters, 40)

    def test_unauthenticated_request_is_rejected(self):
        response = self.update_radius(self.branch_a1, 50)
        self.assertEqual(response.status_code, 401, response.data)
        self.branch_a1.refresh_from_db()
        self.assertEqual(self.branch_a1.attendance_radius_meters, 40)

    def test_radius_requires_integer_between_ten_and_one_hundred(self):
        self.client.force_authenticate(self.platform)
        for value in (10, 100):
            with self.subTest(accepted=value):
                response = self.update_radius(self.branch_a1, value)
                self.assertEqual(response.status_code, 200, response.data)

        for value in (9, 101, 10.0, "10", None, "not-a-number"):
            with self.subTest(rejected=value):
                response = self.update_radius(self.branch_a1, value)
                self.assertEqual(response.status_code, 400, response.data)

        self.branch_a1.refresh_from_db()
        self.assertEqual(self.branch_a1.attendance_radius_meters, 100)

    def test_extra_fields_are_rejected_without_changing_branch(self):
        self.client.force_authenticate(self.platform)
        original = {
            "name": self.branch_a1.name,
            "organization_id": self.branch_a1.organization_id,
            "is_active": self.branch_a1.is_active,
            "latitude": self.branch_a1.latitude,
            "longitude": self.branch_a1.longitude,
            "attendance_radius_meters": self.branch_a1.attendance_radius_meters,
        }
        for field, value in (
            ("name", "Changed"),
            ("organization_id", self.company_b.pk),
            ("is_active", False),
            ("latitude", 11.0),
            ("longitude", 12.0),
        ):
            with self.subTest(field=field):
                response = self.update_radius(self.branch_a1, 90, **{field: value})
                self.assertEqual(response.status_code, 400, response.data)

        self.branch_a1.refresh_from_db()
        self.assertEqual({
            "name": self.branch_a1.name,
            "organization_id": self.branch_a1.organization_id,
            "is_active": self.branch_a1.is_active,
            "latitude": self.branch_a1.latitude,
            "longitude": self.branch_a1.longitude,
            "attendance_radius_meters": self.branch_a1.attendance_radius_meters,
        }, original)

    def test_legacy_radius_is_unchanged_when_endpoint_has_no_update(self):
        self.client.force_authenticate(self.platform)
        Branch.objects.filter(pk=self.branch_a1.pk).update(attendance_radius_meters=150)
        response = self.client.patch(
            self.endpoint.format(self.branch_a1.pk),
            {},
            format="json",
        )
        self.assertEqual(response.status_code, 400, response.data)
        self.branch_a1.refresh_from_db()
        self.assertEqual(self.branch_a1.attendance_radius_meters, 150)