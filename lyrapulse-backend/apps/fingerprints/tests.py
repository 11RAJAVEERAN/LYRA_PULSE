from datetime import timedelta
from unittest.mock import patch
import uuid

from django.contrib.auth.hashers import make_password
from django.db import IntegrityError
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.devices.models import Device
from apps.departments.models import Department
from apps.employees.models import Employee

from .models import EmployeeFingerprint, FingerprintEnrollment


class FingerprintEnrollmentAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user(
            "9100000001",
            role=User.Role.SUPERADMIN,
            is_active=True,
        )
        self.employee_user = User.objects.create_user(
            "9100000002",
            role=User.Role.EMPLOYEE,
            first_name="Test",
            last_name="Employee",
        )
        self.branch = Branch.objects.create(name="Main", code="MAIN")
        self.other_branch = Branch.objects.create(name="Other", code="OTHER")
        self.department = Department.objects.create(name="Operations", branch=self.branch)
        self.employee = Employee.objects.create(
            employee_code="FP-EMP001",
            user=self.employee_user,
            branch=self.branch,
            department=self.department,
        )
        self.device_token = "test-device-token-not-for-production"
        self.device = Device(
            device_id="LYRA-DEVICE-001",
            branch=self.branch,
            token_hash=make_password(self.device_token),
        )
        self.device.save()
        self.other_device_token = "second-test-device-token"
        self.other_device = Device(
            device_id="LYRA-DEVICE-002",
            branch=self.other_branch,
            token_hash=make_password(self.other_device_token),
        )
        self.other_device.save()

    def enroll(self, **payload):
        data = {"device_id": self.device.device_id, "finger": "right_index"}
        data.update(payload)
        self.client.force_authenticate(self.admin)
        return self.client.post(
            "/api/v1/employees/%s/fingerprints/enroll/" % self.employee.id,
            data,
            format="json",
        )

    def device_client(self, device=None, token=None):
        device = device or self.device
        token = token or self.device_token
        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION="Device %s" % token)
        return client

    def poll_url(self, device=None):
        device = device or self.device
        return "/api/v1/devices/%s/enrollment/pending/" % device.device_id

    def result_url(self, enrollment, device=None):
        device = device or self.device
        return "/api/v1/devices/%s/enrollment/%s/result/" % (device.device_id, enrollment.id)

    def advance_to_processing(self, enrollment):
        client = self.device_client()
        response = client.get(self.poll_url())
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"]["enrollment_id"], str(enrollment.id))
        response = client.post(
            self.result_url(enrollment),
            {"status": FingerprintEnrollment.Status.WAITING_FOR_SECOND_SCAN},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        response = client.post(
            self.result_url(enrollment),
            {"status": FingerprintEnrollment.Status.PROCESSING},
            format="json",
        )
        self.assertEqual(response.status_code, 200)

    def test_admin_starts_enrollment_for_active_employee_and_device(self):
        response = self.enroll()

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["data"]["employee_id"], self.employee.id)
        self.assertEqual(response.data["data"]["device_id"], self.device.device_id)
        self.assertEqual(response.data["data"]["finger"], "right_index")
        self.assertEqual(response.data["data"]["status"], FingerprintEnrollment.Status.PENDING)
        enrollment = FingerprintEnrollment.objects.get(pk=response.data["data"]["enrollment_id"])
        self.assertGreater(enrollment.expires_at, timezone.now())
        self.assertEqual(enrollment.created_by, self.admin)

    def test_employee_must_exist(self):
        self.client.force_authenticate(self.admin)

        response = self.client.post(
            "/api/v1/employees/99999/fingerprints/enroll/",
            {"device_id": self.device.device_id, "finger": "right_index"},
            format="json",
        )

        self.assertEqual(response.status_code, 404)

    def test_inactive_employee_cannot_enroll(self):
        self.employee.is_active = False
        self.employee.save(update_fields=["is_active"])

        response = self.enroll()

        self.assertEqual(response.status_code, 400)

    def test_employee_must_have_active_branch(self):
        self.branch.is_active = False
        self.branch.save(update_fields=["is_active"])

        response = self.enroll()

        self.assertEqual(response.status_code, 400)

    def test_device_must_exist_and_be_active(self):
        self.assertEqual(self.enroll(device_id="UNKNOWN-DEVICE").status_code, 400)
        self.device.is_active = False
        self.device.save(update_fields=["is_active"])

        self.assertEqual(self.enroll().status_code, 400)

    def test_device_and_employee_must_share_branch(self):
        response = self.enroll(device_id=self.other_device.device_id)

        self.assertEqual(response.status_code, 400)

    def test_only_one_active_enrollment_can_be_queued_on_device(self):
        self.assertEqual(self.enroll().status_code, 201)

        response = self.enroll()

        self.assertEqual(response.status_code, 400)

    def test_device_cannot_have_active_enrollments_for_different_employees(self):
        self.assertEqual(self.enroll().status_code, 201)
        second_user = User.objects.create_user("9100000004")
        second_employee = Employee.objects.create(
            employee_code="FP-EMP003",
            user=second_user,
            branch=self.branch,
        )
        self.client.force_authenticate(self.admin)

        response = self.client.post(
            "/api/v1/employees/%s/fingerprints/enroll/" % second_employee.id,
            {"device_id": self.device.device_id, "finger": "left_index"},
            format="json",
        )

        self.assertEqual(response.status_code, 400)

    def test_finger_must_be_valid(self):
        response = self.enroll(finger="right_palm")

        self.assertEqual(response.status_code, 400)

    def test_cannot_enroll_already_mapped_employee_finger(self):
        EmployeeFingerprint.objects.create(
            employee=self.employee,
            device=self.device,
            fingerprint_slot=0,
            finger="right_index",
        )

        response = self.enroll()

        self.assertEqual(response.status_code, 400)

    def test_start_enrollment_requires_hr_or_admin_jwt(self):
        self.client.force_authenticate(self.employee_user)

        response = self.client.post(
            "/api/v1/employees/%s/fingerprints/enroll/" % self.employee.id,
            {"device_id": self.device.device_id, "finger": "right_index"},
            format="json",
        )

        self.assertEqual(response.status_code, 403)
        self.client.force_authenticate(user=None)
        response = self.client.post(
            "/api/v1/employees/%s/fingerprints/enroll/" % self.employee.id,
            {"device_id": self.device.device_id, "finger": "right_index"},
            format="json",
        )
        self.assertEqual(response.status_code, 401)

    def test_device_authentication_rejects_missing_wrong_and_cross_device_token(self):
        client = APIClient()
        self.assertEqual(client.get(self.poll_url()).status_code, 401)
        client.credentials(HTTP_AUTHORIZATION="Device incorrect")
        self.assertEqual(client.get(self.poll_url()).status_code, 401)
        client.credentials(HTTP_AUTHORIZATION="Device %s" % self.device_token)
        self.assertEqual(client.get(self.poll_url(self.other_device)).status_code, 401)

    def test_device_receives_only_its_own_minimal_pending_command(self):
        self.client.force_authenticate(self.admin)
        other_user = User.objects.create_user("9100000003")
        other_employee = Employee.objects.create(
            employee_code="FP-EMP002",
            user=other_user,
            branch=self.other_branch,
        )
        other_enrollment = FingerprintEnrollment.objects.create(
            employee=other_employee,
            device=self.other_device,
            finger="left_thumb",
            created_by=self.admin,
            expires_at=timezone.now() + timedelta(minutes=5),
        )
        response = self.enroll()
        enrollment_id = response.data["data"]["enrollment_id"]

        response = self.device_client().get(self.poll_url())

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            set(response.data["data"]),
            {"enrollment_id", "employee_id", "action", "finger"},
        )
        self.assertEqual(response.data["data"]["enrollment_id"], enrollment_id)
        self.assertEqual(response.data["data"]["employee_id"], self.employee.id)
        self.assertNotEqual(response.data["data"]["enrollment_id"], str(other_enrollment.id))
        self.assertEqual(response.data["data"]["action"], "ENROLL_FINGERPRINT")
        self.assertEqual(
            FingerprintEnrollment.objects.get(pk=enrollment_id).status,
            FingerprintEnrollment.Status.WAITING_FOR_FINGER,
        )

    def test_device_poll_returns_null_when_no_enrollment_is_pending(self):
        response = self.device_client().get(self.poll_url())

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"], {})

    def test_device_success_creates_mapping_and_marks_session_success(self):
        response = self.enroll()
        enrollment = FingerprintEnrollment.objects.get(pk=response.data["data"]["enrollment_id"])
        self.advance_to_processing(enrollment)

        result = self.device_client().post(
            self.result_url(enrollment),
            {"status": "SUCCESS", "fingerprint_slot": 17},
            format="json",
        )

        self.assertEqual(result.status_code, 200)
        enrollment.refresh_from_db()
        mapping = EmployeeFingerprint.objects.get(device=self.device, fingerprint_slot=17)
        self.assertEqual(mapping.employee, self.employee)
        self.assertEqual(mapping.finger, "right_index")
        self.assertEqual(enrollment.status, FingerprintEnrollment.Status.SUCCESS)
        self.assertEqual(enrollment.actual_slot, 17)
        self.assertIsNotNone(enrollment.completed_at)

        retry = self.device_client().post(
            self.result_url(enrollment),
            {"status": "SUCCESS", "fingerprint_slot": 17},
            format="json",
        )
        self.assertEqual(retry.status_code, 200)

    def test_invalid_or_wrong_device_enrollment_result_is_rejected(self):
        enrollment_response = self.enroll()
        enrollment = FingerprintEnrollment.objects.get(pk=enrollment_response.data["data"]["enrollment_id"])
        wrong_device_client = self.device_client(
            self.other_device,
            self.other_device_token,
        )

        response = wrong_device_client.post(
            self.result_url(enrollment, self.other_device),
            {"status": "FAILED", "error_code": "UNKNOWN"},
            format="json",
        )
        self.assertEqual(response.status_code, 409)

        response = self.device_client().post(
            "/api/v1/devices/%s/enrollment/%s/result/" % (self.device.device_id, uuid.uuid4()),
            {"status": "FAILED", "error_code": "UNKNOWN"},
            format="json",
        )
        self.assertIn(response.status_code, (404, 409))

    def test_expired_enrollment_cannot_be_completed(self):
        response = self.enroll()
        enrollment = FingerprintEnrollment.objects.get(pk=response.data["data"]["enrollment_id"])
        enrollment.status = FingerprintEnrollment.Status.PROCESSING
        enrollment.expires_at = timezone.now() - timedelta(seconds=1)
        enrollment.save(update_fields=("status", "expires_at"))

        response = self.device_client().post(
            self.result_url(enrollment),
            {"status": "SUCCESS", "fingerprint_slot": 1},
            format="json",
        )

        self.assertEqual(response.status_code, 409)
        enrollment.refresh_from_db()
        self.assertEqual(enrollment.status, FingerprintEnrollment.Status.EXPIRED)
        self.assertFalse(EmployeeFingerprint.objects.filter(device=self.device).exists())

    def test_duplicate_active_slot_is_rejected_without_mapping(self):
        other_user = User.objects.create_user("9100000004")
        other_employee = Employee.objects.create(
            employee_code="FP-EMP003",
            user=other_user,
            branch=self.branch,
        )
        EmployeeFingerprint.objects.create(
            employee=other_employee,
            device=self.device,
            fingerprint_slot=22,
            finger="left_index",
        )
        response = self.enroll()
        enrollment = FingerprintEnrollment.objects.get(pk=response.data["data"]["enrollment_id"])
        self.advance_to_processing(enrollment)

        response = self.device_client().post(
            self.result_url(enrollment),
            {"status": "SUCCESS", "fingerprint_slot": 22},
            format="json",
        )

        self.assertEqual(response.status_code, 409)
        enrollment.refresh_from_db()
        self.assertEqual(enrollment.status, FingerprintEnrollment.Status.PROCESSING)
        self.assertEqual(EmployeeFingerprint.objects.filter(device=self.device, fingerprint_slot=22).count(), 1)

    def test_success_mapping_and_session_update_are_atomic(self):
        response = self.enroll()
        enrollment = FingerprintEnrollment.objects.get(pk=response.data["data"]["enrollment_id"])
        self.advance_to_processing(enrollment)

        with patch.object(EmployeeFingerprint.objects, "create", side_effect=IntegrityError("forced failure")):
            response = self.device_client().post(
                self.result_url(enrollment),
                {"status": "SUCCESS", "fingerprint_slot": 23},
                format="json",
            )

        self.assertEqual(response.status_code, 409)
        enrollment.refresh_from_db()
        self.assertEqual(enrollment.status, FingerprintEnrollment.Status.PROCESSING)
        self.assertFalse(EmployeeFingerprint.objects.filter(device=self.device, fingerprint_slot=23).exists())

    def test_device_failure_is_recorded_and_cannot_be_completed_twice(self):
        response = self.enroll()
        enrollment = FingerprintEnrollment.objects.get(pk=response.data["data"]["enrollment_id"])

        response = self.device_client().post(
            self.result_url(enrollment),
            {"status": "FAILED", "error_code": "DUPLICATE_FINGERPRINT"},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        enrollment.refresh_from_db()
        self.assertEqual(enrollment.status, FingerprintEnrollment.Status.FAILED)
        self.assertEqual(enrollment.failure_reason, "DUPLICATE_FINGERPRINT")
        response = self.device_client().post(
            self.result_url(enrollment),
            {"status": "FAILED", "error_code": "UNKNOWN"},
            format="json",
        )
        self.assertEqual(response.status_code, 409)

    def test_sensor_template_read_failure_is_recorded(self):
        response = self.enroll()
        enrollment = FingerprintEnrollment.objects.get(pk=response.data["data"]["enrollment_id"])

        result = self.device_client().post(
            self.result_url(enrollment),
            {"status": "FAILED", "error_code": "SENSOR_TEMPLATE_READ_ERROR"},
            format="json",
        )

        self.assertEqual(result.status_code, 200)
        enrollment.refresh_from_db()
        self.assertEqual(enrollment.status, FingerprintEnrollment.Status.FAILED)
        self.assertEqual(enrollment.failure_reason, "SENSOR_TEMPLATE_READ_ERROR")

    def test_admin_can_poll_enrollment_status(self):
        response = self.enroll()
        enrollment_id = response.data["data"]["enrollment_id"]

        response = self.client.get(
            "/api/v1/employees/%s/fingerprints/enrollments/%s/" % (self.employee.id, enrollment_id)
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"]["enrollment_id"], enrollment_id)
        self.assertEqual(response.data["data"]["status"], FingerprintEnrollment.Status.PENDING)
        self.assertIsNone(response.data["data"]["fingerprint_slot"])
