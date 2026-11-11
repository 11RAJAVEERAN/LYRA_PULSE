import datetime as dt
from io import BytesIO

from django.utils import timezone
from openpyxl import load_workbook

from apps.shifts.models import AssignmentWeekOff, Shift, ShiftAssignment

from .models import AttendanceAdjustment, AttendanceAdjustmentAudit
from .test_admin_api import AdminAttendanceTestCase


GRID = "/api/v1/attendance/admin/bulk-adjustments/"
SAVE = f"{GRID}save/"
EXPORT = f"{GRID}export/"


class BulkAttendanceAdjustmentApiTests(AdminAttendanceTestCase):
    def test_grid_is_scoped_and_maps_existing_attendance(self):
        response = self.get(GRID, self.admin_a, start_date=self.yesterday, end_date=self.today, page=1, page_size=50)
        self.assertEqual(response.status_code, 200, response.content)
        data = response.json()["data"]
        self.assertEqual(data["count"], 3)
        self.assertEqual([item["date"] for item in data["dates"]], [self.yesterday.isoformat(), self.today.isoformat()])
        rows = {item["employee_code"]: item for item in data["results"]}
        self.assertEqual(rows["EMP001"]["cells"][1]["code"], "FD")
        self.assertEqual(rows["EMP003"]["cells"][1]["code"], "A")
        self.assertNotIn("EMP004", rows)

    def test_grid_uses_effective_assignment_week_off(self):
        shift = Shift.objects.create(branch=self.branch_a, name="Test shift")
        assignment = ShiftAssignment.objects.create(employee=self.karthik, shift=shift, effective_from=self.today)
        AssignmentWeekOff.objects.create(assignment=assignment, weekday=self.today.strftime("%A").upper())
        response = self.get(GRID, self.admin_a, start_date=self.today, end_date=self.today)
        rows = {item["employee_code"]: item for item in response.json()["data"]["results"]}
        self.assertEqual(rows["EMP003"]["cells"][0]["code"], "WO")

    def test_bulk_save_persists_changes_and_audit_without_mutating_punches(self):
        before = self.arun_att.check_in_at
        response = self.api(self.admin_all).post(SAVE, {"changes": [
            {"employee_id": self.arun.pk, "attendance_date": self.today.isoformat(), "code": "HD", "reason": "Approved correction"},
            {"employee_id": self.karthik.pk, "attendance_date": self.today.isoformat(), "code": "WO"},
        ]}, format="json")
        self.assertEqual(response.status_code, 200, response.content)
        self.assertEqual(response.json()["data"]["saved"], 2)
        adjustment = AttendanceAdjustment.objects.get(employee=self.arun, attendance_date=self.today)
        self.assertEqual(adjustment.code, "HD")
        audit = AttendanceAdjustmentAudit.objects.get(adjustment=adjustment)
        self.assertEqual(audit.previous_code, "FD")
        self.assertEqual(audit.new_code, "HD")
        self.assertEqual(audit.actor, self.admin_all)
        self.arun_att.refresh_from_db()
        self.assertEqual(self.arun_att.check_in_at, before)

    def test_batch_is_atomic_and_rejects_out_of_scope_employee(self):
        response = self.api(self.admin_a).post(SAVE, {"changes": [
            {"employee_id": self.arun.pk, "attendance_date": self.today.isoformat(), "code": "HD"},
            {"employee_id": self.meena.pk, "attendance_date": self.today.isoformat(), "code": "WO"},
        ]}, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(AttendanceAdjustment.objects.exists())
        self.assertFalse(AttendanceAdjustmentAudit.objects.exists())

    def test_rejects_duplicate_and_invalid_status(self):
        duplicate = {"employee_id": self.arun.pk, "attendance_date": self.today.isoformat(), "code": "HD"}
        response = self.api(self.admin_all).post(SAVE, {"changes": [duplicate, duplicate]}, format="json")
        self.assertEqual(response.status_code, 400)
        invalid = self.api(self.admin_all).post(SAVE, {"changes": [{**duplicate, "code": "LATE"}]}, format="json")
        self.assertEqual(invalid.status_code, 400)

    def test_grid_rejects_future_dates_and_requires_view_permission(self):
        future = timezone.localdate() + dt.timedelta(days=1)
        response = self.get(GRID, self.admin_all, start_date=future, end_date=future)
        self.assertEqual(response.status_code, 400)
        self.assertEqual(self.api(self.arun.user).get(GRID, {"start_date": self.today, "end_date": self.today}).status_code, 403)

    def test_export_returns_xlsx_for_scoped_filtered_population(self):
        response = self.get(EXPORT, self.admin_a, start_date=self.today, end_date=self.today)
        self.assertEqual(response.status_code, 200)
        self.assertIn("spreadsheetml.sheet", response["Content-Type"])
        workbook = load_workbook(BytesIO(response.content), read_only=True)
        sheet = workbook["Attendance Adjustments"]
        rows = list(sheet.values)
        self.assertEqual(rows[0][0:4], ("Employee ID", "Employee Name", "Department", "Designation"))
        self.assertEqual(len(rows), 4)  # three in-scope employees and one heading
        self.assertEqual(rows[1][4], "FD")
