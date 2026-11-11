import math
import os
import re
import shutil
import tempfile
import threading
import unittest
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone as dt_timezone
from decimal import Decimal
from io import BytesIO
from unittest.mock import patch

from django.contrib.auth.models import Permission
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import SimpleUploadedFile
from django.db import IntegrityError, connection, transaction
from django.test.utils import CaptureQueriesContext
from django.test import SimpleTestCase, TestCase, TransactionTestCase, override_settings
from django.utils import timezone
from PIL import Image
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.employees.models import AttendancePermissionAudit, Employee
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
            services.verify_attendance_location(branch, 11.7, 79.7, 5, timezone.now())
        self.assertEqual(ctx.exception.code, "BRANCH_LOCATION_NOT_CONFIGURED")
        self.assertEqual(ctx.exception.message, "Attendance location is not configured for this branch.")

    def test_only_one_coordinate_is_rejected(self):
        with self.assertRaises(ValidationError):
            self.make(longitude=None).full_clean()


class LocationServiceTests(SimpleTestCase):
    def branch(self, radius=100):
        return Branch(name="Cuddalore", code="CDL", latitude=BRANCH_LAT, longitude=BRANCH_LON, attendance_radius_meters=radius)

    def verify(self, branch, latitude, longitude, accuracy, location_timestamp=None):
        return services.verify_attendance_location(
            branch, latitude, longitude, accuracy, location_timestamp or timezone.now(),
        )

    def test_06_inside_radius(self):
        result = self.verify(self.branch(), NEAR["latitude"], NEAR["longitude"], 7.4)
        self.assertTrue(result.verified)
        self.assertAlmostEqual(result.distance_meters, 33.4, delta=1.0)
        self.assertEqual(result.allowed_radius_meters, 100)
        self.assertEqual(result.accuracy_meters, 7.4)

    def test_07_outside_radius(self):
        result = self.verify(self.branch(), FAR["latitude"], FAR["longitude"], 7.4)
        self.assertFalse(result.verified)
        self.assertAlmostEqual(result.distance_meters, 367, delta=3.0)

    def test_08_boundary(self):
        distance = services.calculate_distance_meters(NEAR["latitude"], NEAR["longitude"], float(BRANCH_LAT), float(BRANCH_LON))
        just_inside = self.branch(radius=math.ceil(distance))
        just_outside = self.branch(radius=math.floor(distance))
        self.assertTrue(self.verify(just_inside, NEAR["latitude"], NEAR["longitude"], 5).verified)
        self.assertFalse(self.verify(just_outside, NEAR["latitude"], NEAR["longitude"], 5).verified)
        # standing exactly on the branch point is distance 0
        on_point = self.verify(self.branch(radius=10), float(BRANCH_LAT), float(BRANCH_LON), 5)
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
                services.verify_attendance_location(self.branch(), *args, location_timestamp=timezone.now())
            self.assertEqual(ctx.exception.code, code, msg=str(args))

    def test_accuracy_must_not_exceed_branch_radius(self):
        with self.assertRaises(AttendanceError) as ctx:
            self.verify(self.branch(radius=10), NEAR["latitude"], NEAR["longitude"], 10.01)
        self.assertEqual(ctx.exception.code, "GPS_ACCURACY_EXCEEDS_RADIUS")

    def test_40_meter_radius_accepts_39_and_40_but_rejects_41(self):
        branch = self.branch(radius=40)
        with patch("apps.attendance.services.calculate_distance_meters", side_effect=(39, 40, 41)):
            results = [
                self.verify(branch, NEAR["latitude"], NEAR["longitude"], 10)
                for _ in range(3)
            ]

        self.assertEqual([result.verified for result in results], [True, True, False])
        self.assertEqual([result.distance_meters for result in results], [39, 40, 41])

    def test_location_timestamp_age_and_future_boundaries(self):
        now = timezone.now()
        branch = self.branch()
        with patch("apps.attendance.services.timezone.now", return_value=now):
            self.verify(branch, *NEAR.values(), location_timestamp=now - timedelta(seconds=120))
            with self.assertRaises(AttendanceError) as stale:
                self.verify(branch, *NEAR.values(), location_timestamp=now - timedelta(seconds=120, microseconds=1))
            self.assertEqual(stale.exception.code, "STALE_LOCATION")

            self.verify(branch, *NEAR.values(), location_timestamp=now + timedelta(seconds=30))
            with self.assertRaises(AttendanceError) as future:
                self.verify(branch, *NEAR.values(), location_timestamp=now + timedelta(seconds=30, microseconds=1))
            self.assertEqual(future.exception.code, "FUTURE_LOCATION")

    def test_exact_distance_boundary_is_inclusive(self):
        branch = self.branch()
        with patch("apps.attendance.services.calculate_distance_meters", return_value=100.0):
            self.assertTrue(self.verify(branch, NEAR["latitude"], NEAR["longitude"], 7.4).verified)


class AttendanceAPITestCase(TestCase):
    def setUp(self):
        media = tempfile.mkdtemp(prefix="lyra_test_media_")
        private_media = tempfile.mkdtemp(prefix="lyra_test_private_media_")
        self.media_root = media
        self.private_media_root = private_media
        override = override_settings(MEDIA_ROOT=media, PRIVATE_MEDIA_ROOT=private_media, ROOT_URLCONF="config.urls")
        override.enable()
        self.addCleanup(override.disable)
        self.addCleanup(shutil.rmtree, media, ignore_errors=True)
        self.addCleanup(shutil.rmtree, private_media, ignore_errors=True)

        self.org = Organization.objects.create(name="Devi", code="DEVI")
        self.branch = Branch.objects.create(
            organization=self.org, name="Cuddalore", code="CDL",
            latitude=BRANCH_LAT, longitude=BRANCH_LON, attendance_radius_meters=100,
        )
        self.user, self.employee = self.make_employee("EMP001", "9876500001", self.branch)
        # Legacy attendance-flow tests model employees whose existing settings were preserved by
        # the 0003/0004 data migrations. New employees remain disabled by default in model tests.
        self.employee.mobile_gps_attendance_enabled = True
        self.employee.photo_attendance_enabled = True
        self.employee.location_attendance_enabled = True
        self.employee.save(update_fields=("mobile_gps_attendance_enabled", "photo_attendance_enabled", "location_attendance_enabled"))
        self.client = APIClient()
        self.client.force_authenticate(self.user)
        self._idempotency_timestamps = {}

    def location_payload(self, location=None, *, timestamp=None, **overrides):
        payload = dict(NEAR if location is None else location)
        payload.update(overrides)
        payload.setdefault("location_timestamp", timestamp or timezone.now().isoformat())
        return payload

    def make_employee(self, code, phone, branch):
        user = User.objects.create_user(phone, role=User.Role.EMPLOYEE, first_name=code, last_name="Test")
        return user, Employee.objects.create(employee_code=code, user=user, branch=branch)

    def post_action(self, name, location=None, photo="default", client=None, idempotency_key=None, **extra):
        data = dict(NEAR if location is None else location)
        if "location_timestamp" not in data:
            if idempotency_key:
                timestamp = self._idempotency_timestamps.setdefault(
                    idempotency_key, timezone.now().isoformat(),
                )
            else:
                timestamp = timezone.now().isoformat()
            data["location_timestamp"] = timestamp
        if photo == "default":
            photo = image_file()
        if photo is not None:
            data["photo"] = photo
        data.update(extra)
        headers = {} if idempotency_key is None else {"HTTP_IDEMPOTENCY_KEY": idempotency_key}
        return (client or self.client).post(f"{BASE}{name}/", data, format="multipart", **headers)

    def check_in(self, **kwargs):
        return self.post_action("check-in", **kwargs)

    def check_out(self, **kwargs):
        return self.post_action("check-out", **kwargs)

    def media_files(self):
        return [os.path.join(root, f) for root, _, files in os.walk(self.private_media_root) for f in files]

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
        Employee.objects.filter(user=other_user).update(
            mobile_gps_attendance_enabled=True,
            photo_attendance_enabled=True,
            location_attendance_enabled=True,
        )
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
    def test_location_verification_disabled_is_not_reported_as_verified(self):
        self.employee.location_attendance_enabled = False
        self.employee.save(update_fields=("location_attendance_enabled",))

        response = self.client.post(f"{BASE}verify-location/", {}, format="json")

        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertIsNone(data["verified"])
        self.assertIsNone(data["distance_meters"])
        self.assertIsNone(data["allowed_radius_meters"])
        self.assertIn("not required", response.json()["message"])

    def test_inside(self):
        response = self.client.post(f"{BASE}verify-location/", self.location_payload(), format="json")
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertTrue(data["verified"])
        self.assertEqual(data["branch"], {"id": self.branch.pk, "name": "Cuddalore"})
        self.assertEqual(data["allowed_radius_meters"], 100)
        self.assertLess(data["distance_meters"], 100)
        self.assertEqual(Attendance.objects.count(), 0)  # verification never creates attendance

    def test_outside(self):
        response = self.client.post(f"{BASE}verify-location/", self.location_payload(FAR), format="json")
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.json()["data"]["verified"])
        self.assertEqual(response.json()["message"], "You are outside the allowed attendance area.")

    def test_invalid_input_and_unconfigured_branch(self):
        for field, value in (("latitude", 95), ("longitude", -200), ("accuracy", -3), ("latitude", "nan"), ("accuracy", None)):
            payload = {**self.location_payload(), field: value}
            response = self.client.post(f"{BASE}verify-location/", payload, format="json")
            self.assertEqual(response.status_code, 400, msg=f"{field}={value}")
            self.assertIn(field, response.json()["errors"])
        Branch.objects.filter(pk=self.branch.pk).update(latitude=None, longitude=None)
        response = self.client.post(f"{BASE}verify-location/", self.location_payload(), format="json")
        self.assertEqual(response.status_code, 409)
        self.assertEqual(self.error_code(response), "BRANCH_LOCATION_NOT_CONFIGURED")

    def test_accuracy_equal_to_radius_is_accepted_and_greater_is_rejected(self):
        payload = self.location_payload(accuracy=100)
        self.assertEqual(self.client.post(f"{BASE}verify-location/", payload, format="json").status_code, 200)
        payload["accuracy"] = 100.01
        response = self.client.post(f"{BASE}verify-location/", payload, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertEqual(self.error_code(response), "GPS_ACCURACY_EXCEEDS_RADIUS")

    def test_timestamp_age_and_future_validation(self):
        fixed = timezone.now()
        with patch("apps.attendance.services.timezone.now", return_value=fixed):
            for offset, expected in (
                (-120, 200), (-120.001, 400), (30, 200), (30.001, 400),
            ):
                payload = self.location_payload(timestamp=(fixed + timedelta(seconds=offset)).isoformat())
                response = self.client.post(f"{BASE}verify-location/", payload, format="json")
                self.assertEqual(response.status_code, expected, msg=f"offset={offset}")
                if expected == 400:
                    self.assertIn(self.error_code(response), {"STALE_LOCATION", "FUTURE_LOCATION"})

    def test_missing_and_malformed_timestamp_rejected(self):
        payload = dict(NEAR)
        response = self.client.post(f"{BASE}verify-location/", payload, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertIn("location_timestamp", response.json()["errors"])
        payload["location_timestamp"] = "not-a-timestamp"
        response = self.client.post(f"{BASE}verify-location/", payload, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertIn("location_timestamp", response.json()["errors"])

    def test_coordinate_nonfinite_and_malformed_values_are_rejected(self):
        for field, value in (
            ("latitude", None), ("longitude", None), ("latitude", "abc"),
            ("latitude", "Infinity"), ("longitude", "NaN"), ("accuracy", "NaN"),
        ):
            response = self.client.post(
                f"{BASE}verify-location/", self.location_payload({**NEAR, field: value}), format="json",
            )
            self.assertEqual(response.status_code, 400, msg=f"{field}={value}")

        payload = self.location_payload()
        payload.pop("latitude")
        response = self.client.post(f"{BASE}verify-location/", payload, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertIn("latitude", response.json()["errors"])

    def test_different_branch_radii_produce_different_results(self):
        payload = self.location_payload(NEAR)
        self.branch.attendance_radius_meters = 40
        self.branch.save(update_fields=("attendance_radius_meters",))
        self.assertTrue(self.client.post(f"{BASE}verify-location/", payload, format="json").json()["data"]["verified"])
        self.branch.attendance_radius_meters = 10
        self.branch.save(update_fields=("attendance_radius_meters",))
        self.assertFalse(self.client.post(f"{BASE}verify-location/", payload, format="json").json()["data"]["verified"])

    def test_mobile_punch_revalidates_location_timestamp(self):
        fixed = timezone.now()
        payload = self.location_payload(timestamp=(fixed - timedelta(seconds=121)).isoformat())
        with patch("apps.attendance.services.timezone.now", return_value=fixed):
            response = self.check_in(location=payload)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(self.error_code(response), "STALE_LOCATION")
        self.assertEqual(Attendance.objects.count(), 0)


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
        self.assertEqual(response.json()["errors"]["code"], "PHOTO_REQUIRED")
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
            response = self.check_in(
                check_in_at="2000-01-01T00:00:00Z",
                attendance_date="2000-01-01",
                location_timestamp=fixed.isoformat(),
            )
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
        self.assertTrue(attendance.check_in_photo.path.startswith(self.private_media_root))
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
        self.assertEqual(response.json()["errors"]["code"], "PHOTO_REQUIRED")
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


class AttendancePermissionApiTests(AttendanceAPITestCase):
    permissions_url = "/api/v1/attendance-permissions/"

    def setUp(self):
        super().setUp()
        Employee.objects.filter(pk=self.employee.pk).update(
            mobile_gps_attendance_enabled=False,
            photo_attendance_enabled=False,
            location_attendance_enabled=False,
        )
        self.employee.refresh_from_db()

    def admin_client(self, *, branch=None, role=User.Role.ADMIN):
        admin = User.objects.create_user(
            f"admin-{Employee.objects.count()}-{role.lower()}@example.test",
            role=role,
            organization=self.org if role != User.Role.SUPERADMIN else None,
        )
        if branch is not None:
            admin.allowed_branches.add(branch)
        client = APIClient()
        client.force_authenticate(admin)
        return client, admin

    def assert_employee_only_lock(self, queries):
        lock_queries = [query["sql"] for query in queries if "FOR UPDATE" in query["sql"].upper()]
        self.assertTrue(lock_queries, "Expected the update query to lock employee rows.")
        for sql in lock_queries:
            self.assertRegex(sql, r'FOR UPDATE OF ("?employees_employee"?)')

    @unittest.skipUnless(connection.vendor == "postgresql", "PostgreSQL row-lock SQL assertion")
    def test_individual_patch_locks_only_employee_row(self):
        client, _ = self.admin_client(branch=self.branch)
        with CaptureQueriesContext(connection) as queries:
            response = client.patch(
                f"{self.permissions_url}{self.employee.pk}/",
                {"mobile_gps_attendance_enabled": True},
                format="json",
            )
        self.assertEqual(response.status_code, 200, response.content)
        self.assert_employee_only_lock(queries)

    @unittest.skipUnless(connection.vendor == "postgresql", "PostgreSQL row-lock SQL assertion")
    def test_bulk_patch_locks_only_employee_rows(self):
        _, second = self.make_employee("EMP002", "9876500018", self.branch)
        client, _ = self.admin_client(branch=self.branch)
        with CaptureQueriesContext(connection) as queries:
            response = client.post(self.permissions_url + "bulk/", {
                "employee_ids": [self.employee.pk, second.pk],
                "permissions": {"auto_punch_out_enabled": True},
            }, format="json")
        self.assertEqual(response.status_code, 200, response.content)
        self.assert_employee_only_lock(queries)

    def test_scoped_listing_and_update_create_audit_record(self):
        client, admin = self.admin_client(branch=self.branch)
        response = client.get(self.permissions_url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual([row["id"] for row in response.json()["data"]["results"]], [self.employee.pk])
        updated = client.patch(
            f"{self.permissions_url}{self.employee.pk}/",
            {"mobile_gps_attendance_enabled": True, "location_attendance_enabled": True},
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertTrue(updated.json()["data"]["mobile_gps_attendance_enabled"])
        audit = AttendancePermissionAudit.objects.get(employee=self.employee)
        self.assertEqual(audit.actor, admin)
        self.assertEqual(audit.previous_values["mobile_gps_attendance_enabled"], False)
        self.assertEqual(audit.new_values["location_attendance_enabled"], True)

    def test_bulk_update_saves_permissions_and_audit_for_each_in_scope_employee(self):
        _, second = self.make_employee("EMP002", "9876500017", self.branch)
        client, admin = self.admin_client(branch=self.branch)
        response = client.post(self.permissions_url + "bulk/", {
            "employee_ids": [self.employee.pk, second.pk],
            "permissions": {"biometric_attendance_enabled": True, "auto_punch_out_enabled": True},
        }, format="json")
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(response.json()["data"]["updated"], 2)
        self.assertEqual(AttendancePermissionAudit.objects.filter(actor=admin).count(), 2)
        self.assertTrue(Employee.objects.get(pk=self.employee.pk).biometric_attendance_enabled)
        self.assertTrue(Employee.objects.get(pk=second.pk).auto_punch_out_enabled)

    def test_employee_outside_branch_scope_cannot_be_updated(self):
        other_org = Organization.objects.create(name="Other", code="OTHER")
        other_branch = Branch.objects.create(organization=other_org, name="Elsewhere", code="OTHER-B")
        _, other_employee = self.make_employee("EMP-OTHER", "9876500015", other_branch)
        client, _ = self.admin_client(branch=self.branch)
        response = client.patch(f"{self.permissions_url}{other_employee.pk}/", {"mobile_gps_attendance_enabled": True}, format="json")
        self.assertEqual(response.status_code, 404)
        self.assertFalse(other_employee.refresh_from_db() or other_employee.mobile_gps_attendance_enabled)

    def test_bulk_update_is_atomic_and_scope_checked(self):
        other_org = Organization.objects.create(name="Other", code="OTHER")
        other_branch = Branch.objects.create(organization=other_org, name="Elsewhere", code="OTHER-B")
        _, other_employee = self.make_employee("EMP-OTHER", "9876500016", other_branch)
        client, _ = self.admin_client(branch=self.branch)
        response = client.post(self.permissions_url + "bulk/", {
            "employee_ids": [self.employee.pk, other_employee.pk],
            "permissions": {"biometric_attendance_enabled": True},
        }, format="json")
        self.assertEqual(response.status_code, 404)
        self.employee.refresh_from_db()
        self.assertFalse(self.employee.biometric_attendance_enabled)
        self.assertEqual(AttendancePermissionAudit.objects.count(), 0)


class IndependentLocationPermissionTests(AttendanceAPITestCase):
    def enable_mobile(self, *, location=False, photo=False):
        self.employee.mobile_gps_attendance_enabled = True
        self.employee.location_attendance_enabled = location
        self.employee.photo_attendance_enabled = photo
        self.employee.save(update_fields=("mobile_gps_attendance_enabled", "location_attendance_enabled", "photo_attendance_enabled"))

    def test_location_off_allows_check_in_and_check_out_without_gps(self):
        self.enable_mobile(location=False)
        response = self.client.post(f"{BASE}check-in/", {}, format="multipart")
        self.assertEqual(response.status_code, 201, response.content)
        attendance = Attendance.objects.get()
        self.assertIsNone(attendance.check_in_location_verified)
        self.assertIsNone(attendance.check_in_latitude)
        response = self.client.post(f"{BASE}check-out/", {}, format="multipart")
        self.assertEqual(response.status_code, 200, response.content)
        attendance.refresh_from_db()
        self.assertIsNone(attendance.check_out_location_verified)

    def test_location_on_requires_gps_and_rejects_outside_radius(self):
        self.enable_mobile(location=True)
        missing = self.client.post(f"{BASE}check-in/", {"photo": image_file()}, format="multipart")
        self.assertEqual(missing.status_code, 400)
        self.assertEqual(self.error_code(missing), "INVALID_GPS_ACCURACY")
        outside = self.check_in(location=FAR, photo=None)
        self.assertEqual(self.error_code(outside), "OUTSIDE_ATTENDANCE_RADIUS")
        self.assertEqual(Attendance.objects.count(), 0)

    def test_location_off_ignores_outside_coordinates(self):
        self.enable_mobile(location=False)
        response = self.check_in(location=FAR, photo=None)
        self.assertEqual(response.status_code, 201, response.content)
        self.assertIsNone(Attendance.objects.get().check_in_location_verified)


class MediaIsolationTests(AttendanceAPITestCase):
    def test_36_uploads_go_to_the_temporary_private_media_root(self):
        from django.conf import settings
        self.assertEqual(str(settings.MEDIA_ROOT), self.media_root)
        self.assertEqual(str(settings.PRIVATE_MEDIA_ROOT), self.private_media_root)
        self.assertIn("lyra_test_media_", self.media_root)
        self.assertIn("lyra_test_private_media_", self.private_media_root)
        self.check_in()
        files = self.media_files()
        self.assertEqual(len(files), 1)
        self.assertTrue(files[0].startswith(self.private_media_root))
        self.assertEqual(
            [os.path.join(root, f) for root, _, files in os.walk(self.media_root) for f in files],
            [],
        )

    def test_public_debug_media_does_not_serve_legacy_attendance_photos(self):
        from django.core.files.storage import FileSystemStorage

        self.check_in()
        attendance = Attendance.objects.get()
        public_storage = FileSystemStorage(location=self.media_root)
        name = "attendance/legacy/private.jpg"
        public_storage.save(name, image_file())
        Attendance.objects.filter(pk=attendance.pk).update(check_in_photo=name)
        response = self.client.get(f"/media/{name}")
        self.assertEqual(response.status_code, 404)
        self.assertEqual(self.client.get(f"{BASE}{attendance.pk}/photos/check-in/").status_code, 200)

    def test_new_photo_is_available_only_to_its_employee(self):
        self.assertEqual(self.check_in().status_code, 201)
        attendance = Attendance.objects.get()
        photo_url = f"{BASE}{attendance.pk}/photos/check-in/"
        response = self.client.get(photo_url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response["Content-Type"], "image/jpeg")
        self.assertEqual(response["Cache-Control"], "private, no-store")
        self.assertTrue(b"JFIF" in b"".join(response.streaming_content))

        other_user, other_employee = self.make_employee("EMP-PRIVATE", "9876500099", self.branch)
        other_employee.mobile_gps_attendance_enabled = True
        other_employee.save(update_fields=("mobile_gps_attendance_enabled",))
        other_client = APIClient()
        other_client.force_authenticate(other_user)
        self.assertEqual(other_client.get(photo_url).status_code, 404)
        self.assertEqual(APIClient().get(photo_url).status_code, 401)


class MobileIdempotencyAndHistoryTests(AttendanceAPITestCase):
    def test_changed_location_timestamp_is_not_an_idempotent_replay(self):
        fixed = timezone.now()
        original = self.check_in(
            idempotency_key="timestamp-key",
            location_timestamp=fixed.isoformat(),
        )
        self.assertEqual(original.status_code, 201)
        changed = self.check_in(
            idempotency_key="timestamp-key",
            location_timestamp=(fixed - timedelta(seconds=1)).isoformat(),
        )
        self.assertEqual(changed.status_code, 409)
        self.assertEqual(self.error_code(changed), "IDEMPOTENCY_KEY_REUSED")

    def test_same_key_replays_original_check_in_response(self):
        first = self.check_in(idempotency_key="same-check-in-key")
        replay = self.check_in(idempotency_key="same-check-in-key")
        self.assertEqual(first.status_code, 201)
        self.assertEqual(replay.status_code, 201)
        self.assertEqual(replay.json(), first.json())
        self.assertEqual(Attendance.objects.count(), 1)
        self.assertEqual(len(self.media_files()), 1)

    def test_delayed_check_in_replay_after_checkout_does_not_open_another_session(self):
        original = self.check_in(idempotency_key="delayed-check-in-key")
        self.assertEqual(self.check_out(idempotency_key="check-out-key").status_code, 200)
        replay = self.check_in(idempotency_key="delayed-check-in-key")
        self.assertEqual(replay.status_code, 201)
        self.assertEqual(replay.json(), original.json())
        self.assertEqual(Attendance.objects.count(), 1)
        self.assertIsNotNone(Attendance.objects.get().check_out_at)

    def test_key_cannot_be_reused_for_another_payload_employee_or_action(self):
        self.assertEqual(self.check_in(idempotency_key="payload-key").status_code, 201)
        changed_payload = self.check_in(
            idempotency_key="payload-key",
            location={"latitude": 11.7451, "longitude": 79.7689, "accuracy": 7.4},
        )
        self.assertEqual(changed_payload.status_code, 409)
        self.assertEqual(self.error_code(changed_payload), "IDEMPOTENCY_KEY_REUSED")

        other_user, other_employee = self.make_employee("EMP-KEY", "9876500098", self.branch)
        other_employee.mobile_gps_attendance_enabled = True
        other_employee.photo_attendance_enabled = True
        other_employee.location_attendance_enabled = True
        other_employee.save(update_fields=("mobile_gps_attendance_enabled", "photo_attendance_enabled", "location_attendance_enabled"))
        other_client = APIClient()
        other_client.force_authenticate(other_user)
        different_owner = self.check_in(client=other_client, idempotency_key="payload-key")
        self.assertEqual(different_owner.status_code, 409)
        self.assertEqual(self.error_code(different_owner), "IDEMPOTENCY_KEY_REUSED")
        different_action = self.check_out(idempotency_key="payload-key")
        self.assertEqual(different_action.status_code, 409)
        self.assertEqual(self.error_code(different_action), "IDEMPOTENCY_KEY_REUSED")
        self.assertEqual(Attendance.objects.count(), 1)

    def test_distinct_keys_allow_multiple_sessions_and_legacy_requests_still_work(self):
        self.assertEqual(self.check_in(idempotency_key="first-session-in").status_code, 201)
        self.assertEqual(self.check_out(idempotency_key="first-session-out").status_code, 200)
        self.assertEqual(self.check_in(idempotency_key="second-session-in").status_code, 201)
        self.assertEqual(Attendance.objects.count(), 2)

        Attendance.objects.filter(employee=self.employee, check_out_at__isnull=True).update(check_out_at=timezone.now())
        self.assertEqual(self.check_in().status_code, 201)
        self.assertEqual(Attendance.objects.count(), 3)

    def test_expected_business_error_is_replayed_with_original_status_and_body(self):
        first = self.check_in(location=FAR, idempotency_key="rejected-check-in")
        replay = self.check_in(location=FAR, idempotency_key="rejected-check-in")
        self.assertEqual(first.status_code, 403)
        self.assertEqual(replay.status_code, 403)
        self.assertEqual(replay.json(), first.json())
        self.assertEqual(Attendance.objects.count(), 0)

    def test_invalid_key_is_rejected(self):
        response = self.check_in(idempotency_key="bad key")
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Attendance.objects.count(), 0)

    def test_history_is_employee_scoped_date_filtered_and_paginated(self):
        self.check_in(idempotency_key="history-session-in")
        self.check_out(idempotency_key="history-session-out")
        today = timezone.localdate()
        other_user, other_employee = self.make_employee("EMP-HISTORY", "9876500097", self.branch)
        Attendance.objects.create(
            employee=other_employee,
            branch=self.branch,
            attendance_date=today,
            check_in_at=timezone.now(),
        )
        Attendance.objects.create(
            employee=self.employee,
            branch=self.branch,
            attendance_date=today,
            check_in_at=timezone.now() - timedelta(minutes=30),
            check_out_at=timezone.now() - timedelta(minutes=15),
        )
        url = f"{BASE}history/?start_date={today.isoformat()}&end_date={today.isoformat()}&page_size=1"
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["count"], 2)
        self.assertTrue(data["has_next"])
        self.assertEqual(len(data["results"]), 1)
        record = data["results"][0]
        self.assertIn(record["id"], Attendance.objects.filter(employee=self.employee).values_list("pk", flat=True))
        self.assertNotIn("photo", record)
        second_page = self.client.get(url + "&page=2").json()["data"]
        self.assertEqual(len(second_page["results"]), 1)
        self.assertFalse(second_page["has_next"])
        self.assertEqual(
            self.client.get(f"{BASE}history/?start_date={today.isoformat()}&end_date=2020-01-01").status_code,
            400,
        )
        self.assertEqual(
            self.client.get(f"{BASE}history/?start_date={(today + timedelta(days=1)).isoformat()}").status_code,
            400,
        )
        self.assertEqual(
            self.client.get(f"{BASE}history/?employee_id={other_employee.pk}").json()["data"]["count"],
            2,
        )
        self.assertEqual(APIClient().get(f"{BASE}history/").status_code, 401)

    def test_employee_jwt_can_access_own_profile_and_attendance(self):
        from rest_framework_simplejwt.tokens import AccessToken

        client = APIClient()
        client.credentials(HTTP_AUTHORIZATION=f"Bearer {AccessToken.for_user(self.user)}")
        self.assertEqual(client.get("/api/v1/mobile/me/").status_code, 200)
        self.assertEqual(client.get(f"{BASE}today/").status_code, 200)
        self.assertEqual(self.check_in(client=client).status_code, 201)
        self.assertEqual(self.check_out(client=client).status_code, 200)
        self.assertEqual(client.get(f"{BASE}history/").status_code, 200)

    def test_missed_checkout_remains_in_history_without_polluting_today_state(self):
        yesterday = timezone.localdate() - timedelta(days=1)
        missed_session = Attendance.objects.create(
            employee=self.employee,
            branch=self.branch,
            attendance_date=yesterday,
            check_in_at=timezone.now() - timedelta(days=1),
        )

        today = self.client.get(f"{BASE}today/")
        self.assertEqual(today.status_code, 200)
        self.assertEqual(today.json()["data"]["state"], "NOT_CHECKED_IN")
        self.assertEqual(today.json()["data"]["sessions"], [])

        history = self.client.get(f"{BASE}history/?start_date={yesterday.isoformat()}&end_date={yesterday.isoformat()}")
        self.assertEqual(history.status_code, 200)
        record = history.json()["data"]["results"][0]
        self.assertEqual(record["id"], missed_session.pk)
        self.assertIsNone(record["check_out_at"])
        self.assertIsNone(record["working_seconds"])
        self.assertEqual(record["status"], "CHECKED_IN")


class ConcurrentMobileIdempotencyTests(TransactionTestCase):
    reset_sequences = True

    def setUp(self):
        self.media_root = tempfile.mkdtemp(prefix="lyra_concurrent_media_")
        self.private_media_root = tempfile.mkdtemp(prefix="lyra_concurrent_private_media_")
        override = override_settings(
            MEDIA_ROOT=self.media_root,
            PRIVATE_MEDIA_ROOT=self.private_media_root,
            ROOT_URLCONF="config.urls",
        )
        override.enable()
        self.addCleanup(override.disable)
        self.addCleanup(shutil.rmtree, self.media_root, ignore_errors=True)
        self.addCleanup(shutil.rmtree, self.private_media_root, ignore_errors=True)
        organization = Organization.objects.create(name="Concurrent", code="CONCURRENT")
        branch = Branch.objects.create(
            organization=organization,
            name="Concurrent branch",
            code="CONCURRENT-B",
            latitude=BRANCH_LAT,
            longitude=BRANCH_LON,
            attendance_radius_meters=100,
        )
        self.user = User.objects.create_user("9876500096", role=User.Role.EMPLOYEE)
        employee = Employee.objects.create(employee_code="EMP-CONCURRENT", user=self.user, branch=branch)
        employee.mobile_gps_attendance_enabled = True
        employee.photo_attendance_enabled = True
        employee.location_attendance_enabled = True
        employee.save(update_fields=("mobile_gps_attendance_enabled", "photo_attendance_enabled", "location_attendance_enabled"))
        self.location_timestamp = timezone.now().isoformat()

    def test_concurrent_same_key_creates_one_session_and_returns_same_result(self):
        barrier = threading.Barrier(2)

        def send_punch():
            client = APIClient()
            client.force_authenticate(self.user)
            barrier.wait(timeout=5)
            return client.post(
                f"{BASE}check-in/",
                {**NEAR, "location_timestamp": self.location_timestamp, "photo": image_file()},
                format="multipart",
                HTTP_IDEMPOTENCY_KEY="concurrent-same-key",
            )

        with ThreadPoolExecutor(max_workers=2) as pool:
            responses = list(pool.map(lambda _: send_punch(), range(2)))
        self.assertEqual([response.status_code for response in responses], [201, 201])
        self.assertEqual(responses[0].json(), responses[1].json())
        self.assertEqual(Attendance.objects.count(), 1)
