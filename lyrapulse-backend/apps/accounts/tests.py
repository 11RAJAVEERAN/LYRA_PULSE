from datetime import timedelta
from unittest.mock import patch

from django.test import TestCase, override_settings
from django.utils import timezone
from django.core.management import call_command
from django.contrib.auth.models import Permission
from rest_framework.test import APIClient

from apps.accounts.models import OTPVerification, User
from apps.accounts.services.otp_service import create_otp
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from apps.employees.models import Employee


class SeedDemoDataTests(TestCase):
    def test_seed_uses_new_branch_default_and_preserves_existing_radius(self):
        call_command("seed_demo_data")
        branch = Branch.objects.get(code="MAIN")
        self.assertEqual(branch.attendance_radius_meters, 40)

        branch.attendance_radius_meters = 50
        branch.save(update_fields=("attendance_radius_meters", "updated_at"))
        call_command("seed_demo_data")
        branch.refresh_from_db()
        self.assertEqual(branch.attendance_radius_meters, 50)


@override_settings(ROOT_URLCONF="config.urls")
class OTPAuthenticationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.branch = Branch.objects.create(name="Main", code="MAIN")
        self.department = Department.objects.create(name="Development", branch=self.branch)
        self.designation = Designation.objects.create(name="Developer", department=self.department)
        self.user = User.objects.create_user("9876543210", first_name="Test", last_name="Employee")
        Employee.objects.create(employee_code="EMP001", user=self.user, branch=self.branch, department=self.department, designation=self.designation)

    @override_settings(DEBUG=True, SMS_PROVIDER="mock")
    def test_send_and_verify_otp_returns_jwt(self):
        response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        record = OTPVerification.objects.get(phone_number="9876543210")
        from django.contrib.auth.hashers import check_password
        otp = response.data["data"]["dev_otp"]
        self.assertRegex(otp, r"^\d{6}$")
        self.assertTrue(check_password(otp, record.otp_hash))
        response = self.client.post("/api/v1/auth/verify-otp/", {"phone_number": "9876543210", "otp": otp})
        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.data["data"])

    @override_settings(DEBUG=True, SMS_PROVIDER="mock")
    def test_send_otp_returns_dev_otp_only_for_debug_mock(self):
        response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        self.assertRegex(response.data["data"]["dev_otp"], r"^\d{6}$")
        self.assertNotIn("otp", response.data)
        self.assertNotIn("otp_hash", response.data)

    @override_settings(DEBUG=False, SMS_PROVIDER="mock")
    def test_send_otp_hides_dev_otp_when_debug_is_false(self):
        response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("dev_otp", response.data["data"])
        self.assertNotIn("otp", response.data)
        self.assertNotIn("otp_hash", response.data)

    @override_settings(DEBUG=True, SMS_PROVIDER="twilio")
    def test_send_otp_hides_dev_otp_for_non_mock_provider(self):
        with patch("apps.accounts.services.otp_service.get_sms_service"):
            response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("dev_otp", response.data["data"])

    @override_settings(DEBUG=False, SMS_PROVIDER="mock")
    def test_employee_send_otp_response_does_not_disclose_account_eligibility(self):
        eligible = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        unknown = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876500000"})

        self.assertEqual(eligible.status_code, unknown.status_code)
        self.assertEqual(eligible.data["message"], unknown.data["message"])
        eligible_data = dict(eligible.data["data"])
        unknown_data = dict(unknown.data["data"])
        eligible_data.pop("phone_number")
        unknown_data.pop("phone_number")
        self.assertEqual(eligible_data, unknown_data)

    @override_settings(DEBUG=False, SMS_PROVIDER="mock", OTP_RESEND_COOLDOWN_SECONDS=300)
    def test_employee_send_otp_cooldown_does_not_disclose_account_eligibility(self):
        first = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        second = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        unknown = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876500000"})

        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, unknown.status_code)
        self.assertEqual(second.data["message"], unknown.data["message"])
        second_data = dict(second.data["data"])
        unknown_data = dict(unknown.data["data"])
        second_data.pop("phone_number")
        unknown_data.pop("phone_number")
        self.assertEqual(second_data, unknown_data)

    def test_expired_otp_is_rejected(self):
        record = create_otp("9876543210")
        record.expires_at = timezone.now() - timedelta(seconds=1)
        record.save(update_fields=["expires_at"])
        from django.contrib.auth.hashers import make_password
        record.otp_hash = make_password("123456")
        record.save(update_fields=["otp_hash"])
        response = self.client.post("/api/v1/auth/verify-otp/", {"phone_number": "9876543210", "otp": "123456"})
        self.assertEqual(response.status_code, 400)

    def test_me_requires_authentication(self):
        response = self.client.get("/api/v1/auth/me/")
        self.assertEqual(response.status_code, 401)

    def test_refresh_and_logout_blacklist_refresh_token(self):
        from rest_framework_simplejwt.tokens import RefreshToken
        refresh = RefreshToken.for_user(self.user)
        refresh_value = str(refresh)
        response = self.client.post("/api/v1/auth/token/refresh/", {"refresh": refresh_value})
        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.data["success"])

        self.client.force_authenticate(user=self.user)
        response = self.client.post("/api/v1/auth/logout/", {"refresh": refresh_value})
        self.assertEqual(response.status_code, 200)
        response = self.client.post("/api/v1/auth/token/refresh/", {"refresh": refresh_value})
        self.assertEqual(response.status_code, 401)

    def test_admin_login_accepts_email_or_mobile_and_returns_jwt(self):
        from apps.organizations.models import Organization
        organization = Organization.objects.create(name="OTP Admin Company", code="OTP-ADMIN")
        branch = Branch.objects.create(organization=organization, name="OTP Admin Branch", code="OTP-ADMIN-BRANCH")
        admin = User.objects.create_user(
            "9123456789",
            email="admin@example.test",
            role=User.Role.ADMIN,
            organization=organization,
        )
        admin.allowed_branches.add(branch)
        from apps.accounts.services.role_permissions import ensure_role_group
        admin.groups.add(ensure_role_group(User.Role.ADMIN))
        with self.settings(DEBUG=True, SMS_PROVIDER="mock", OTP_RESEND_COOLDOWN_SECONDS=0):
            for identifier in (admin.email, admin.phone_number):
                response = self.client.post("/api/v1/auth/admin/send-otp/", {"identifier": identifier})
                self.assertEqual(response.status_code, 200)
                otp = response.data["data"]["dev_otp"]
                response = self.client.post("/api/v1/auth/admin/verify-otp/", {"identifier": identifier, "otp": otp})
                self.assertEqual(response.status_code, 200)
                self.assertIn("access", response.data["data"])

    @override_settings(DEBUG=False, SMS_PROVIDER="mock")
    def test_admin_send_otp_hides_dev_otp_when_debug_is_false(self):
        admin = User.objects.create_user("9123456789", email="admin@example.test", role=User.Role.ADMIN)
        response = self.client.post("/api/v1/auth/admin/send-otp/", {"identifier": admin.email})
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("dev_otp", response.data["data"])

    def test_employee_cannot_get_admin_token(self):
        response = self.client.post("/api/v1/auth/admin/send-otp/", {"identifier": self.user.phone_number})
        self.assertEqual(response.status_code, 200)
        self.assertFalse(OTPVerification.objects.filter(phone_number=self.user.phone_number, purpose=OTPVerification.Purpose.ADMIN_LOGIN).exists())

    def test_employee_management_requires_django_permission(self):
        from apps.organizations.models import Organization
        organization = Organization.objects.create(name="Manager Test Company", code="MANAGER-TEST")
        branch = Branch.objects.create(organization=organization, name="Manager Test Branch", code="MANAGER-TEST-BRANCH")
        manager = User.objects.create_user("9123456789", role=User.Role.MANAGER, organization=organization)
        manager.allowed_branches.add(branch)
        self.client.force_authenticate(user=manager)
        response = self.client.get("/api/v1/employees/")
        self.assertEqual(response.status_code, 403)
        manager.user_permissions.add(Permission.objects.get(codename="view_employee", content_type__app_label="employees"))
        manager = User.objects.get(pk=manager.pk)
        self.client.force_authenticate(user=manager)
        response = self.client.get("/api/v1/employees/")
        self.assertEqual(response.status_code, 200)

    def test_superadmin_can_manage_admin_users(self):
        from apps.organizations.models import Organization
        organization = Organization.objects.create(name="Admin User Test Company", code="ADMIN-USER-TEST")
        branch = Branch.objects.create(organization=organization, name="Admin User Test Branch", code="ADMIN-USER-TEST-BRANCH")
        superadmin = User.objects.create_user("9000000000", role=User.Role.SUPERADMIN, is_superuser=True)
        self.client.force_authenticate(user=superadmin)
        response = self.client.post("/api/v1/auth/admin/users/", {
            "phone_number": "9123456789", "email": "manager@example.test", "first_name": "Mina",
            "role": "MANAGER", "permissions": [], "organization": organization.pk, "branch_ids": [branch.pk],
        })
        self.assertEqual(response.status_code, 201)
        manager = User.objects.get(phone_number="9123456789")
        self.assertEqual(manager.role, User.Role.MANAGER)
        self.assertTrue(manager.is_active)
        self.assertTrue(manager.groups.filter(name="MANAGER").exists())
        self.assertTrue(manager.groups.get(name="MANAGER").permissions.filter(codename="view_employee").exists())
        self.assertIn("employees.view_employee", manager.get_group_permissions())
        self.assertTrue(manager.has_perm("employees.view_employee"))

    def test_ensure_superadmin_is_idempotent_and_preserves_existing_user(self):
        existing = User.objects.create_user("+91 90000 00001", first_name="Existing", role=User.Role.HR)
        call_command("ensure_superadmin", "--phone", "9000000001", stdout=None)
        call_command("ensure_superadmin", "--phone", "9000000001", stdout=None)
        existing.refresh_from_db()
        self.assertEqual(User.objects.filter(phone_number=existing.phone_number).count(), 1)
        self.assertEqual(existing.role, User.Role.SUPERADMIN)
        self.assertEqual(existing.first_name, "Existing")
        self.assertTrue(existing.is_superuser)

    def test_ensure_superadmin_requires_a_phone(self):
        from django.core.management.base import CommandError
        with patch.dict("os.environ"):
            import os
            os.environ.pop("LYRA_SUPERADMIN_PHONE", None)
            with self.assertRaises(CommandError):
                call_command("ensure_superadmin", stdout=None)


@override_settings(ROOT_URLCONF="config.urls")
class OrganizationScopeTests(TestCase):
    def setUp(self):
        from apps.accounts.services.role_permissions import ensure_role_group
        from apps.organizations.models import Organization
        self.client = APIClient()
        self.devi = Organization.objects.create(name="Devi Hotel", code="DEVI")
        self.lyra = Organization.objects.create(name="LyraTech", code="LYRA")
        self.chennai = Branch.objects.create(organization=self.devi, name="Chennai", code="DEVI-CHN")
        self.madurai = Branch.objects.create(organization=self.devi, name="Madurai", code="DEVI-MDU")
        self.bangalore = Branch.objects.create(organization=self.lyra, name="Bangalore", code="LYRA-BLR")
        self.superadmin = User.objects.create_user("9000000000", role=User.Role.SUPERADMIN, is_superuser=True)
        self.devi_owner = User.objects.create_user("9000000001", role=User.Role.SUPERADMIN, organization=self.devi)
        self.lyra_owner = User.objects.create_user("9000000002", role=User.Role.SUPERADMIN, organization=self.lyra)
        self.murugan = User.objects.create_user("9999999999", first_name="Murugan", role=User.Role.ADMIN, organization=self.devi)
        self.murugan.allowed_branches.add(self.chennai)
        self.murugan.groups.add(ensure_role_group(User.Role.ADMIN))
        self.emp_chennai = self._employee("E1", "9100000001", self.chennai)
        self.emp_madurai = self._employee("E2", "9100000002", self.madurai)
        self.emp_other_org = self._employee("E3", "9100000003", self.bangalore)

    def _employee(self, code, phone, branch):
        user = User.objects.create_user(phone, first_name=code)
        return Employee.objects.create(employee_code=code, user=user, branch=branch)

    def _codes(self, response):
        return {item["employee_code"] for item in response.data["data"]}

    def test_scoped_admin_sees_only_allowed_branch_employees(self):
        self.client.force_authenticate(user=self.murugan)
        self.assertEqual(self._codes(self.client.get("/api/v1/employees/")), {"E1"})
        self.assertEqual(self.client.get(f"/api/v1/employees/{self.emp_madurai.pk}/").status_code, 404)
        self.assertEqual(self.client.get(f"/api/v1/employees/{self.emp_other_org.pk}/").status_code, 404)

    def test_superadmin_sees_all_employees(self):
        self.client.force_authenticate(user=self.superadmin)
        self.assertEqual(self._codes(self.client.get("/api/v1/employees/")), {"E1", "E2", "E3"})

    def test_customer_superadmins_are_scoped_to_their_active_organization(self):
        from apps.devices.models import Device

        from apps.departments.models import Department
        from apps.designations.models import Designation

        dev_department = Department.objects.create(name="Devi Ops", branch=self.chennai)
        lyra_department = Department.objects.create(name="Lyra Ops", branch=self.bangalore)
        Designation.objects.create(name="Devi Lead", department=dev_department)
        Designation.objects.create(name="Lyra Lead", department=lyra_department)
        dev_device = Device(device_id="DEVI-DEVICE", branch=self.chennai)
        dev_device.set_token("devi-device-test-token")
        dev_device.save()
        lyra_device = Device(device_id="LYRA-DEVICE", branch=self.bangalore)
        lyra_device.set_token("lyra-device-test-token")
        lyra_device.save()

        self.client.force_authenticate(user=self.devi_owner)
        self.assertEqual(self._codes(self.client.get("/api/v1/employees/")), {"E1", "E2"})
        self.assertEqual(self.client.get(f"/api/v1/employees/{self.emp_other_org.pk}/").status_code, 404)
        self.assertEqual(
            {item["name"] for item in self.client.get("/api/v1/branches/").data["data"]},
            {"Chennai", "Madurai"},
        )
        self.assertEqual(
            {item["name"] for item in self.client.get("/api/v1/departments/").data["data"]},
            {"Devi Ops"},
        )
        self.assertEqual(
            {item["name"] for item in self.client.get("/api/v1/designations/").data["data"]},
            {"Devi Lead"},
        )
        devices = self.client.get("/api/v1/devices/")
        self.assertEqual({item["device_id"] for item in devices.data["data"]}, {dev_device.device_id})
        cross_org_update = self.client.patch("/api/v1/devices/", {"device_id": lyra_device.device_id, "name": "changed"}, format="json")
        self.assertEqual(cross_org_update.status_code, 404)
        cross_org_provision = self.client.post("/api/v1/devices/", {
            "device_id": "DEVI-CROSS", "branch_id": self.bangalore.pk,
        }, format="json")
        self.assertEqual(cross_org_provision.status_code, 404)
        self.client.force_authenticate(user=self.lyra_owner)
        self.assertEqual(self._codes(self.client.get("/api/v1/employees/")), {"E3"})

    def test_branch_filter_stays_within_authenticated_scope_for_employees_and_devices(self):
        from apps.devices.models import Device

        dev_device = Device(device_id="DEVI-FILTER", branch=self.chennai)
        dev_device.set_token("devi-filter-test-token")
        dev_device.save()
        other_device = Device(device_id="LYRA-FILTER", branch=self.bangalore)
        other_device.set_token("lyra-filter-test-token")
        other_device.save()

        self.client.force_authenticate(user=self.devi_owner)
        self.assertEqual(self._codes(self.client.get("/api/v1/employees/", {"branch": self.chennai.pk})), {"E1"})
        self.assertEqual(self._codes(self.client.get("/api/v1/employees/", {"branch": self.bangalore.pk})), set())
        devices = self.client.get("/api/v1/devices/", {"branch": self.chennai.pk})
        self.assertEqual({item["device_id"] for item in devices.data["data"]}, {dev_device.device_id})
        devices = self.client.get("/api/v1/devices/", {"branch": self.bangalore.pk})
        self.assertEqual(devices.data["data"], [])
        self.assertEqual(self.client.get("/api/v1/employees/", {"branch": "invalid"}).data["data"], [])

    def test_customer_superadmin_without_active_organization_is_fail_closed(self):
        unassigned = User.objects.create_user("9000000003", role=User.Role.SUPERADMIN)
        self.client.force_authenticate(user=unassigned)
        self.assertEqual(self.client.get("/api/v1/employees/").status_code, 403)
        self.assertEqual(self.client.get(f"/api/v1/employees/{self.emp_other_org.pk}/").status_code, 403)
        self.lyra.is_active = False
        self.lyra.save(update_fields=["is_active"])
        self.client.force_authenticate(user=self.lyra_owner)
        self.assertEqual(self.client.get("/api/v1/employees/").status_code, 403)

    def test_customer_superadmin_admin_user_api_is_tenant_scoped(self):
        dev_user = User.objects.create_user("9000000011", role=User.Role.HR, organization=self.devi)
        lyra_user = User.objects.create_user("9000000012", role=User.Role.HR, organization=self.lyra)
        self.client.force_authenticate(user=self.devi_owner)
        listing = self.client.get("/api/v1/auth/admin/users/")
        self.assertEqual({item["id"] for item in listing.data["data"]}, {self.murugan.pk, dev_user.pk})
        self.assertEqual(self.client.get(f"/api/v1/auth/admin/users/{lyra_user.pk}/").status_code, 404)
        response = self.client.post("/api/v1/auth/admin/users/", {
            "phone_number": "9000000015", "role": "HR", "branch_ids": [self.chennai.pk],
        }, format="json")
        self.assertEqual(response.status_code, 201)
        managed_user = User.objects.get(phone_number="9000000015")
        self.assertEqual(managed_user.organization, self.devi)
        self.assertFalse(managed_user.is_staff)
        response = self.client.post("/api/v1/auth/admin/users/", {
            "phone_number": "9000000013", "role": "HR", "organization": self.lyra.pk,
        }, format="json")
        self.assertEqual(response.status_code, 400)
        response = self.client.post("/api/v1/auth/admin/users/", {
            "phone_number": "9000000014", "role": "HR", "branch_ids": [self.bangalore.pk],
        }, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(User.objects.filter(phone_number__in=["9000000013", "9000000014"]).exists())

    def test_customer_owner_cannot_create_organizations_or_branches_via_website_api(self):
        self.client.force_authenticate(user=self.devi_owner)
        branch_response = self.client.post("/api/v1/branches/", {"name": "New", "code": "NEW"}, format="json")
        self.assertEqual(branch_response.status_code, 201)
        self.assertEqual(branch_response.data["data"]["organization"]["id"], self.devi.pk)
        company_response = self.client.post("/api/v1/organizations/", {"name": "New", "code": "NEW"}, format="json")
        self.assertEqual(company_response.status_code, 403)

    def test_customer_superadmin_does_not_gain_django_admin_access_from_role(self):
        self.client.force_login(self.devi_owner)
        response = self.client.get("/admin/")
        self.assertEqual(response.status_code, 302)

    def test_admin_without_scope_sees_nothing(self):
        from apps.accounts.services.role_permissions import ensure_role_group
        legacy = User.objects.create_user("9111111111", role=User.Role.ADMIN)
        legacy.groups.add(ensure_role_group(User.Role.ADMIN))
        self.client.force_authenticate(user=legacy)
        self.assertEqual(self.client.get("/api/v1/employees/").status_code, 403)

    def test_scoped_admin_cannot_create_employee_outside_scope(self):
        self.client.force_authenticate(user=self.murugan)
        payload = {"employee_code": "E9", "first_name": "A", "last_name": "B", "phone_number": "9222222222", "email": "a@example.test"}
        for branch in (self.madurai, self.bangalore):
            response = self.client.post("/api/v1/employees/", {**payload, "branch": branch.pk})
            self.assertEqual(response.status_code, 400)
        response = self.client.post("/api/v1/employees/", payload)  # no branch
        self.assertEqual(response.status_code, 400)
        response = self.client.post("/api/v1/employees/", {**payload, "branch": self.chennai.pk})
        self.assertEqual(response.status_code, 201)

    def test_branch_dropdown_is_scoped(self):
        self.client.force_authenticate(user=self.murugan)
        names = {item["name"] for item in self.client.get("/api/v1/branches/").data["data"]}
        self.assertEqual(names, {"Chennai"})
        self.client.force_authenticate(user=self.superadmin)
        names = {item["name"] for item in self.client.get("/api/v1/branches/").data["data"]}
        self.assertEqual(names, {"Chennai", "Madurai", "Bangalore"})

    def test_create_admin_user_with_organization_and_branches(self):
        self.client.force_authenticate(user=self.superadmin)
        response = self.client.post("/api/v1/auth/admin/users/", {
            "phone_number": "9333333333", "first_name": "Ravi", "role": "HR",
            "organization": self.devi.pk, "branch_ids": [self.chennai.pk, self.madurai.pk],
        }, format="json")
        self.assertEqual(response.status_code, 201)
        user = User.objects.get(phone_number="9333333333")
        self.assertEqual(user.organization, self.devi)
        self.assertEqual(set(user.allowed_branches.all()), {self.chennai, self.madurai})
        self.assertTrue(user.groups.filter(name="HR").exists())

    def test_create_admin_user_rejects_cross_organization_branch(self):
        self.client.force_authenticate(user=self.superadmin)
        response = self.client.post("/api/v1/auth/admin/users/", {
            "phone_number": "9333333333", "first_name": "Ravi", "role": "ADMIN",
            "organization": self.devi.pk, "branch_ids": [self.bangalore.pk],
        }, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(User.objects.filter(phone_number="9333333333").exists())

    def test_role_change_via_api_swaps_group(self):
        self.client.force_authenticate(user=self.superadmin)
        response = self.client.patch(f"/api/v1/auth/admin/users/{self.murugan.pk}/", {"role": "HR"}, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertFalse(self.murugan.groups.filter(name="ADMIN").exists())
        self.assertTrue(self.murugan.groups.filter(name="HR").exists())

    def test_model_level_guard_rejects_cross_organization_branch(self):
        from django.core.exceptions import ValidationError
        from django.db import transaction
        with self.assertRaises(ValidationError), transaction.atomic():
            self.murugan.allowed_branches.add(self.bangalore)
        with self.assertRaises(ValidationError), transaction.atomic():
            self.bangalore.admin_users.add(self.murugan)
        self.assertEqual(set(self.murugan.allowed_branches.all()), {self.chennai})

    def test_branch_cannot_change_organization_while_admins_are_scoped_to_it(self):
        from django.core.exceptions import ValidationError
        self.chennai.organization = self.lyra
        with self.assertRaises(ValidationError):
            self.chennai.save()

    def test_login_payload_includes_scope(self):
        with self.settings(DEBUG=True, SMS_PROVIDER="mock"):
            send = self.client.post("/api/v1/auth/admin/send-otp/", {"identifier": "9999999999"})
            verify = self.client.post("/api/v1/auth/admin/verify-otp/", {"identifier": "9999999999", "otp": send.data["data"]["dev_otp"]})
        user = verify.data["data"]["user"]
        self.assertEqual(user["role"], "ADMIN")
        self.assertEqual(user["organization"], {"id": self.devi.pk, "name": "Devi Hotel"})
        self.assertEqual(user["branches"], [{"id": self.chennai.pk, "name": "Chennai"}])
        self.assertFalse(user["is_global"])
