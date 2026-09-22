from datetime import timedelta

from django.test import TestCase, override_settings
from django.utils import timezone
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

    def test_send_and_verify_otp_returns_jwt(self):
        response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        record = OTPVerification.objects.get(phone_number="9876543210")
        from django.contrib.auth.hashers import check_password
        self.assertTrue(check_password("000000", record.otp_hash) or record.otp_hash.startswith("pbkdf2_"))

        with self.settings(OTP_RESEND_COOLDOWN_SECONDS=0):
            create_otp("9876543210")
        latest = OTPVerification.objects.filter(phone_number="9876543210").latest("created_at")
        from django.contrib.auth.hashers import make_password
        latest.otp_hash = make_password("123456")
        latest.save(update_fields=["otp_hash"])
        response = self.client.post("/api/v1/auth/verify-otp/", {"phone_number": "9876543210", "otp": "123456"})
        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.data["data"])

    @override_settings(DEBUG=True)
    def test_send_otp_returns_plaintext_otp_only_in_development(self):
        response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        self.assertRegex(response.data["otp"], r"^\d{6}$")
        self.assertNotIn("otp_hash", response.data)

    @override_settings(DEBUG=False)
    def test_send_otp_does_not_return_plaintext_otp_in_production(self):
        response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("otp", response.data)
        self.assertNotIn("otp_hash", response.data)

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