from datetime import timedelta
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.devices.models import Device
from apps.employees.models import Employee
from apps.fingerprints.models import EmployeeFingerprint

from .models import Attendance, AttendanceEvent, DeviceAttendanceEvent
from .tests import image_file


class IntegrationRulesTests(TestCase):
    def setUp(self):
        self.branch = Branch.objects.create(name="Main", code="MAIN", latitude=Decimal("11.744700"), longitude=Decimal("79.768900"), attendance_radius_meters=100)
        self.user = User.objects.create_user("9000000001", role=User.Role.EMPLOYEE)
        self.employee = Employee.objects.create(employee_code="E001", user=self.user, branch=self.branch)
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self.base = "/api/v1/attendance/"
        self.location = {"latitude": 11.745, "longitude": 79.7689, "accuracy": 5}

    def post_mobile(self, action, photo="send"):
        data = dict(self.location)
        if photo == "send":
            data["photo"] = image_file()
        return self.client.post(self.base + action + "/", data, format="multipart")

    def test_new_employee_permissions_default_off(self):
        self.assertFalse(self.employee.biometric_attendance_enabled)
        self.assertFalse(self.employee.mobile_gps_attendance_enabled)
        self.assertFalse(self.employee.photo_attendance_enabled)

    def test_gps_disabled_blocks_mobile_even_if_photo_enabled(self):
        self.employee.photo_attendance_enabled = True
        self.employee.save(update_fields=("photo_attendance_enabled",))
        response = self.post_mobile("check-in")
        self.assertEqual(response.status_code, 403)
        self.assertEqual(Attendance.objects.count(), 0)

    def test_photo_on_requires_photo_for_check_in_and_check_out(self):
        self.employee.mobile_gps_attendance_enabled = True
        self.employee.photo_attendance_enabled = True
        self.employee.save(update_fields=("mobile_gps_attendance_enabled", "photo_attendance_enabled"))
        self.assertEqual(self.post_mobile("check-in", photo=None).status_code, 400)
        self.assertEqual(Attendance.objects.count(), 0)

    def test_photo_off_discards_submitted_photo(self):
        self.employee.mobile_gps_attendance_enabled = True
        self.employee.save(update_fields=("mobile_gps_attendance_enabled",))
        response = self.post_mobile("check-in", photo="send")
        self.assertEqual(response.status_code, 201)
        row = Attendance.objects.get()
        self.assertFalse(row.check_in_photo)
        self.assertTrue(row.actions.filter(action="CHECK_IN", method="MOBILE_GPS").exists())

    def test_multiple_sessions_per_day_and_method_audit(self):
        self.employee.mobile_gps_attendance_enabled = True
        self.employee.save(update_fields=("mobile_gps_attendance_enabled",))
        for _ in range(2):
            self.assertEqual(self.post_mobile("check-in").status_code, 201)
            self.assertEqual(self.post_mobile("check-out").status_code, 200)
        rows = Attendance.objects.filter(employee=self.employee).order_by("check_in_at")
        self.assertEqual(rows.count(), 2)
        self.assertEqual(AttendanceEvent.objects.filter(attendance__in=rows).count(), 4)
        self.assertEqual(self.client.get(self.base + "today/").json()["data"]["sessions"].__len__(), 2)

    def test_device_event_is_idempotent(self):
        self.employee.biometric_attendance_enabled = True
        self.employee.save(update_fields=("biometric_attendance_enabled",))
        device = Device(device_id="D-1", branch=self.branch, token_hash="")
        device.set_token("test-device-secret")
        device.save()
        EmployeeFingerprint.objects.create(employee=self.employee, device=device, fingerprint_slot=12, finger="right_index")
        payload = {"device_id": "D-1", "event_id": "6d70e206-92a2-4ec8-924c-80bbdf2c8b7b", "fingerprint_slot": 12,
                   "occurred_at": (timezone.now() - timedelta(seconds=1)).isoformat()}
        client = APIClient()
        first = client.post(self.base + "fingerprint/events/", payload, format="json", HTTP_AUTHORIZATION="Device test-device-secret")
        second = client.post(self.base + "fingerprint/events/", payload, format="json", HTTP_AUTHORIZATION="Device test-device-secret")
        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)
        self.assertEqual(Attendance.objects.filter(employee=self.employee).count(), 1)
        self.assertEqual(DeviceAttendanceEvent.objects.filter(device=device).count(), 1)
