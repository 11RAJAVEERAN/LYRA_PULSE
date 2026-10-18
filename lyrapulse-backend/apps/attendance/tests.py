import math
import os
import re
import shutil
import tempfile
from datetime import datetime, timezone as dt_timezone
from decimal import Decimal
from io import BytesIO
from unittest.mock import patch

from django.contrib.auth.models import Permission
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from django.db import IntegrityError, transaction
from django.test import SimpleTestCase, TestCase, override_settings
from PIL import Image
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.employees.models import Employee
from apps.organizations.models import Organization

from . import services
from .exceptions import AttendanceError
from .models import Attendance

BRANCH_LAT, BRANCH_LON = Decimal("11.744700"), Decimal("79.768900")
NEAR = {"latitude": 11.7450, "longitude": 79.7689, "accuracy": 7.4}  # ~33 m from the branch
FAR = {"latitude": 11.7480, "longitude": 79.7689, "accuracy": 7.4}   # ~367 m from the branch
BASE = "/api/v1/attendance/"


def image_file(name="selfie.jpg", fmt="JPEG", content_type=None):
    buffer = BytesIO()
    Image.new("RGB", (16, 16), "blue").save(buffer, format=fmt)
    return SimpleUploadedFile(name, buffer.getvalue(), content_type=content_type or f"image/{fmt.lower()}")


def unconfigured_branch(**extra):
    return Branch(name="Test", code="T1", **extra)


class BranchLocationTests(TestCase):
    def make(self, **extra):
        values = {"name": "Cuddalore", "code": "CDL", "latitude": BRANCH_LAT, "longitude": BRANCH_LON, "attendance_radius_meters": 100}
        values.update(extra)
        return Branch(**values)

    def test_01_valid_branch_coordinates(self):
        branch = self.make()
        branch.full_clean()
        self.assertTrue(branch.has_attendance_location)

    def test_02_invalid_latitude(self):
        for bad in (Decimal("90.5"), Decimal("-91")):
            with self.assertRaises(ValidationError) as ctx:
                self.make(latitude=bad).full_clean()
            self.assertIn("latitude", ctx.exception.message_dict)

    def test_03_invalid_longitude(self):
        for bad in (Decimal("180.5"), Decimal("-181")):
            with self.assertRaises(ValidationError) as ctx:
                self.make(longitude=bad).full_clean()
            self.assertIn("longitude", ctx.exception.message_dict)

    def test_04_invalid_radius(self):
        with self.assertRaises(ValidationError) as ctx:
            self.make(attendance_radius_meters=0).full_clean()
        self.assertIn("attendance_radius_meters", ctx.exception.message_dict)

    def test_05_missing_location_configuration(self):
        branch = self.make(latitude=None, longitude=None)
        branch.full_clean()  # allowed: existing branches stay valid
        self.assertFalse(branch.has_attendance_location)
        with self.assertRaises(AttendanceError) as ctx:
            services.verify_attendance_location(branch, 11.7, 79.7, 5)
        self.assertEqual(ctx.exception.code, "BRANCH_LOCATION_NOT_CONFIGURED")
        self.assertEqual(ctx.exception.message, "Attendance location is not configured for this branch.")

    def test_only_one_coordinate_is_rejected(self):
        with self.assertRaises(ValidationError):
            self.make(longitude=None).full_clean()


class LocationServiceTests(SimpleTestCase):
    def branch(self, radius=100):
        return Branch(name="Cuddalore", code="CDL", latitude=BRANCH_LAT, longitude=BRANCH_LON, attendance_radius_meters=radius)

    def test_06_inside_radius(self):
        result = services.verify_attendance_location(self.branch(), NEAR["latitude"], NEAR["longitude"], 7.4)
        self.assertTrue(result.verified)
        self.assertAlmostEqual(result.distance_meters, 33.4, delta=1.0)
        self.assertEqual(result.allowed_radius_meters, 100)
        self.assertEqual(result.accuracy_meters, 7.4)

    def test_07_outside_radius(self):
        result = services.verify_attendance_location(self.branch(), FAR["latitude"], FAR["longitude"], 7.4)
        self.assertFalse(result.verified)
        self.assertAlmostEqual(result.distance_meters, 367, delta=3.0)

    def test_08_boundary(self):
        distance = services.calculate_distance_meters(NEAR["latitude"], NEAR["longitude"], float(BRANCH_LAT), float(BRANCH_LON))
        just_inside = self.branch(radius=math.ceil(distance))
        just_outside = self.branch(radius=math.floor(distance))
        self.assertTrue(services.verify_attendance_location(just_inside, NEAR["latitude"], NEAR["longitude"], 5).verified)
        self.assertFalse(services.verify_attendance_location(just_outside, NEAR["latitude"], NEAR["longitude"], 5).verified)
        # standing exactly on the branch point is distance 0
        on_point = services.verify_attendance_location(self.branch(radius=1), float(BRANCH_LAT), float(BRANCH_LON), 5)
        self.assertTrue(on_point.verified)
        self.assertEqual(on_point.distance_meters, 0)

    def test_haversine_known_distance(self):
        # One degree of latitude is ~111.19 km
        self.assertAlmostEqual(services.calculate_distance_meters(0, 0, 1, 0), 111195, delta=100)

    def test_09_invalid_coordinates(self):
        cases = [
            ((91, 79.7, 5), "INVALID_LATITUDE"), ((-91, 79.7, 5), "INVALID_LATITUDE"), (("abc", 79.7, 5), "INVALID_LATITUDE"),
            ((float("nan"), 79.7, 5), "INVALID_LATITUDE"),
            ((11.7, 181, 5), "INVALID_LONGITUDE"), ((11.7, float("inf"), 5), "INVALID_LONGITUDE"),
            ((11.7, 79.7, -1), "INVALID_GPS_ACCURACY"), ((11.7, 79.7, "x"), "INVALID_GPS_ACCURACY"),
        ]
        for args, code in cases:
            with self.assertRaises(AttendanceError, msg=str(args)) as ctx:
                services.verify_attendance_location(self.branch(), *args)
            self.assertEqual(ctx.exception.code, code, msg=str(args))


class AttendanceAPITestCase(TestCase):
    def setUp(self):
        media = tempfile.mkdtemp(prefix="lyra_test_media_")
        self.media_root = media
        override = override_settings(MEDIA_ROOT=media, ROOT_URLCONF="config.urls")
        override.enable()
        self.addCleanup(override.disable)
        self.addCleanup(shutil.rmtree, media, ignore_errors=True)

        self.org = Organization.objects.create(name="Devi", code="DEVI")
        self.branch = Branch.objects.create(
            organization=self.org, name="Cuddalore", code="CDL",
            latitude=BRANCH_LAT, longitude=BRANCH_LON, attendance_radius_meters=100,
        )
        self.user, self.employee = self.make_employee("EMP001", "9876500001", self.branch)
        self.client = APIClient()
        self.client.force_authenticate(self.user)

    def make_employee(self, code, phone, branch):
        user = User.objects.create_user(phone, role=User.Role.EMPLOYEE, first_name=code, last_name="Test")
        return user, Employee.objects.create(employee_code=code, user=user, branch=branch)

    def post_action(self, name, location=None, photo="default", client=None, **extra):
        data = dict(NEAR if location is None else location)
        if photo == "default":
            photo = image_file()
        if photo is not None:
            data["photo"] = photo
        data.update(extra)
        return (client or self.client).post(f"{BASE}{name}/", data, format="multipart")

    def check_in(self, **kwargs):
        return self.post_action("check-in", **kwargs)

    def check_out(self, **kwargs):
        return self.post_action("check-out", **kwargs)

    def media_files(self):
        return [os.path.join(root, f) for root, _, files in os.walk(self.media_root) for f in files]

    def error_code(self, response):
        return response.json()["errors"]["code"]


class AuthAndScopingTests(AttendanceAPITestCase):
    def test_10_unauthenticated_verify_location_rejected(self):
        response = APIClient().post(f"{BASE}verify-location/", NEAR, format="json")
        self.assertEqual(response.status_code, 401)

    def test_11_unauthenticated_check_in_and_others_rejected(self):
        anonymous = APIClient()
        self.assertEqual(self.check_in(client=anonymous).status_code, 401)
        self.assertEqual(self.check_out(client=anonymous).status_code, 401)
        self.assertEqual(anonymous.get(f"{BASE}today/").status_code, 401)
        self.assertEqual(Attendance.objects.count(), 0)

    def test_12_employee_cannot_create_attendance_for_another_employee(self):
        _, other = self.make_employee("EMP002", "9876500002", self.branch)
        response = self.check_in(employee_id=other.pk, employee=other.pk, branch_id=999, branch=999)
        self.assertEqual(response.status_code, 201)
        self.assertFalse(Attendance.objects.filter(employee=other).exists())
        self.assertEqual(Attendance.objects.get().employee, self.employee)
        self.assertEqual(Attendance.objects.get().branch, self.branch)

    def test_34_branch_comes_from_the_employees_own_assignment(self):
        other_org = Organization.objects.create(name="Other", code="OTH")
        far_branch = Branch.objects.create(
            organization=other_org, name="Elsewhere", code="ELS",
            latitude=Decimal("28.613900"), longitude=Decimal("77.209000"), attendance_radius_meters=100,
        )
        # Client claims the far branch; server still verifies against the employee's own branch.
        response = self.check_in(branch_id=far_branch.pk)
        self.assertEqual(response.status_code, 201)
        self.assertEqual(Attendance.objects.get().branch, self.branch)
        # An employee of the other branch cannot use this branch's coordinates
        other_user, _ = self.make_employee("EMP003", "9876500003", far_branch)
        client = APIClient()
        client.force_authenticate(other_user)
        self.assertEqual(self.error_code(self.check_in(client=client)), "OUTSIDE_ATTENDANCE_RADIUS")

    def test_34_employee_without_valid_branch(self):
        self.branch.is_active = False
        self.branch.save()
        self.assertEqual(self.error_code(self.check_in()), "NO_VALID_BRANCH")
        self.branch.is_active = True
        self.branch.save()
        self.org.is_active = False
        self.org.save()
        self.assertEqual(self.error_code(self.check_in()), "NO_VALID_BRANCH")
        self.org.is_active = True
        self.org.save()
        Employee.objects.filter(pk=self.employee.pk).update(branch=None)
        self.assertEqual(self.error_code(self.check_in()), "NO_VALID_BRANCH")
        self.assertEqual(Attendance.objects.count(), 0)

    def test_employee_profile_missing_or_inactive(self):
        no_profile = User.objects.create_user("9876509999", role=User.Role.EMPLOYEE)
        client = APIClient()
        client.force_authenticate(no_profile)
        response = client.get(f"{BASE}today/")
        self.assertEqual(response.status_code, 403)
        self.assertEqual(self.error_code(response), "EMPLOYEE_PROFILE_NOT_FOUND")
        Employee.objects.filter(pk=self.employee.pk).update(is_active=False)
        self.assertEqual(self.error_code(self.check_in()), "EMPLOYEE_PROFILE_NOT_FOUND")

    def test_35_existing_role_permissions_intact(self):
        # Admin-side roles are not employees: they cannot use the employee attendance APIs.
        hr = User.objects.create_user("9111111111", role=User.Role.HR, organization=self.org)
        hr.allowed_branches.add(self.branch)
        hr.user_permissions.add(Permission.objects.get(codename="view_employee", content_type__app_label="employees"))
        client = APIClient()
        client.force_authenticate(hr)
        self.assertEqual(client.get(f"{BASE}today/").status_code, 403)
        self.assertEqual(self.check_in(client=client).status_code, 403)
        # ...and existing employee/admin endpoints behave as before.
        self.assertEqual(self.client.get("/api/v1/mobile/me/").status_code, 200)
        self.assertEqual(client.get("/api/v1/employees/").status_code, 200)
        self.assertEqual(self.client.get("/api/v1/employees/").status_code, 403)


class VerifyLocationTests(AttendanceAPITestCase):
    def test_inside(self):
        response = self.client.post(f"{BASE}verify-location/", NEAR, format="json")
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertTrue(data["verified"])
        self.assertEqual(data["branch"], {"id": self.branch.pk, "name": "Cuddalore"})
        self.assertEqual(data["allowed_radius_meters"], 100)
        self.assertLess(data["distance_meters"], 100)
        self.assertEqual(Attendance.objects.count(), 0)  # verification never creates attendance

    def test_outside(self):
        response = self.client.post(f"{BASE}verify-location/", FAR, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.json()["data"]["verified"])
        self.assertEqual(response.json()["message"], "You are outside the allowed attendance area.")

    def test_invalid_input_and_unconfigured_branch(self):
        for field, value in (("latitude", 95), ("longitude", -200), ("accuracy", -3), ("latitude", "nan"), ("accuracy", None)):
            payload = {**NEAR, field: value}
            response = self.client.post(f"{BASE}verify-location/", payload, format="json")
            self.assertEqual(response.status_code, 400, msg=f"{field}={value}")
            self.assertIn(field, response.json()["errors"])
        Branch.objects.filter(pk=self.branch.pk).update(latitude=None, longitude=None)
        response = self.client.post(f"{BASE}verify-location/", NEAR, format="json")
        self.assertEqual(response.status_code, 409)
        self.assertEqual(self.error_code(response), "BRANCH_LOCATION_NOT_CONFIGURED")


class CheckInTests(AttendanceAPITestCase):
    def test_13_valid_check_in_and_response(self):
        response = self.check_in()
        self.assertEqual(response.status_code, 201)
        body = response.json()
        self.assertTrue(body["success"])
        self.assertEqual(body["message"], "Check-in successful.")
        attendance = body["data"]["attendance"]
        self.assertTrue(attendance["location_verified"])
        self.assertEqual(Attendance.objects.count(), 1)
        self.assertEqual(attendance["id"], Attendance.objects.get().pk)

    def test_14_outside_radius_rejected(self):
        response = self.check_in(location=FAR)
        self.assertEqual(response.status_code, 403)
        self.assertEqual(self.error_code(response), "OUTSIDE_ATTENDANCE_RADIUS")
        self.assertEqual(response.json()["errors"]["allowed_radius_meters"], 100)
        self.assertEqual(Attendance.objects.count(), 0)
        self.assertEqual(self.media_files(), [])

    def test_15_missing_photo_rejected(self):
        response = self.check_in(photo=None)
        self.assertEqual(response.status_code, 400)
        self.assertIn("photo", response.json()["errors"])
        self.assertEqual(Attendance.objects.count(), 0)

    def test_16_invalid_photo_rejected(self):
        bad = {
            "text disguised as jpg": SimpleUploadedFile("evil.jpg", b"definitely not an image", content_type="image/jpeg"),
            "executable": SimpleUploadedFile("run.exe", b"MZ\x90\x00", content_type="application/octet-stream"),
            "pdf": SimpleUploadedFile("doc.pdf", b"%PDF-1.4 fake", content_type="application/pdf"),
            "unsupported image format (GIF)": image_file("anim.gif", "GIF"),
            "empty": SimpleUploadedFile("empty.jpg", b"", content_type="image/jpeg"),
        }
        for label, upload in bad.items():
            response = self.check_in(photo=upload)
            self.assertEqual(response.status_code, 400, msg=label)
            self.assertIn("photo", response.json()["errors"], msg=label)
        self.assertEqual(Attendance.objects.count(), 0)
        self.assertEqual(self.media_files(), [])

    def test_photo_too_large_rejected(self):
        with patch("apps.attendance.validators.MAX_PHOTO_BYTES", 100):
            response = self.check_in()
        self.assertEqual(response.status_code, 400)
        self.assertIn("too large", response.json()["errors"]["photo"][0])
        self.assertEqual(Attendance.objects.count(), 0)

    def test_png_accepted_regardless_of_client_filename(self):
        response = self.check_in(photo=image_file("../../etc/passwd.jpg", "PNG", "image/png"))
        self.assertEqual(response.status_code, 201)
        self.assertTrue(Attendance.objects.get().check_in_photo.name.endswith(".png"))

    def test_17_duplicate_same_day_check_in_rejected(self):
        self.assertEqual(self.check_in().status_code, 201)
        files_before = self.media_files()
        response = self.check_in()
        self.assertEqual(response.status_code, 409)
        self.assertEqual(self.error_code(response), "ALREADY_CHECKED_IN")
        self.assertEqual(Attendance.objects.count(), 1)
        self.assertEqual(self.media_files(), files_before)  # no orphaned second photo

    def test_race_lost_to_unique_constraint_is_a_clean_error_without_orphan_file(self):
        self.assertEqual(self.check_in().status_code, 201)
        files_before = self.media_files()
        # Simulate two simultaneous requests: the pre-check passes, the DB constraint is the last line of defence.
        with patch("apps.attendance.services._todays_attendance_exists", return_value=False):
            response = self.check_in()
        self.assertEqual(response.status_code, 409)
        self.assertEqual(self.error_code(response), "ALREADY_CHECKED_IN")
        self.assertEqual(Attendance.objects.count(), 1)
        self.assertEqual(self.media_files(), files_before)

    def test_unique_constraint_exists_at_database_level(self):
        self.check_in()
        existing = Attendance.objects.get()
        with self.assertRaises(IntegrityError), transaction.atomic():
            Attendance.objects.create(
                employee=existing.employee, branch=existing.branch, attendance_date=existing.attendance_date,
                check_in_at=existing.check_in_at, check_in_latitude=Decimal("11.7"), check_in_longitude=Decimal("79.7"),
                check_in_accuracy=1, check_in_distance_meters=1, check_in_location_verified=True, check_in_photo="x.jpg",
            )

    def test_18_server_timestamp_and_timezone_date(self):
        # 20:00 UTC on 17 Oct is 01:30 on 18 Oct in the project time zone (Asia/Kolkata).
        fixed = datetime(2026, 10, 17, 20, 0, tzinfo=dt_timezone.utc)
        with patch("django.utils.timezone.now", return_value=fixed):
            response = self.check_in(check_in_at="2000-01-01T00:00:00Z", attendance_date="2000-01-01")
        self.assertEqual(response.status_code, 201)
        attendance = Attendance.objects.get()
        self.assertEqual(attendance.check_in_at, fixed)  # client-supplied time ignored
        self.assertEqual(str(attendance.attendance_date), "2026-10-18")

    def test_19_to_22_stored_evidence(self):
        self.check_in(location={"latitude": 11.7450123, "longitude": 79.7689456, "accuracy": 7.4})
        attendance = Attendance.objects.get()
        self.assertAlmostEqual(attendance.check_in_distance_meters, 35.1, delta=0.5)            # 19 distance
        self.assertEqual(attendance.check_in_accuracy, 7.4)                                      # 20 accuracy
        self.assertTrue(attendance.check_in_location_verified)                                   # 21 verified
        self.assertEqual(attendance.check_in_latitude, Decimal("11.7450123"))
        self.assertEqual(attendance.check_in_longitude, Decimal("79.7689456"))
        name = attendance.check_in_photo.name                                                    # 22 photo path
        self.assertRegex(name, r"^attendance/checkin/\d{4}/\d{2}/\d{2}/[0-9a-f]{8}-[0-9a-f-]{27}\.jpg$")
        self.assertTrue(os.path.isfile(attendance.check_in_photo.path))
        self.assertTrue(attendance.check_in_photo.path.startswith(self.media_root))
        self.assertNotIn("selfie", name)
        self.assertNotIn(self.user.phone_number, name)
        self.assertIsNone(attendance.check_out_at)


class CheckOutTests(AttendanceAPITestCase):
    def test_23_valid_checkout_updates_same_row(self):
        self.assertEqual(self.check_in().status_code, 201)
        row = Attendance.objects.get()
        response = self.check_out()
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["message"], "Check-out successful.")
        self.assertEqual(Attendance.objects.count(), 1)
        updated = Attendance.objects.get()
        self.assertEqual(updated.pk, row.pk)
        self.assertEqual(updated.check_in_at, row.check_in_at)
        self.assertIsNotNone(updated.check_out_at)
        self.assertGreaterEqual(updated.check_out_at, updated.check_in_at)
        self.assertEqual(response.json()["data"]["attendance"]["id"], row.pk)

    def test_24_checkout_without_check_in_rejected(self):
        response = self.check_out()
        self.assertEqual(response.status_code, 409)
        self.assertEqual(self.error_code(response), "NOT_CHECKED_IN")
        self.assertEqual(Attendance.objects.count(), 0)
        self.assertEqual(self.media_files(), [])

    def test_25_duplicate_checkout_rejected(self):
        self.check_in()
        self.assertEqual(self.check_out().status_code, 200)
        first = Attendance.objects.get()
        files_before = self.media_files()
        response = self.check_out()
        self.assertEqual(response.status_code, 409)
        self.assertEqual(self.error_code(response), "ALREADY_CHECKED_OUT")
        again = Attendance.objects.get()
        self.assertEqual(again.check_out_at, first.check_out_at)
        self.assertEqual(again.check_out_photo.name, first.check_out_photo.name)
        self.assertEqual(self.media_files(), files_before)

    def test_26_outside_radius_checkout_rejected(self):
        self.check_in()
        response = self.check_out(location=FAR)
        self.assertEqual(response.status_code, 403)
        self.assertEqual(self.error_code(response), "OUTSIDE_ATTENDANCE_RADIUS")
        self.assertIsNone(Attendance.objects.get().check_out_at)

    def test_27_missing_checkout_photo_rejected(self):
        self.check_in()
        response = self.check_out(photo=None)
        self.assertEqual(response.status_code, 400)
        self.assertIn("photo", response.json()["errors"])
        self.assertIsNone(Attendance.objects.get().check_out_at)

    def test_28_to_30_checkout_evidence_stored(self):
        self.check_in()
        self.check_out(location={"latitude": 11.7449, "longitude": 79.7690, "accuracy": 12.5})
        attendance = Attendance.objects.get()
        self.assertEqual(attendance.check_out_latitude, Decimal("11.7449000"))                 # 28 location
        self.assertEqual(attendance.check_out_longitude, Decimal("79.7690000"))
        self.assertEqual(attendance.check_out_accuracy, 12.5)
        self.assertAlmostEqual(attendance.check_out_distance_meters, 24.8, delta=0.5)          # 29 distance
        self.assertTrue(attendance.check_out_location_verified)
        self.assertRegex(attendance.check_out_photo.name,                                      # 30 photo
                         r"^attendance/checkout/\d{4}/\d{2}/\d{2}/[0-9a-f]{8}-[0-9a-f-]{27}\.jpg$")
        self.assertTrue(os.path.isfile(attendance.check_out_photo.path))
        self.assertNotEqual(attendance.check_in_photo.name, attendance.check_out_photo.name)

    def test_checkout_rejected_if_branch_changed_since_check_in(self):
        self.check_in()
        other = Branch.objects.create(organization=self.org, name="Second", code="SEC",
                                      latitude=BRANCH_LAT, longitude=BRANCH_LON, attendance_radius_meters=100)
        Employee.objects.filter(pk=self.employee.pk).update(branch=other)
        response = self.check_out()
        self.assertEqual(response.status_code, 409)
        self.assertEqual(self.error_code(response), "BRANCH_MISMATCH")
        self.assertIsNone(Attendance.objects.get().check_out_at)

    def test_yesterdays_check_in_does_not_satisfy_todays_checkout(self):
        yesterday = datetime(2026, 10, 16, 5, 0, tzinfo=dt_timezone.utc)
        today = datetime(2026, 10, 17, 5, 0, tzinfo=dt_timezone.utc)
        with patch("django.utils.timezone.now", return_value=yesterday):
            self.assertEqual(self.check_in().status_code, 201)
        with patch("django.utils.timezone.now", return_value=today):
            self.assertEqual(self.error_code(self.check_out()), "NOT_CHECKED_IN")
            self.assertEqual(self.check_in().status_code, 201)  # a new day gets its own row
        self.assertEqual(Attendance.objects.count(), 2)


class TodayTests(AttendanceAPITestCase):
    def today(self):
        response = self.client.get(f"{BASE}today/")
        self.assertEqual(response.status_code, 200)
        return response.json()["data"]

    def test_31_not_checked_in(self):
        data = self.today()
        self.assertEqual(data["state"], "NOT_CHECKED_IN")
        self.assertIsNone(data["check_in_at"])
        self.assertIsNone(data["check_out_at"])
        self.assertRegex(data["attendance_date"], r"^\d{4}-\d{2}-\d{2}$")

    def test_32_checked_in(self):
        self.check_in()
        data = self.today()
        self.assertEqual(data["state"], "CHECKED_IN")
        self.assertIsNotNone(data["check_in_at"])
        self.assertIsNone(data["check_out_at"])

    def test_33_checked_out(self):
        self.check_in()
        self.check_out()
        data = self.today()
        self.assertEqual(data["state"], "CHECKED_OUT")
        self.assertIsNotNone(data["check_in_at"])
        self.assertIsNotNone(data["check_out_at"])

    def test_today_only_reports_own_attendance(self):
        other_user, _ = self.make_employee("EMP002", "9876500002", self.branch)
        other = APIClient()
        other.force_authenticate(other_user)
        self.check_in()
        self.assertEqual(other.get(f"{BASE}today/").json()["data"]["state"], "NOT_CHECKED_IN")


class MediaIsolationTests(AttendanceAPITestCase):
    def test_36_uploads_go_to_the_temporary_media_root(self):
        from django.conf import settings
        self.assertEqual(str(settings.MEDIA_ROOT), self.media_root)
        self.assertIn("lyra_test_media_", self.media_root)
        self.check_in()
        files = self.media_files()
        self.assertEqual(len(files), 1)
        self.assertTrue(files[0].startswith(self.media_root))
