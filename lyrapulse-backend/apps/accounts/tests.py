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

    @override_settings(DEBUG=True)
    def test_send_and_verify_otp_returns_jwt(self):
        response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        otp = response.data["data"]["otp"]
        record = OTPVerification.objects.get(phone_number="9876543210")
        from django.contrib.auth.hashers import check_password
        self.assertTrue(check_password(otp, record.otp_hash))

        response = self.client.post(
            "/api/v1/auth/verify-otp/",
            {"phone_number": "9876543210", "otp": otp},
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.data["data"])

    @override_settings(DEBUG=True)
    def test_send_otp_returns_plaintext_otp_only_in_development(self):
        response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        self.assertRegex(response.data["data"]["otp"], r"^\d{6}$")
        self.assertNotIn("otp", response.data)
        self.assertNotIn("otp_hash", response.data)

    @override_settings(DEBUG=True, OTP_RESEND_COOLDOWN_SECONDS=0)
    def test_resend_otp_uses_existing_flow_and_returns_development_otp(self):
        response = self.client.post(
            "/api/v1/auth/resend-otp/",
            {"phone_number": "9876543210"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertRegex(response.data["data"]["otp"], r"^\d{6}$")
        self.assertEqual(OTPVerification.objects.filter(phone_number="9876543210").count(), 1)

    @override_settings(DEBUG=False)
    def test_send_otp_does_not_return_plaintext_otp_in_production(self):
        response = self.client.post("/api/v1/auth/send-otp/", {"phone_number": "9876543210"})
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("otp", response.data)
        self.assertNotIn("otp", response.data["data"])
        self.assertNotIn("otp_hash", response.data)

    @override_settings(DEBUG=True)
    def test_invalid_otp_is_rejected(self):
        create_otp("9876543210")

        response = self.client.post(
            "/api/v1/auth/verify-otp/",
            {"phone_number": "9876543210", "otp": "999999"},
        )

        self.assertEqual(response.status_code, 400)
        self.assertNotIn("access", response.data["data"])

    @override_settings(DEBUG=True)
    def test_mock_sms_service_does_not_log_plaintext_otp(self):
        from apps.accounts.services.sms_service import MockSMSService

        with self.assertLogs("apps.accounts.services.sms_service", level="INFO") as captured:
            MockSMSService().send_otp("9876543210", "123456")

        self.assertTrue(captured.output)
        self.assertNotIn("123456", "\n".join(captured.output))

    def test_expired_otp_is_rejected(self):
        record = create_otp("9876543210")
        record.expires_at = timezone.now() - timedelta(seconds=1)
        record.save(update_fields=["expires_at"])
        from django.contrib.auth.hashers import make_password
        record.otp_hash = make_password("123456")
        record.save(update_fields=["otp_hash"])
        response = self.client.post("/api/v1/auth/verify-otp/", {"phone_number": "9876543210", "otp": "123456"})
        self.assertEqual(response.status_code, 400)

    @override_settings(DEBUG=True)
    def test_employee_without_active_branch_cannot_request_or_use_login_otp(self):
        self.user.employee.branch = None
        self.user.employee.save(update_fields=["branch"])
        send_response = self.client.post(
            "/api/v1/auth/send-otp/",
            {"phone_number": self.user.phone_number},
        )
        self.assertNotIn("otp", send_response.data["data"])

        otp_record = create_otp(self.user.phone_number)
        verify_response = self.client.post(
            "/api/v1/auth/verify-otp/",
            {"phone_number": self.user.phone_number, "otp": otp_record._plain_otp},
        )
        self.assertEqual(verify_response.status_code, 403)
        self.assertNotIn("access", verify_response.data["data"])

    @override_settings(DEBUG=True)
    def test_employee_with_inactive_branch_cannot_log_in(self):
        self.branch.is_active = False
        self.branch.save(update_fields=["is_active"])
        otp_record = create_otp(self.user.phone_number)

        response = self.client.post(
            "/api/v1/auth/verify-otp/",
            {"phone_number": self.user.phone_number, "otp": otp_record._plain_otp},
        )

        self.assertEqual(response.status_code, 403)
        self.assertNotIn("access", response.data["data"])

    @override_settings(DEBUG=True)
    def test_inactive_employee_cannot_log_in(self):
        self.user.employee.is_active = False
        self.user.employee.save(update_fields=["is_active"])
        otp_record = create_otp(self.user.phone_number)

        response = self.client.post(
            "/api/v1/auth/verify-otp/",
            {"phone_number": self.user.phone_number, "otp": otp_record._plain_otp},
        )

        self.assertEqual(response.status_code, 403)
        self.assertNotIn("access", response.data["data"])

    @override_settings(DEBUG=True)
    def test_hr_and_superadmin_can_still_log_in_with_otp(self):
        for phone_number, role in (
            ("9876543211", User.Role.HR),
            ("9876543212", User.Role.SUPERADMIN),
        ):
            with self.subTest(role=role):
                User.objects.create_user(phone_number, role=role)
                send_response = self.client.post(
                    "/api/v1/auth/send-otp/",
                    {"phone_number": phone_number},
                )
                otp = send_response.data["data"]["otp"]
                verify_response = self.client.post(
                    "/api/v1/auth/verify-otp/",
                    {"phone_number": phone_number, "otp": otp},
                )
                self.assertEqual(verify_response.status_code, 200)
                self.assertEqual(verify_response.data["data"]["user"]["role"], role)
                self.assertIn("access", verify_response.data["data"])
                self.assertIn("refresh", verify_response.data["data"])

    @override_settings(DEBUG=True)
    def test_login_returns_employee_and_branch_profile_fields(self):
        otp_record = create_otp(self.user.phone_number)

        response = self.client.post(
            "/api/v1/auth/verify-otp/",
            {"phone_number": self.user.phone_number, "otp": otp_record._plain_otp},
        )

        self.assertEqual(response.status_code, 200)
        profile = response.data["data"]["user"]
        self.assertEqual(profile["role"], User.Role.EMPLOYEE)
        self.assertEqual(profile["phone_number"], self.user.phone_number)
        self.assertEqual(profile["employee"]["id"], self.user.employee.id)
        self.assertEqual(profile["employee"]["employee_code"], "EMP001")
        self.assertEqual(
            profile["employee"]["branch"],
            {"id": self.branch.id, "name": self.branch.name},
        )

    def test_employee_profile_routes_return_only_authenticated_employee(self):
        other_branch = Branch.objects.create(name="Other", code="OTHER")
        other_user = User.objects.create_user("9876543213")
        Employee.objects.create(
            employee_code="EMP002",
            user=other_user,
            branch=other_branch,
        )
        self.client.force_authenticate(self.user)

        auth_profile = self.client.get("/api/v1/auth/me/")
        mobile_profile = self.client.get("/api/v1/mobile/me/")

        self.assertEqual(auth_profile.status_code, 200)
        self.assertEqual(mobile_profile.status_code, 200)
        self.assertEqual(
            auth_profile.data["data"]["employee"]["branch"],
            {"id": self.branch.id, "name": self.branch.name},
        )
        mobile_data = mobile_profile.data["data"]
        self.assertEqual(mobile_data["id"], self.user.employee.id)
        self.assertEqual(mobile_data["employee_code"], "EMP001")
        self.assertEqual(mobile_data["branch_id"], self.branch.id)
        self.assertEqual(mobile_data["branch_name"], self.branch.name)
        self.assertEqual(mobile_data["role"], User.Role.EMPLOYEE)
        self.assertNotEqual(mobile_data["id"], other_user.employee.id)

        branch_list = self.client.get("/api/v1/branches/")
        self.assertEqual(branch_list.status_code, 403)

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