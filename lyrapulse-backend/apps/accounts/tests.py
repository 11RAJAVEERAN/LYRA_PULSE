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
        admin = User.objects.create_user("9123456789", email="admin@example.test", role=User.Role.ADMIN)
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
        manager = User.objects.create_user("9123456789", role=User.Role.MANAGER)
        self.client.force_authenticate(user=manager)
        response = self.client.get("/api/v1/employees/")
        self.assertEqual(response.status_code, 403)
        manager.user_permissions.add(Permission.objects.get(codename="view_employee", content_type__app_label="employees"))
        manager = User.objects.get(pk=manager.pk)
        self.client.force_authenticate(user=manager)
        response = self.client.get("/api/v1/employees/")
        self.assertEqual(response.status_code, 200)

    def test_superadmin_can_manage_admin_users(self):
        superadmin = User.objects.create_user("9000000000", role=User.Role.SUPERADMIN, is_superuser=True)
        self.client.force_authenticate(user=superadmin)
        response = self.client.post("/api/v1/auth/admin/users/", {
            "phone_number": "9123456789", "email": "manager@example.test", "first_name": "Mina",
            "role": "MANAGER", "permissions": [],
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
        existing = User.objects.create_user("+91 91501 81669", first_name="Existing", role=User.Role.HR)
        call_command("ensure_superadmin", stdout=None)
        call_command("ensure_superadmin", stdout=None)
        existing.refresh_from_db()
        self.assertEqual(User.objects.filter(phone_number=existing.phone_number).count(), 1)
        self.assertEqual(existing.role, User.Role.SUPERADMIN)
        self.assertEqual(existing.first_name, "Existing")
        self.assertTrue(existing.is_superuser)
