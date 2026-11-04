from datetime import timedelta
from unittest.mock import patch
import uuid

from django.contrib import admin
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

from .admin import FingerprintEnrollmentAdmin
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
        if "fingers" in payload and "finger" not in payload:
            data.pop("finger")
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

    def test_two_finger_request_creates_sequential_commands_for_one_employee(self):
        response = self.enroll(
            fingers=["right_thumb", "left_thumb"],
        )

        self.assertEqual(response.status_code, 201)
        data = response.data["data"]
        self.assertEqual(data["total_fingers"], 2)
        self.assertEqual(len(data["enrollments"]), 2)
        self.assertEqual(
            [item["finger_index"] for item in data["enrollments"]],
            [1, 2],
        )
        self.assertEqual(
            [item["status"] for item in data["enrollments"]],
            [
                FingerprintEnrollment.Status.PENDING,
                FingerprintEnrollment.Status.QUEUED,
            ],
        )
        enrollments = list(
            FingerprintEnrollment.objects.filter(pair_id=data["pair_id"]).order_by("finger_index")
        )
        self.assertEqual(len(enrollments), 2)
        self.assertEqual(enrollments[0].employee, self.employee)
        self.assertEqual(enrollments[1].employee, self.employee)
        self.assertEqual([item.finger for item in enrollments], ["right_thumb", "left_thumb"])
        self.assertEqual(
            [item.finger_index for item in enrollments],
            [1, 2],
        )
        self.assertEqual(
            FingerprintEnrollment.objects.filter(
                device=self.device,
                status__in=FingerprintEnrollment.ACTIVE_STATUSES,
            ).count(),
            1,
        )

    def test_two_finger_request_rejects_duplicate_or_existing_mappings(self):
        duplicate = self.enroll(
            fingers=["right_thumb", "right_thumb"],
        )
        self.assertEqual(duplicate.status_code, 400)

        EmployeeFingerprint.objects.create(
            employee=self.employee,
            device=self.device,
            fingerprint_slot=19,
            finger="right_thumb",
        )
        existing = self.enroll(
            fingers=["right_thumb", "left_thumb"],
        )
        self.assertEqual(existing.status_code, 400)
        self.assertEqual(
            FingerprintEnrollment.objects.filter(employee=self.employee).count(),
            0,
        )

    def test_two_finger_pair_activates_second_only_after_first_slot_is_stored(self):
        started = self.enroll(
            fingers=["right_thumb", "left_thumb"],
        )
        pair = FingerprintEnrollment.objects.filter(
            pair_id=started.data["data"]["pair_id"]
        ).order_by("finger_index")
        first, second = list(pair)
        self.advance_to_processing(first)

        reserve = self.device_client().post(
            self.result_url(first),
            {"status": "STORING", "fingerprint_slot": 17},
            format="json",
        )
        self.assertEqual(reserve.status_code, 200)
        first.refresh_from_db()
        self.assertEqual(first.status, FingerprintEnrollment.Status.STORING)
        self.assertEqual(first.actual_slot, 17)
        self.assertEqual(
            self.device_client().get(self.poll_url()).data["data"]["fingerprint_slot"],
            17,
        )

        result = self.device_client().post(
            self.result_url(first),
            {"status": "SUCCESS", "fingerprint_slot": 17},
            format="json",
        )
        self.assertEqual(result.status_code, 200)
        first.refresh_from_db()
        second.refresh_from_db()
        self.assertEqual(first.status, FingerprintEnrollment.Status.SUCCESS)
        self.assertEqual(second.status, FingerprintEnrollment.Status.PENDING)

        command = self.device_client().get(self.poll_url()).data["data"]
        self.assertEqual(command["enrollment_id"], str(second.id))
        self.assertEqual(command["employee_id"], self.employee.id)
        self.assertEqual(command["pair_id"], str(first.pair_id))
        self.assertEqual(command["finger_index"], 2)
        self.assertEqual(command["total_fingers"], 2)
        self.assertEqual(command["finger"], "left_thumb")

        self.advance_to_processing(second)
        reserve_second = self.device_client().post(
            self.result_url(second),
            {"status": "STORING", "fingerprint_slot": 23},
            format="json",
        )
        self.assertEqual(reserve_second.status_code, 200)
        result_second = self.device_client().post(
            self.result_url(second),
            {"status": "SUCCESS", "fingerprint_slot": 23},
            format="json",
        )
        self.assertEqual(result_second.status_code, 200)

        mappings = list(
            EmployeeFingerprint.objects.filter(employee=self.employee, device=self.device)
            .order_by("fingerprint_slot")
        )
        self.assertEqual([mapping.fingerprint_slot for mapping in mappings], [17, 23])
        self.assertEqual([mapping.finger for mapping in mappings], ["right_thumb", "left_thumb"])
        self.assertTrue(all(mapping.employee_id == self.employee.id for mapping in mappings))
        self.assertEqual(self.device_client().get(self.poll_url()).data["data"], {})

    def test_reserved_slot_cannot_change_or_overwrite_a_mapping(self):
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
        started = self.enroll()
        enrollment = FingerprintEnrollment.objects.get(
            pk=started.data["data"]["enrollment_id"]
        )
        self.advance_to_processing(enrollment)

        reserved = self.device_client().post(
            self.result_url(enrollment),
            {"status": "STORING", "fingerprint_slot": 24},
            format="json",
        )
        self.assertEqual(reserved.status_code, 200)
        changed_slot = self.device_client().post(
            self.result_url(enrollment),
            {"status": "STORING", "fingerprint_slot": 25},
            format="json",
        )
        self.assertEqual(changed_slot.status_code, 409)
        occupied_slot = self.device_client().post(
            self.result_url(enrollment),
            {"status": "SUCCESS", "fingerprint_slot": 22},
            format="json",
        )
        self.assertEqual(occupied_slot.status_code, 409)
        self.assertEqual(
            EmployeeFingerprint.objects.get(
                device=self.device,
                fingerprint_slot=22,
            ).employee_id,
            other_employee.id,
        )

    def test_failure_of_first_pair_member_cancels_queued_second(self):
        started = self.enroll(
            fingers=["right_thumb", "left_thumb"],
        )
        pair = list(
            FingerprintEnrollment.objects.filter(
                pair_id=started.data["data"]["pair_id"]
            ).order_by("finger_index")
        )

        result = self.device_client().post(
            self.result_url(pair[0]),
            {"status": "FAILED", "error_code": "POOR_IMAGE"},
            format="json",
        )

        self.assertEqual(result.status_code, 200)
        pair[1].refresh_from_db()
        self.assertEqual(pair[1].status, FingerprintEnrollment.Status.CANCELLED)

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
            {
                "enrollment_id",
                "employee_id",
                "action",
                "finger",
                "pair_id",
                "finger_index",
                "total_fingers",
                "status",
                "fingerprint_slot",
            },
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
        self.client.force_authenticate(self.admin)
        status_response = self.client.get(
            "/api/v1/employees/%s/fingerprints/enrollments/%s/"
            % (self.employee.id, enrollment.id)
        )
        self.assertEqual(status_response.status_code, 200)
        self.assertEqual(status_response.data["data"]["status"], "FAILED")
        self.assertEqual(
            status_response.data["data"]["failure_reason"],
            "DUPLICATE_FINGERPRINT",
        )
        model_admin = FingerprintEnrollmentAdmin(FingerprintEnrollment, admin.site)
        self.assertEqual(
            model_admin.failure_summary(enrollment),
            "Duplicate fingerprint: this template is already stored; choose a different finger.",
        )
        pending = self.device_client().get(self.poll_url())
        self.assertEqual(pending.status_code, 200)
        self.assertEqual(pending.data["data"], {})

        response = self.device_client().post(
            self.result_url(enrollment),
            {"status": "FAILED", "error_code": "UNKNOWN"},
            format="json",
        )
        self.assertEqual(response.status_code, 409)
        next_enrollment = self.enroll(finger="left_index")
        self.assertEqual(next_enrollment.status_code, 201)
        self.assertEqual(
            next_enrollment.data["data"]["status"],
            FingerprintEnrollment.Status.PENDING,
        )

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
