"""Tests for the Admin Attendance APIs (list, summary, detail, CSV export).

The existing mobile attendance tests live in tests.py and are not modified; run them together:
    python manage.py test apps.attendance
"""
import csv
import datetime as dt
import io
import shutil
import tempfile

from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.accounts.services.role_permissions import ensure_role_group
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from apps.employees.models import Employee
from apps.organizations.models import Organization

from . import admin_services
from .models import Attendance
from .tests import BRANCH_LAT, BRANCH_LON, NEAR, image_file

BASE = "/api/v1/attendance/"
ADMIN = f"{BASE}admin/"
IN_PHOTO = "attendance/checkin/2026/10/18/in-photo.jpg"
OUT_PHOTO = "attendance/checkout/2026/10/18/out-photo.jpg"


def at(day, hour, minute):
    """Aware datetime in the project time zone (no manual offsets)."""
    return timezone.make_aware(dt.datetime.combine(day, dt.time(hour, minute)))


@override_settings(ROOT_URLCONF="config.urls")
class AdminAttendanceTestCase(TestCase):
    def setUp(self):
        self.today = timezone.localdate()
        self.yesterday = self.today - dt.timedelta(days=1)

        self.org = Organization.objects.create(name="Devi", code="DEVI")
        self.branch_a = Branch.objects.create(organization=self.org, name="Cuddalore", code="CDL",
                                              latitude=BRANCH_LAT, longitude=BRANCH_LON, attendance_radius_meters=100)
        self.branch_b = Branch.objects.create(organization=self.org, name="Chennai", code="CHN")
        self.other_org = Organization.objects.create(name="Other", code="OTH")
        self.other_branch = Branch.objects.create(organization=self.other_org, name="Mumbai", code="MUM")

        self.sales = Department.objects.create(name="Sales", branch=self.branch_a)
        self.support = Department.objects.create(name="Support", branch=self.branch_a)
        self.b_support = Department.objects.create(name="Support", branch=self.branch_b)
        self.other_dept = Department.objects.create(name="Sales", branch=self.other_branch)
        self.executive = Designation.objects.create(name="Executive", department=self.sales)
        self.agent = Designation.objects.create(name="Agent", department=self.support)
        self.other_desig = Designation.objects.create(name="Executive", department=self.other_dept)

        self.arun = self.employee("EMP001", "Arun", "Kumar", "9000000001", self.branch_a, self.sales, self.executive)
        self.divya = self.employee("EMP002", "Divya", "Raj", "9000000002", self.branch_a, self.sales, self.executive)
        self.karthik = self.employee("EMP003", "Karthik", "S", "9000000003", self.branch_a, self.support, self.agent)
        self.meena = self.employee("EMP004", "Meena", "P", "9000000004", self.branch_b, self.b_support, None)
        self.inactive = self.employee("EMP005", "Gone", "Away", "9000000005", self.branch_a, self.sales, self.executive,
                                      is_active=False)
        self.outsider = self.employee("EMP900", "Out", "Sider", "9000000900", self.other_branch, self.other_dept,
                                      self.other_desig)

        # Arun: completed day 09:12 -> 18:08 (8h 56m = 32160 s); Divya: checked in only; Outsider: present elsewhere
        self.arun_att = self.attendance(self.arun, self.today, (9, 12), (18, 8))
        self.divya_att = self.attendance(self.divya, self.today, (9, 40), None)
        self.attendance(self.outsider, self.today, (9, 0), (17, 0))

        self.superadmin = User.objects.create_user("9111000000", role=User.Role.SUPERADMIN, is_superuser=True)
        self.admin_all = self.admin("9111000001", [self.branch_a, self.branch_b])
        self.admin_a = self.admin("9111000002", [self.branch_a])
        self.admin_other = self.admin("9111000003", [self.other_branch], organization=self.other_org)
        self.admin_no_scope = User.objects.create_user("9111000004", role=User.Role.ADMIN, organization=self.org)
        self.admin_no_scope.groups.add(ensure_role_group(User.Role.ADMIN))

    # ---- builders ----
    def employee(self, code, first, last, phone, branch, department, designation, is_active=True, **extra):
        user = User.objects.create_user(phone, role=User.Role.EMPLOYEE, first_name=first, last_name=last, is_active=is_active)
        return Employee.objects.create(employee_code=code, user=user, branch=branch, department=department,
                                       designation=designation, is_active=is_active, **extra)

    def admin(self, phone, branches, organization=None, role=User.Role.ADMIN):
        user = User.objects.create_user(phone, role=role, organization=organization or self.org)
        user.allowed_branches.set(branches)
        user.groups.add(ensure_role_group(role))
        return user

    def attendance(self, employee, day, check_in, check_out, **extra):
        values = dict(
            employee=employee, branch=employee.branch, attendance_date=day, check_in_at=at(day, *check_in),
            check_in_latitude="11.7450000", check_in_longitude="79.7689000", check_in_accuracy=7.4,
            check_in_distance_meters=33.4, check_in_location_verified=True, check_in_photo=IN_PHOTO,
        )
        if check_out:
            values.update(
                check_out_at=at(day, *check_out), check_out_latitude="11.7451000", check_out_longitude="79.7690000",
                check_out_accuracy=5.0, check_out_distance_meters=12.5, check_out_location_verified=True,
                check_out_photo=OUT_PHOTO,
            )
        values.update(extra)
        return Attendance.objects.create(**values)

    # ---- request helpers ----
    def api(self, user):
        client = APIClient()
        client.force_authenticate(user)
        return client

    def get(self, path, user=None, **params):
        return self.api(user or self.admin_all).get(path, params)

    def rows(self, user=None, **params):
        response = self.get(ADMIN, user, **params)
        self.assertEqual(response.status_code, 200, response.content)
        return response.json()["data"]["results"]

    def codes(self, user=None, **params):
        return [row["employee"]["employee_code"] for row in self.rows(user, **params)]

    def by_code(self, user=None, **params):
        return {row["employee"]["employee_code"]: row for row in self.rows(user, **params)}

    def assertError(self, response, field, status=400):
        self.assertEqual(response.status_code, status, response.content)
        body = response.json()
        self.assertFalse(body["success"])
        if field:
            self.assertIn(field, body["errors"])


class ListTests(AdminAttendanceTestCase):
    def test_01_authorised_admin_can_list(self):
        response = self.get(ADMIN)
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertTrue(body["success"])
        data = body["data"]
        for key in ("count", "page", "page_size", "total_pages", "next", "previous", "results", "start_date", "end_date"):
            self.assertIn(key, data)
        self.assertEqual(data["count"], 4)
        self.assertEqual(data["start_date"], self.today.isoformat())

    def test_02_unauthorised_users_are_rejected(self):
        self.assertEqual(APIClient().get(ADMIN).status_code, 401)
        employee_user = self.arun.user
        for path in (ADMIN, f"{ADMIN}summary/", f"{ADMIN}export/", f"{ADMIN}{self.arun.pk}/"):
            self.assertEqual(self.api(employee_user).get(path).status_code, 403, path)
        # a MANAGER-style user without the permission is rejected too
        nobody = User.objects.create_user("9222000000", role=User.Role.MANAGER, organization=self.org)
        self.assertEqual(self.api(nobody).get(ADMIN).status_code, 403)

    def test_03_organization_and_branch_scoping(self):
        self.assertEqual(sorted(self.codes(self.admin_all)), ["EMP001", "EMP002", "EMP003", "EMP004"])
        self.assertEqual(sorted(self.codes(self.admin_a)), ["EMP001", "EMP002", "EMP003"])  # no Chennai
        self.assertEqual(self.codes(self.admin_other), ["EMP900"])  # no Devi data
        self.assertEqual(sorted(self.codes(self.superadmin)), ["EMP001", "EMP002", "EMP003", "EMP004", "EMP900"])
        self.assertEqual(self.codes(self.admin_no_scope), [])  # fail-closed: no scope assigned -> no data

    def test_customer_superadmin_attendance_is_limited_to_assigned_organization(self):
        owner = self.admin("9111000005", [], role=User.Role.SUPERADMIN)
        self.assertEqual(sorted(self.codes(owner)), ["EMP001", "EMP002", "EMP003", "EMP004"])
        self.assertEqual(self.api(owner).get(f"{ADMIN}{self.outsider.pk}/").status_code, 404)
        summary = self.api(owner).get(f"{ADMIN}summary/").json()["data"]
        self.assertEqual(summary["total_employees"], 4)

    def test_03b_scope_cannot_be_bypassed_with_ids(self):
        for params in ({"branch": self.other_branch.pk}, {"branch": self.branch_b.pk},  # admin_a lacks Chennai
                       {"department": self.other_dept.pk}, {"designation": self.other_desig.pk}):
            response = self.get(ADMIN, self.admin_a, **params)
            self.assertError(response, next(iter(params)))
        self.assertError(self.get(ADMIN, self.admin_a, branch=999999), "branch")  # same answer as out-of-scope

    def test_04_present_employee_is_present(self):
        row = self.by_code()["EMP001"]
        self.assertEqual(row["status"], "PRESENT")
        self.assertTrue(row["has_check_in"])
        self.assertTrue(row["has_check_out"])
        self.assertEqual(row["state"], "CHECKED_OUT")
        self.assertEqual(row["employee"]["name"], "Arun Kumar")
        self.assertEqual(row["branch"], {"id": self.branch_a.pk, "name": "Cuddalore"})
        self.assertEqual(row["department"], {"id": self.sales.pk, "name": "Sales"})
        self.assertEqual(row["designation"], {"id": self.executive.pk, "name": "Executive"})
        self.assertEqual(row["attendance_date"], self.today.isoformat())
        self.assertTrue(row["check_in_location_verified"])

    def test_05_employee_without_attendance_is_absent(self):
        row = self.by_code()["EMP003"]
        self.assertEqual(row["status"], "ABSENT")
        self.assertFalse(row["has_check_in"])
        self.assertFalse(row["has_check_out"])
        for key in ("check_in_at", "check_out_at", "working_seconds", "working_hours_display",
                    "check_in_location_verified", "check_out_location_verified"):
            self.assertIsNone(row[key], key)
        self.assertEqual(row["state"], "NOT_CHECKED_IN")
        self.assertIsNone(self.by_code()["EMP004"]["designation"])  # missing relations are null, not errors
        # derived only: listing never creates attendance rows
        self.assertFalse(Attendance.objects.filter(employee=self.karthik).exists())

    def test_inactive_employee_is_not_in_the_population_but_history_is_kept(self):
        self.assertNotIn("EMP005", self.codes())
        self.attendance(self.inactive, self.yesterday, (9, 0), (17, 0))  # worked yesterday, deactivated later
        self.assertEqual(self.by_code(date=self.yesterday.isoformat())["EMP005"]["status"], "PRESENT")
        self.assertNotIn("EMP005", self.codes())  # today: inactive and no attendance -> not listed

    def test_not_yet_joined_employee_is_not_marked_absent(self):
        Employee.objects.filter(pk=self.karthik.pk).update(joining_date=self.today + dt.timedelta(days=5))
        self.assertNotIn("EMP003", self.codes())
        Employee.objects.filter(pk=self.karthik.pk).update(joining_date=self.today)
        self.assertIn("EMP003", self.codes())

    def test_09_10_search_by_name_and_code(self):
        self.assertEqual(self.codes(search="Arun"), ["EMP001"])
        self.assertEqual(self.codes(search="arun kumar"), ["EMP001"])  # case-insensitive, multi-term
        self.assertEqual(self.codes(search="EMP003"), ["EMP003"])
        self.assertEqual(self.codes(search="emp00"), ["EMP001", "EMP002", "EMP003", "EMP004"])
        self.assertEqual(self.codes(search="nobody-matches"), [])
        self.assertEqual(self.codes(search="9000000001"), [])  # phone numbers are not searchable

    def test_11_branch_filter(self):
        self.assertEqual(self.codes(branch=self.branch_b.pk), ["EMP004"])

    def test_12_department_filter(self):
        self.assertEqual(sorted(self.codes(department=self.sales.pk)), ["EMP001", "EMP002"])
        self.assertEqual(self.codes(department=self.support.pk), ["EMP003"])

    def test_13_designation_filter(self):
        self.assertEqual(sorted(self.codes(designation=self.executive.pk)), ["EMP001", "EMP002"])
        self.assertEqual(self.codes(designation=self.agent.pk), ["EMP003"])

    def test_14_present_status_filter(self):
        self.assertEqual(sorted(self.codes(status="present")), ["EMP001", "EMP002"])
        self.assertEqual(sorted(self.codes(status="PRESENT")), ["EMP001", "EMP002"])  # case-insensitive

    def test_15_absent_status_filter(self):
        self.assertEqual(sorted(self.codes(status="absent")), ["EMP003", "EMP004"])

    def test_unsupported_statuses_are_rejected(self):
        for status in ("late", "early", "overtime", "checked_in", "xyz"):
            self.assertError(self.get(ADMIN, status=status), "status")

    def test_filters_combine(self):
        self.assertEqual(self.codes(branch=self.branch_a.pk, department=self.sales.pk,
                                    designation=self.executive.pk, status="present", search="divya"), ["EMP002"])
        self.assertEqual(self.codes(branch=self.branch_a.pk, status="absent", search="karthik"), ["EMP003"])
        self.assertEqual(self.codes(branch=self.branch_b.pk, department=self.sales.pk), [])

    def test_16_date_filter(self):
        self.attendance(self.karthik, self.yesterday, (10, 0), (19, 0))
        yesterday = self.by_code(date=self.yesterday.isoformat())
        self.assertEqual(yesterday["EMP003"]["status"], "PRESENT")
        self.assertEqual(yesterday["EMP001"]["status"], "ABSENT")  # Arun only worked today
        self.assertEqual(yesterday["EMP003"]["attendance_date"], self.yesterday.isoformat())
        today = self.by_code()
        self.assertEqual(today["EMP003"]["status"], "ABSENT")
        self.assertEqual(today["EMP001"]["status"], "PRESENT")

    def test_17_date_validation(self):
        d = self.today.isoformat()
        tomorrow = (self.today + dt.timedelta(days=1)).isoformat()
        for params, field in (
            ({"date": "18-10-2026"}, "date"), ({"date": "banana"}, "date"),
            ({"start_date": "2026-13-45", "end_date": d}, "start_date"),
            ({"start_date": d, "end_date": (self.yesterday).isoformat()}, "end_date"),  # start after end
            ({"start_date": d}, "end_date"), ({"end_date": d}, "start_date"),           # must come together
            ({"date": d, "start_date": d, "end_date": d}, "date"),                       # not both styles
            ({"date": tomorrow}, "date"),
            ({"start_date": d, "end_date": tomorrow}, "end_date"),
            ({"start_date": (self.today - dt.timedelta(days=200)).isoformat(), "end_date": d}, "end_date"),
        ):
            self.assertError(self.get(ADMIN, **params), field)
        # valid custom range
        self.assertEqual(self.get(ADMIN, start_date=self.yesterday.isoformat(), end_date=d).status_code, 200)

    def test_range_returns_one_row_per_employee_per_day(self):
        self.attendance(self.arun, self.yesterday, (9, 0), (17, 0))
        data = self.get(ADMIN, start_date=self.yesterday.isoformat(), end_date=self.today.isoformat()).json()["data"]
        self.assertEqual(data["count"], 8)  # 4 employees x 2 days
        by_key = {(r["attendance_date"], r["employee"]["employee_code"]): r["status"] for r in data["results"]}
        self.assertEqual(len(by_key), 8)  # no duplicate (date, employee)
        self.assertEqual(by_key[(self.yesterday.isoformat(), "EMP001")], "PRESENT")
        self.assertEqual(by_key[(self.today.isoformat(), "EMP001")], "PRESENT")
        self.assertEqual(by_key[(self.yesterday.isoformat(), "EMP002")], "ABSENT")
        self.assertEqual(by_key[(self.today.isoformat(), "EMP002")], "PRESENT")  # Divya, checked in today
        dates = [r["attendance_date"] for r in data["results"]]
        self.assertEqual(dates, sorted(dates, reverse=True))  # newest date first by default

    def test_18_pagination(self):
        first = self.get(ADMIN, page_size=3).json()["data"]
        self.assertEqual((first["count"], first["page"], first["page_size"], first["total_pages"]), (4, 1, 3, 2))
        self.assertEqual(len(first["results"]), 3)
        self.assertIsNone(first["previous"])
        self.assertIn("page=2", first["next"])
        second = self.get(ADMIN, page_size=3, page=2).json()["data"]
        self.assertEqual(len(second["results"]), 1)
        self.assertIsNone(second["next"])
        self.assertIsNotNone(second["previous"])
        seen = [r["employee"]["employee_code"] for r in first["results"] + second["results"]]
        self.assertEqual(len(set(seen)), 4)  # pages do not overlap
        self.assertEqual(self.get(ADMIN, page_size=3, page=3).status_code, 404)

    def test_pagination_across_days_has_no_gaps_or_overlaps(self):
        params = dict(start_date=(self.today - dt.timedelta(days=2)).isoformat(), end_date=self.today.isoformat())
        everything = self.rows(page_size=100, **params)
        paged = []
        for page in (1, 2, 3, 4):
            paged += self.rows(page_size=3, page=page, **params)
        key = lambda r: (r["attendance_date"], r["employee"]["employee_code"])
        self.assertEqual([key(r) for r in paged], [key(r) for r in everything])
        self.assertEqual(len(everything), 12)

    def test_invalid_pagination_params(self):
        for params in ({"page": "abc"}, {"page": 0}, {"page_size": 0}, {"page_size": 101}, {"page_size": "x"}):
            self.assertEqual(self.get(ADMIN, **params).status_code, 400, params)

    def test_ordering(self):
        self.assertEqual(self.codes(ordering="employee_name"), ["EMP001", "EMP002", "EMP003", "EMP004"])
        self.assertEqual(self.codes(ordering="-employee_name"), ["EMP004", "EMP003", "EMP002", "EMP001"])
        # check_in ascending: Arun 09:12, Divya 09:40, then the absent (null) rows last
        self.assertEqual(self.codes(ordering="check_in")[:2], ["EMP001", "EMP002"])
        self.assertEqual(self.codes(ordering="-check_in")[:2], ["EMP002", "EMP001"])
        self.assertEqual(self.codes(ordering="check_out")[0], "EMP001")  # only Arun has a check-out; nulls last
        self.assertEqual(self.get(ADMIN, ordering="password").status_code, 400)
        self.assertEqual(self.get(ADMIN, ordering="late").status_code, 400)

    def test_oldest_first_ordering_for_ranges(self):
        params = dict(start_date=self.yesterday.isoformat(), end_date=self.today.isoformat())
        dates = [r["attendance_date"] for r in self.rows(ordering="attendance_date", **params)]
        self.assertEqual(dates, sorted(dates))

    def test_list_query_count_does_not_grow_with_employees(self):
        from django.db import connection
        from django.test.utils import CaptureQueriesContext

        def queries():
            with CaptureQueriesContext(connection) as captured:
                response = self.get(ADMIN, page_size=100)
            return len(captured), response.json()["data"]["count"]

        queries()  # warm-up: the first request caches the user's permissions on the user object
        before, count_before = queries()
        for index in range(20):  # present + absent employees, all with attendance data to serialise
            employee = self.employee(f"BULK{index:02d}", "Bulk", str(index), f"93000000{index:02d}",
                                     self.branch_a, self.sales, self.executive)
            if index % 2:
                self.attendance(employee, self.today, (9, 0), (17, 0))
        after, count_after = queries()
        self.assertEqual((count_before, count_after), (4, 24))
        self.assertEqual(before, after)  # constant number of queries: no N+1

    def test_response_never_exposes_phone_numbers_or_other_sensitive_fields(self):
        body = self.get(ADMIN).content.decode()
        self.assertNotIn("9000000001", body)
        self.assertNotIn("monthly_salary", body)
        self.assertNotIn("bank", body)


class SummaryTests(AdminAttendanceTestCase):
    SUMMARY = f"{ADMIN}summary/"

    def summary(self, user=None, **params):
        response = self.get(self.SUMMARY, user, **params)
        self.assertEqual(response.status_code, 200, response.content)
        return response.json()["data"]

    def test_06_07_08_total_present_absent(self):
        data = self.summary()
        self.assertEqual((data["total_employees"], data["present"], data["absent"]), (4, 2, 2))
        self.assertEqual(data["date"], self.today.isoformat())
        self.assertEqual(set(data), {"date", "start_date", "end_date", "total_employees", "present", "absent"})
        # no placeholder values for metrics that are not implemented
        for unsupported in ("late", "early", "overtime", "late_arrivals"):
            self.assertNotIn(unsupported, data)

    def test_summary_is_scoped(self):
        data = self.summary(self.admin_a)
        self.assertEqual((data["total_employees"], data["present"], data["absent"]), (3, 2, 1))
        data = self.summary(self.admin_other)
        self.assertEqual((data["total_employees"], data["present"], data["absent"]), (1, 1, 0))
        data = self.summary(self.admin_no_scope)
        self.assertEqual((data["total_employees"], data["present"], data["absent"]), (0, 0, 0))

    def test_summary_matches_the_list(self):
        for params in ({}, {"branch": self.branch_a.pk}, {"department": self.sales.pk}, {"search": "e"}):
            rows = self.rows(page_size=100, **params)
            data = self.summary(**params)
            self.assertEqual(data["total_employees"], len(rows), params)
            self.assertEqual(data["present"], sum(r["status"] == "PRESENT" for r in rows), params)
            self.assertEqual(data["absent"], sum(r["status"] == "ABSENT" for r in rows), params)

    def test_summary_for_a_past_date_and_filters(self):
        self.attendance(self.karthik, self.yesterday, (10, 0), None)
        data = self.summary(date=self.yesterday.isoformat())
        self.assertEqual((data["total_employees"], data["present"], data["absent"]), (4, 1, 3))
        data = self.summary(branch=self.branch_b.pk)
        self.assertEqual((data["total_employees"], data["present"], data["absent"]), (1, 0, 1))

    def test_summary_counts_are_not_inflated_by_multi_day_ranges(self):
        self.attendance(self.arun, self.yesterday, (9, 0), (17, 0))  # Arun present on 2 days
        data = self.summary(start_date=self.yesterday.isoformat(), end_date=self.today.isoformat())
        self.assertEqual((data["total_employees"], data["present"], data["absent"]), (4, 2, 2))  # employees, not days
        self.assertIsNone(data["date"])
        self.assertEqual(data["start_date"], self.yesterday.isoformat())

    def test_summary_validates_inputs(self):
        self.assertError(self.get(self.SUMMARY, date="nope"), "date")
        self.assertError(self.get(self.SUMMARY, self.admin_a, branch=self.other_branch.pk), "branch")


class DetailTests(AdminAttendanceTestCase):
    def detail(self, employee, user=None, **params):
        return self.get(f"{ADMIN}{employee.pk}/", user, **params)

    def test_19_20_21_check_in_check_out_and_gps_fields(self):
        data = self.detail(self.arun).json()["data"]
        self.assertEqual(data["status"], "PRESENT")
        self.assertEqual(data["employee"]["employee_code"], "EMP001")
        self.assertEqual(data["employee"]["branch"]["name"], "Cuddalore")
        self.assertEqual(data["employee"]["department"]["name"], "Sales")
        self.assertEqual(data["employee"]["designation"]["name"], "Executive")
        self.assertEqual(data["attendance_branch"]["name"], "Cuddalore")
        self.assertAlmostEqual(data["attendance_branch"]["latitude"], float(BRANCH_LAT), places=6)
        self.assertAlmostEqual(data["attendance_branch"]["longitude"], float(BRANCH_LON), places=6)
        self.assertEqual(data["attendance_date"], self.today.isoformat())
        check_in, check_out = data["check_in"], data["check_out"]
        self.assertEqual(check_in["latitude"], 11.745)
        self.assertEqual(check_in["longitude"], 79.7689)
        self.assertEqual(check_in["accuracy_m"], 7.4)
        self.assertEqual(check_in["distance_from_branch_m"], 33.4)
        self.assertTrue(check_in["location_verified"])
        self.assertEqual(check_out["latitude"], 11.7451)
        self.assertEqual(check_out["longitude"], 79.769)
        self.assertEqual(check_out["accuracy_m"], 5.0)
        self.assertEqual(check_out["distance_from_branch_m"], 12.5)
        self.assertTrue(check_out["location_verified"])
        # the exact stored instants, round-tripped, expressed in the project time zone (like the mobile API)
        self.assertEqual(dt.datetime.fromisoformat(check_in["time"]), self.arun_att.check_in_at)
        self.assertEqual(dt.datetime.fromisoformat(check_out["time"]), self.arun_att.check_out_at)
        self.assertTrue(check_in["time"].endswith("+05:30"), check_in["time"])
        self.assertTrue(self.by_code()["EMP001"]["check_in_at"].endswith("+05:30"))

    def test_22_photo_urls(self):
        data = self.detail(self.arun).json()["data"]
        self.assertEqual(data["check_in"]["photo"], f"http://testserver/media/{IN_PHOTO}")
        self.assertEqual(data["check_out"]["photo"], f"http://testserver/media/{OUT_PHOTO}")
        # the database still holds only the relative path
        self.arun_att.refresh_from_db()
        self.assertEqual(self.arun_att.check_in_photo.name, IN_PHOTO)
        # URL follows the request host (no hard-coded domain)
        with override_settings(ALLOWED_HOSTS=["hr.example.com"]):
            response = self.api(self.admin_all).get(f"{ADMIN}{self.arun.pk}/", HTTP_HOST="hr.example.com")
        self.assertTrue(response.json()["data"]["check_in"]["photo"].startswith("http://hr.example.com/media/"))
        # no profile photo -> null
        self.assertIsNone(data["employee"]["profile_photo"])

    def test_23_absent_employee_detail(self):
        data = self.detail(self.karthik).json()["data"]
        self.assertEqual(data["status"], "ABSENT")
        self.assertEqual(data["state"], "NOT_CHECKED_IN")
        self.assertIsNone(data["check_in"])
        self.assertIsNone(data["check_out"])
        self.assertIsNone(data["working_seconds"])
        self.assertIsNone(data["working_hours_display"])
        self.assertIsNone(data["attendance_branch"])
        self.assertEqual(data["employee"]["employee_code"], "EMP003")
        self.assertEqual(data["employee"]["name"], "Karthik S")

    def test_24_working_hours(self):
        data = self.detail(self.arun).json()["data"]
        self.assertEqual(data["working_seconds"], 32160)
        self.assertEqual(data["working_hours_display"], "8h 56m")
        row = self.by_code()["EMP001"]
        self.assertEqual((row["working_seconds"], row["working_hours_display"]), (32160, "8h 56m"))

    def test_working_hours_unit(self):
        self.assertEqual(admin_services.format_duration(0), "0h 0m")
        self.assertEqual(admin_services.format_duration(59), "0h 0m")
        self.assertEqual(admin_services.format_duration(3600 + 5 * 60 + 59), "1h 5m")
        self.assertIsNone(admin_services.format_duration(None))
        self.assertIsNone(admin_services.working_seconds(None))
        inverted = Attendance(check_in_at=at(self.today, 18, 0), check_out_at=at(self.today, 9, 0))
        self.assertIsNone(admin_services.working_seconds(inverted))  # inconsistent data is never shown as negative

    def test_25_checked_in_but_not_checked_out(self):
        data = self.detail(self.divya).json()["data"]
        self.assertEqual(data["status"], "PRESENT")
        self.assertEqual(data["state"], "CHECKED_IN")
        self.assertIsNotNone(data["check_in"])
        self.assertIsNone(data["check_out"])
        self.assertIsNone(data["working_seconds"])  # no live duration is passed off as a final one
        self.assertIsNone(data["working_hours_display"])
        row = self.by_code()["EMP002"]
        self.assertTrue(row["has_check_in"])
        self.assertFalse(row["has_check_out"])
        self.assertIsNone(row["working_seconds"])
        self.assertIsNone(row["check_out_at"])
        self.assertEqual(Attendance.objects.get(pk=self.divya_att.pk).check_out_at, None)  # nothing was stored

    def test_detail_date_param(self):
        self.attendance(self.karthik, self.yesterday, (10, 0), (19, 0))
        self.assertEqual(self.detail(self.karthik, date=self.yesterday.isoformat()).json()["data"]["status"], "PRESENT")
        self.assertEqual(self.detail(self.karthik).json()["data"]["status"], "ABSENT")
        self.assertError(self.detail(self.karthik, date="bad"), "date")
        self.assertError(self.detail(self.karthik, date=(self.today + dt.timedelta(days=1)).isoformat()), "date")

    def test_detail_respects_scope(self):
        self.assertEqual(self.detail(self.meena, self.admin_a).status_code, 404)    # branch outside admin_a's scope
        self.assertEqual(self.detail(self.arun, self.admin_other).status_code, 404)  # another organization
        self.assertEqual(self.detail(self.outsider, self.admin_all).status_code, 404)
        self.assertEqual(self.detail(self.arun, self.admin_no_scope).status_code, 404)
        self.assertEqual(self.detail(self.outsider, self.superadmin).status_code, 200)
        self.assertEqual(self.api(self.admin_all).get(f"{ADMIN}999999/").status_code, 404)

    def test_detail_for_employee_outside_the_population_is_404(self):
        self.assertEqual(self.detail(self.inactive).status_code, 404)  # inactive and no attendance that day


class ExportTests(AdminAttendanceTestCase):
    EXPORT = f"{ADMIN}export/"

    def export(self, user=None, **params):
        response = self.get(self.EXPORT, user, **params)
        self.assertEqual(response.status_code, 200, getattr(response, "content", b""))
        text = b"".join(response.streaming_content).decode("utf-8")
        return response, list(csv.reader(io.StringIO(text.lstrip("\ufeff"))))

    def test_26_csv_export(self):
        response, rows = self.export()
        self.assertTrue(response["Content-Type"].startswith("text/csv"))
        day = self.today.isoformat()
        self.assertEqual(response["Content-Disposition"], f'attachment; filename="attendance-report-{day}-to-{day}.csv"')
        header, body = rows[0], rows[1:]
        self.assertEqual(header[:10], ["Date", "Employee ID", "Employee Name", "Branch", "Department", "Designation",
                                       "Status", "Check In", "Check Out", "Working Hours"])
        for column in ("Check-in Latitude", "Check-in Accuracy (m)", "Check-in Distance (m)", "Check-in Verified",
                       "Check-in Photo", "Check-out Longitude", "Check-out Photo"):
            self.assertIn(column, header)
        for fake in ("Late", "Early", "Overtime"):
            self.assertFalse([h for h in header if fake.lower() in h.lower()])
        self.assertEqual(len(body), 4)
        cells = {row[1]: dict(zip(header, row)) for row in body}
        arun = cells["EMP001"]
        self.assertEqual((arun["Employee Name"], arun["Branch"], arun["Department"], arun["Designation"], arun["Status"]),
                         ("Arun Kumar", "Cuddalore", "Sales", "Executive", "PRESENT"))
        self.assertEqual(arun["Check In"], f"{day} 09:12:00")
        self.assertEqual(arun["Check Out"], f"{day} 18:08:00")
        self.assertEqual(arun["Working Hours"], "8h 56m")
        self.assertEqual(arun["Check-in Verified"], "Yes")
        self.assertEqual(arun["Check-in Latitude"], "11.7450000")
        self.assertEqual(arun["Check-in Photo"], f"http://testserver/media/{IN_PHOTO}")
        self.assertEqual(arun["Check-out Photo"], f"http://testserver/media/{OUT_PHOTO}")
        divya = cells["EMP002"]
        self.assertEqual((divya["Check Out"], divya["Working Hours"], divya["Check-out Photo"]), ("", "", ""))
        absent = cells["EMP003"]
        self.assertEqual(absent["Status"], "ABSENT")
        self.assertEqual([absent[c] for c in header[7:]], [""] * len(header[7:]))

    def test_customer_superadmin_export_is_limited_to_assigned_organization(self):
        owner = self.admin("9111000005", [], role=User.Role.SUPERADMIN)
        response, rows = self.export(owner)
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("EMP900", [row[1] for row in rows[1:]])

    def test_27_export_respects_filters_and_dates(self):
        _, rows = self.export(status="absent")
        self.assertEqual(sorted(r[1] for r in rows[1:]), ["EMP003", "EMP004"])
        _, rows = self.export(department=self.sales.pk, status="present")
        self.assertEqual(sorted(r[1] for r in rows[1:]), ["EMP001", "EMP002"])
        _, rows = self.export(search="meena")
        self.assertEqual([r[1] for r in rows[1:]], ["EMP004"])
        _, rows = self.export(branch=self.branch_a.pk, designation=self.agent.pk)
        self.assertEqual([r[1] for r in rows[1:]], ["EMP003"])
        start, end = self.yesterday.isoformat(), self.today.isoformat()
        response, rows = self.export(start_date=start, end_date=end)
        self.assertEqual(response["Content-Disposition"], f'attachment; filename="attendance-report-{start}-to-{end}.csv"')
        self.assertEqual(len(rows) - 1, 8)
        self.assertEqual([r[0] for r in rows[1:]], sorted(r[0] for r in rows[1:]))  # oldest first by default

    def test_28_export_respects_scope(self):
        _, rows = self.export(self.admin_a)
        self.assertEqual(sorted(r[1] for r in rows[1:]), ["EMP001", "EMP002", "EMP003"])
        _, rows = self.export(self.admin_other)
        self.assertEqual([r[1] for r in rows[1:]], ["EMP900"])
        _, rows = self.export(self.admin_no_scope)
        self.assertEqual(len(rows), 1)  # header only
        self.assertError(self.get(self.EXPORT, self.admin_a, branch=self.other_branch.pk), "branch")
        self.assertEqual(self.get(self.EXPORT, self.arun.user).status_code, 403)
        self.assertEqual(APIClient().get(self.EXPORT).status_code, 401)

    def test_export_validates_inputs(self):
        self.assertError(self.get(self.EXPORT, status="late"), "status")
        self.assertError(self.get(self.EXPORT, start_date="2026-01-01"), "end_date")

    def test_csv_formula_injection_is_neutralised(self):
        Employee.objects.filter(pk=self.karthik.pk).update(employee_code="=CMD()")
        User.objects.filter(pk=self.karthik.user.pk).update(first_name="@evil", last_name="")
        _, rows = self.export(search="evil")
        self.assertEqual(rows[1][1], "'=CMD()")
        self.assertEqual(rows[1][2], "'@evil")


class IntegrationWithMobileFlowTests(AdminAttendanceTestCase):
    """A REAL mobile check-in / check-out (the existing endpoints) must show up in the admin APIs immediately."""

    def setUp(self):
        super().setUp()
        media = tempfile.mkdtemp(prefix="lyra_admin_test_media_")
        override = override_settings(MEDIA_ROOT=media)
        override.enable()
        self.addCleanup(override.disable)
        self.addCleanup(shutil.rmtree, media, ignore_errors=True)

    def mobile_post(self, employee, action):
        data = dict(NEAR, photo=image_file())
        return self.api(employee.user).post(f"{BASE}{action}/", data, format="multipart")

    def test_30_mobile_check_in_and_out_are_visible_to_admin_and_unchanged(self):
        Employee.objects.filter(pk=self.karthik.pk).update(
            mobile_gps_attendance_enabled=True,
            photo_attendance_enabled=True,
            location_attendance_enabled=True,
        )
        self.assertEqual(self.by_code()["EMP003"]["status"], "ABSENT")
        response = self.mobile_post(self.karthik, "check-in")
        self.assertEqual(response.status_code, 201, response.content)
        self.assertEqual(set(response.json()["data"]["attendance"]),
                         {"id", "attendance_date", "check_in_at", "location_verified", "distance_meters"})  # contract intact

        row = self.by_code()["EMP003"]
        self.assertEqual(row["status"], "PRESENT")
        self.assertEqual(row["state"], "CHECKED_IN")
        self.assertIsNone(row["working_seconds"])
        data = self.get(f"{ADMIN}{self.karthik.pk}/").json()["data"]
        self.assertTrue(data["check_in"]["location_verified"])
        self.assertAlmostEqual(data["check_in"]["latitude"], NEAR["latitude"], places=6)
        self.assertEqual(data["check_in"]["accuracy_m"], NEAR["accuracy"])
        self.assertRegex(data["check_in"]["photo"], r"^http://testserver/media/attendance/checkin/\d{4}/\d{2}/\d{2}/[0-9a-f-]+\.jpg$")
        self.assertEqual(self.get(f"{ADMIN}summary/").json()["data"]["present"], 3)

        response = self.mobile_post(self.karthik, "check-out")
        self.assertEqual(response.status_code, 200, response.content)
        data = self.get(f"{ADMIN}{self.karthik.pk}/").json()["data"]
        self.assertEqual(data["state"], "CHECKED_OUT")
        self.assertRegex(data["check_out"]["photo"], r"/media/attendance/checkout/")
        self.assertIsNotNone(data["working_seconds"])
        self.assertEqual(Attendance.objects.filter(employee=self.karthik).count(), 1)  # same row, never duplicated
        # the mobile "today" endpoint is untouched
        today = self.api(self.karthik.user).get(f"{BASE}today/")
        self.assertEqual(today.json()["data"]["state"], "CHECKED_OUT")

    def test_mobile_routes_and_names_are_unchanged(self):
        from django.urls import resolve, reverse
        for name, path in (("attendance-verify-location", "verify-location/"), ("attendance-check-in", "check-in/"),
                           ("attendance-check-out", "check-out/"), ("attendance-today", "today/")):
            self.assertEqual(reverse(name), f"/api/v1/attendance/{path}")
        self.assertEqual(resolve("/api/v1/attendance/today/").url_name, "attendance-today")
        self.assertEqual(resolve("/api/v1/attendance/admin/").url_name, "attendance-admin-list")
        self.assertEqual(resolve("/api/v1/attendance/admin/summary/").url_name, "attendance-admin-summary")
        self.assertEqual(resolve("/api/v1/attendance/admin/export/").url_name, "attendance-admin-export")
        self.assertEqual(resolve("/api/v1/attendance/admin/12/").url_name, "attendance-admin-detail")

    def test_admin_apis_are_read_only(self):
        for path in (ADMIN, f"{ADMIN}summary/", f"{ADMIN}export/", f"{ADMIN}{self.arun.pk}/"):
            client = self.api(self.superadmin)
            for method in (client.post, client.put, client.patch, client.delete):
                self.assertEqual(method(path).status_code, 405, (method, path))
