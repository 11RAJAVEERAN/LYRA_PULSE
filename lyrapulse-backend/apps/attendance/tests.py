from datetime import datetime, timedelta, timezone as datetime_timezone
from threading import Barrier
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch

from django.contrib.auth.hashers import make_password
from django.db import IntegrityError, close_old_connections, transaction
from django.test import TestCase, TransactionTestCase, skipUnlessDBFeature
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.devices.models import Device
from apps.employees.models import Employee
from apps.fingerprints.models import EmployeeFingerprint

from .models import Attendance


class FingerprintAttendanceAPITests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.branch = Branch.objects.create(name="Main", code="MAIN")
        self.other_branch = Branch.objects.create(name="Other", code="OTHER")
        self.employee_user = User.objects.create_user(
            "9100000011",
            first_name="Rajaveeran",
            last_name="V",
        )
        self.employee = Employee.objects.create(
            employee_code="ATT-EMP001",
            user=self.employee_user,
            branch=self.branch,
        )
        self.device_token = "attendance-test-device-token"
        self.device = Device(
            device_id="LYRA-ATTENDANCE-001",
            branch=self.branch,
            token_hash=make_password(self.device_token),
        )
        self.device.save()
        self.mapping = EmployeeFingerprint.objects.create(
            employee=self.employee,
            device=self.device,
            fingerprint_slot=25,
            finger="right_index",
        )
        self.url = "/api/v1/attendance/fingerprint/"
        self.history_url = "/api/v1/attendance/"
        self.payload = {
            "device_id": self.device.device_id,
            "fingerprint_slot": self.mapping.fingerprint_slot,
        }

    def authenticated_client(self, token=None):
        client = APIClient()
        if token is not None:
            client.credentials(HTTP_AUTHORIZATION="Device %s" % token)
        return client

    def scan(self, payload=None, token=None):
        return self.authenticated_client(token or self.device_token).post(
            self.url,
            self.payload if payload is None else payload,
            format="json",
        )

    def advance_last_action(self, attendance, seconds):
        timestamp = timezone.now() - timedelta(seconds=seconds)
        if attendance.check_out_at is None:
            attendance.check_in_at = timestamp
            attendance.save(update_fields=("check_in_at",))
        else:
            attendance.check_out_at = timestamp
            attendance.save(update_fields=("check_out_at",))

    def test_valid_fingerprint_checks_employee_in_and_returns_response_structure(self):
        response = self.scan()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["success"], True)
        self.assertEqual(response.data["message"], "Check-in successful")
        data = response.data["data"]
        self.assertEqual(
            set(data),
            {
                "attendance_id",
                "employee",
                "status",
                "attendance_date",
                "check_in_time",
                "check_out_time",
            },
        )
        self.assertEqual(
            data["employee"],
            {"id": self.employee.id, "name": "Rajaveeran V"},
        )
        self.assertEqual(data["status"], "CHECKED_IN")
        attendance = Attendance.objects.get(pk=data["attendance_id"])
        self.assertIsNone(attendance.check_out_at)

    def test_valid_fingerprint_checks_employee_out_after_duplicate_window(self):
        checked_in = self.scan()
        attendance = Attendance.objects.get(pk=checked_in.data["data"]["attendance_id"])
        self.advance_last_action(attendance, 6)

        checked_out = self.scan()

        self.assertEqual(checked_out.status_code, 200)
        self.assertEqual(checked_out.data["message"], "Check-out successful")
        self.assertEqual(checked_out.data["data"]["status"], "CHECKED_OUT")
        attendance.refresh_from_db()
        self.assertIsNotNone(attendance.check_out_at)

    def test_repeated_scan_within_duplicate_window_does_not_change_attendance(self):
        self.scan()

        duplicate = self.scan()

        self.assertEqual(duplicate.status_code, 200)
        self.assertEqual(duplicate.data["message"], "Duplicate scan ignored")
        self.assertTrue(duplicate.data["data"]["duplicate"])
        self.assertEqual(duplicate.data["data"]["status"], "CHECKED_IN")
        self.assertEqual(Attendance.objects.count(), 1)
        attendance = Attendance.objects.get()
        self.assertIsNone(attendance.check_out_at)

    def test_multiple_sessions_alternate_check_in_and_check_out(self):
        expected = ("CHECKED_IN", "CHECKED_OUT", "CHECKED_IN", "CHECKED_OUT")
        responses = []
        for status in expected:
            latest = Attendance.objects.order_by("-check_in_at", "-pk").first()
            if latest is not None:
                self.advance_last_action(latest, 6)
            responses.append(self.scan())

        self.assertEqual(
            tuple(response.data["data"]["status"] for response in responses),
            expected,
        )
        self.assertEqual(Attendance.objects.count(), 2)
        self.assertTrue(all(record.check_out_at is not None for record in Attendance.objects.all()))

    def test_multiple_sensor_slots_for_same_employee_finger_resolve_attendance(self):
        slot_one_mapping = EmployeeFingerprint.objects.create(
            employee=self.employee,
            device=self.device,
            fingerprint_slot=1,
            finger=self.mapping.finger,
        )
        self.mapping.fingerprint_slot = 256
        self.mapping.save(update_fields=("fingerprint_slot",))

        first_scan = self.scan({
            "device_id": self.device.device_id,
            "fingerprint_slot": slot_one_mapping.fingerprint_slot,
        })
        self.assertEqual(first_scan.status_code, 200)
        self.assertEqual(first_scan.data["data"]["employee"]["id"], self.employee.id)
        self.assertEqual(first_scan.data["data"]["status"], "CHECKED_IN")

        attendance = Attendance.objects.get()
        self.advance_last_action(attendance, 6)
        second_scan = self.scan({
            "device_id": self.device.device_id,
            "fingerprint_slot": 256,
        })
        self.assertEqual(second_scan.status_code, 200)
        self.assertEqual(second_scan.data["data"]["employee"]["id"], self.employee.id)
        self.assertEqual(second_scan.data["data"]["status"], "CHECKED_OUT")

    def test_employee_can_start_new_session_after_checkout(self):
        self.scan()
        session = Attendance.objects.get()
        self.advance_last_action(session, 6)
        self.assertEqual(self.scan().data["data"]["status"], "CHECKED_OUT")

        session.refresh_from_db()
        self.advance_last_action(session, 6)
        response = self.scan()

        self.assertEqual(response.data["data"]["status"], "CHECKED_IN")
        self.assertEqual(Attendance.objects.count(), 2)
        self.assertIsNone(
            Attendance.objects.get(pk=response.data["data"]["attendance_id"]).check_out_at
        )

    def test_database_rejects_a_second_open_session_for_same_employee_date(self):
        self.scan()
        existing = Attendance.objects.get()

        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                Attendance.objects.create(
                    employee=self.employee,
                    branch=self.branch,
                    device=self.device,
                    attendance_date=existing.attendance_date,
                    check_in_at=timezone.now(),
                    source="BIOMETRIC",
                )

        self.assertEqual(Attendance.objects.filter(check_out_at__isnull=True).count(), 1)

    def test_unknown_fingerprint_slot_does_not_create_attendance(self):
        response = self.scan({"device_id": self.device.device_id, "fingerprint_slot": 999})

        self.assertEqual(response.status_code, 404)
        self.assertFalse(Attendance.objects.exists())

    def test_unmapped_sensor_slots_one_and_256_are_rejected(self):
        for fingerprint_slot in (1, 256):
            with self.subTest(fingerprint_slot=fingerprint_slot):
                response = self.scan({
                    "device_id": self.device.device_id,
                    "fingerprint_slot": fingerprint_slot,
                })
                self.assertEqual(response.status_code, 404)
        self.assertFalse(Attendance.objects.exists())

    def test_inactive_fingerprint_mapping_is_rejected(self):
        self.mapping.is_active = False
        self.mapping.save(update_fields=("is_active",))

        response = self.scan()

        self.assertEqual(response.status_code, 404)
        self.assertFalse(Attendance.objects.exists())

    def test_inactive_employee_is_rejected(self):
        self.employee.is_active = False
        self.employee.save(update_fields=("is_active",))

        response = self.scan()

        self.assertEqual(response.status_code, 403)
        self.assertFalse(Attendance.objects.exists())

    def test_inactive_employee_user_is_rejected(self):
        self.employee_user.is_active = False
        self.employee_user.save(update_fields=("is_active",))

        response = self.scan()

        self.assertEqual(response.status_code, 403)
        self.assertFalse(Attendance.objects.exists())

    def test_unknown_device_is_rejected_by_existing_device_authentication(self):
        response = self.scan({
            "device_id": "UNKNOWN-DEVICE",
            "fingerprint_slot": self.mapping.fingerprint_slot,
        })

        self.assertEqual(response.status_code, 401)
        self.assertFalse(Attendance.objects.exists())

    def test_inactive_device_is_rejected_by_existing_device_authentication(self):
        self.device.is_active = False
        self.device.save(update_fields=("is_active",))

        response = self.scan()

        self.assertEqual(response.status_code, 401)
        self.assertFalse(Attendance.objects.exists())

    def test_employee_device_branch_mismatch_is_rejected(self):
        self.employee.branch = self.other_branch
        self.employee.save(update_fields=("branch",))

        response = self.scan()

        self.assertEqual(response.status_code, 403)
        self.assertFalse(Attendance.objects.exists())

    def test_inactive_device_branch_is_rejected(self):
        self.branch.is_active = False
        self.branch.save(update_fields=("is_active",))

        response = self.scan()

        self.assertEqual(response.status_code, 403)
        self.assertFalse(Attendance.objects.exists())

    def test_different_employee_fingerprint_resolves_to_its_owner(self):
        second_user = User.objects.create_user(
            "9100000012",
            first_name="Second",
            last_name="Employee",
        )
        second_employee = Employee.objects.create(
            employee_code="ATT-EMP002",
            user=second_user,
            branch=self.branch,
        )
        EmployeeFingerprint.objects.create(
            employee=second_employee,
            device=self.device,
            fingerprint_slot=26,
            finger="left_index",
        )

        response = self.scan({
            "device_id": self.device.device_id,
            "fingerprint_slot": 26,
        })

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"]["employee"]["id"], second_employee.id)
        self.assertEqual(response.data["data"]["employee"]["name"], "Second Employee")
        self.assertNotEqual(response.data["data"]["employee"]["id"], self.employee.id)

    def test_attendance_date_uses_asia_kolkata_timezone(self):
        instant = datetime(2026, 10, 7, 19, 0, tzinfo=datetime_timezone.utc)
        with patch("apps.attendance.services.timezone.now", return_value=instant):
            response = self.scan()

        self.assertEqual(response.status_code, 200)
        attendance = Attendance.objects.get(pk=response.data["data"]["attendance_id"])
        self.assertEqual(attendance.attendance_date.isoformat(), "2026-10-08")
        self.assertEqual(response.data["data"]["attendance_date"].isoformat(), "2026-10-08")
        self.assertEqual(response.data["data"]["check_in_time"], instant)

    def test_device_authentication_rejects_missing_or_invalid_token(self):
        missing_token_response = self.authenticated_client().post(
            self.url,
            self.payload,
            format="json",
        )
        invalid_token_response = self.scan(token="incorrect-token")

        self.assertEqual(missing_token_response.status_code, 401)
        self.assertEqual(invalid_token_response.status_code, 401)
        self.assertFalse(Attendance.objects.exists())

    def test_employee_id_is_not_accepted_from_device_payload(self):
        response = self.scan({
            "device_id": self.device.device_id,
            "fingerprint_slot": self.mapping.fingerprint_slot,
            "employee_id": self.employee.id,
        })

        self.assertEqual(response.status_code, 400)
        self.assertFalse(Attendance.objects.exists())

    def test_scan_immediately_after_check_out_is_ignored_during_cooldown(self):
        self.scan()
        attendance = Attendance.objects.get()
        self.advance_last_action(attendance, 6)
        self.assertEqual(self.scan().data["data"]["status"], "CHECKED_OUT")
        attendance.refresh_from_db()

        response = self.scan()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["data"]["status"], "CHECKED_OUT")
        self.assertTrue(response.data["data"]["duplicate"])
        self.assertEqual(Attendance.objects.count(), 1)
        attendance.refresh_from_db()
        self.assertEqual(attendance.check_out_at, response.data["data"]["check_out_time"])

    def test_history_returns_all_sessions_and_completed_working_time(self):
        first = self.scan()
        first_session = Attendance.objects.get(pk=first.data["data"]["attendance_id"])
        now = timezone.now()
        first_session.check_in_at = now - timedelta(hours=2)
        first_session.check_out_at = now - timedelta(hours=1, minutes=45)
        first_session.save(update_fields=("check_in_at", "check_out_at"))

        second = self.scan()
        second_session = Attendance.objects.get(pk=second.data["data"]["attendance_id"])
        second_session.check_in_at = timezone.now() - timedelta(hours=1)
        second_session.save(update_fields=("check_in_at",))

        admin = User.objects.create_superuser("9100000099", password="test-password")
        self.client.force_authenticate(user=admin)
        response = self.client.get(
            self.history_url,
            {"employee_id": self.employee.id, "date": timezone.localdate().isoformat()},
        )

        self.assertEqual(response.status_code, 200)
        data = response.data["data"]
        self.assertEqual(data["employee"]["id"], self.employee.id)
        self.assertEqual(data["date"], timezone.localdate())
        self.assertEqual(len(data["sessions"]), 2)
        self.assertEqual(data["sessions"][0]["status"], "CHECKED_OUT")
        self.assertEqual(data["sessions"][1]["status"], "CHECKED_IN")
        self.assertEqual(data["total_working_seconds"], 900)
        self.assertEqual(data["total_working_hours"], 0.25)

    def test_history_requires_jwt_and_hr_or_superadmin_permissions(self):
        params = {"employee_id": self.employee.id, "date": "2026-10-08"}

        unauthenticated = self.client.get(self.history_url, params)
        self.assertEqual(unauthenticated.status_code, 401)

        employee_client = APIClient()
        employee_client.force_authenticate(user=self.employee_user)
        forbidden = employee_client.get(self.history_url, params)
        self.assertEqual(forbidden.status_code, 403)

        admin = User.objects.create_superuser("9100000099", password="test-password")
        access_token = str(RefreshToken.for_user(admin).access_token)
        self.client.credentials(HTTP_AUTHORIZATION="Bearer %s" % access_token)
        allowed = self.client.get(self.history_url, params)
        self.assertEqual(allowed.status_code, 200)

    def test_scan_after_midnight_uses_new_kolkata_attendance_date(self):
        before_midnight = datetime(2026, 10, 7, 18, 29, 58, tzinfo=datetime_timezone.utc)
        after_midnight = datetime(2026, 10, 7, 18, 30, 4, tzinfo=datetime_timezone.utc)
        with patch("apps.attendance.services.timezone.now", return_value=before_midnight):
            first = self.scan()
        first_record = Attendance.objects.get(pk=first.data["data"]["attendance_id"])

        with patch("apps.attendance.services.timezone.now", return_value=after_midnight):
            next_day = self.scan()

        self.assertEqual(first_record.attendance_date.isoformat(), "2026-10-07")
        self.assertEqual(next_day.data["data"]["attendance_date"].isoformat(), "2026-10-08")
        self.assertEqual(Attendance.objects.count(), 2)


@skipUnlessDBFeature("has_select_for_update")
class FingerprintAttendanceConcurrencyTests(TransactionTestCase):
    def setUp(self):
        branch = Branch.objects.create(name="Concurrent", code="CONCURRENT")
        employee_user = User.objects.create_user("9100000021", first_name="Concurrent")
        employee = Employee.objects.create(
            employee_code="ATT-CONCURRENT",
            user=employee_user,
            branch=branch,
        )
        self.device_token = "concurrent-test-device-token"
        self.device = Device.objects.create(
            device_id="LYRA-CONCURRENT",
            branch=branch,
            token_hash=make_password(self.device_token),
        )
        EmployeeFingerprint.objects.create(
            employee=employee,
            device=self.device,
            fingerprint_slot=25,
            finger="right_index",
        )

    def test_simultaneous_scans_cannot_create_two_open_sessions(self):
        barrier = Barrier(2)

        def scan():
            close_old_connections()
            try:
                barrier.wait(timeout=10)
                client = APIClient()
                client.credentials(
                    HTTP_AUTHORIZATION="Device %s" % self.device_token
                )
                response = client.post(
                    "/api/v1/attendance/fingerprint/",
                    {
                        "device_id": self.device.device_id,
                        "fingerprint_slot": 25,
                    },
                    format="json",
                )
                return response.status_code, response.data
            finally:
                close_old_connections()

        with ThreadPoolExecutor(max_workers=2) as executor:
            results = list(executor.map(lambda _: scan(), range(2)))

        self.assertEqual([status_code for status_code, _ in results], [200, 200])
        self.assertEqual(Attendance.objects.count(), 1)
        self.assertEqual(
            Attendance.objects.filter(check_out_at__isnull=True).count(),
            1,
        )
