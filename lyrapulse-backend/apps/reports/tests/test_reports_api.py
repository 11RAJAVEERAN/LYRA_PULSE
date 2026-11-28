import importlib.util
import unittest
from io import BytesIO

from openpyxl import load_workbook

from apps.attendance.test_admin_api import AdminAttendanceTestCase


BASE = "/api/v1/reports/"


class ReportsApiTests(AdminAttendanceTestCase):
    def test_all_report_endpoints_return_scoped_real_data_envelopes(self):
        for report in (
            "attendance-master", "daily-punch", "shift-wise", "working-hours",
            "muster", "branch-wise-punch", "leave-taken",
        ):
            response = self.get(f"{BASE}{report}/", start_date=self.today, end_date=self.today)
            self.assertEqual(response.status_code, 200, (report, response.content))
            body = response.json()["data"]
            for key in ("count", "page", "page_size", "total_pages", "dates", "results"):
                self.assertIn(key, body, report)
        self.assertFalse(self.get(f"{BASE}leave-taken/", start_date=self.today, end_date=self.today).json()["data"]["source_available"])

    def test_attendance_master_reuses_existing_punch_and_working_time_rules(self):
        response = self.get(f"{BASE}attendance-master/", start_date=self.today, end_date=self.today, branch=self.branch_a.pk)
        self.assertEqual(response.status_code, 200, response.content)
        data = response.json()["data"]
        self.assertEqual(data["count"], 3)
        arun = next(row for row in data["results"] if row["employee"]["employee_code"] == "EMP001")
        self.assertEqual(arun["working_seconds"], 8 * 3600 + 56 * 60)
        self.assertEqual(arun["first_punch_at"], self.arun_att.check_in_at.isoformat())
        self.assertIsNone(arun["break_hours_display"])

    def test_employee_date_matrix_uses_actual_attendance(self):
        response = self.get(f"{BASE}daily-punch/", start_date=self.today, end_date=self.today)
        self.assertEqual(response.status_code, 200, response.content)
        rows = response.json()["data"]["results"]
        arun = next(row for row in rows if row["employee_code"] == "EMP001")
        self.assertEqual(arun["values"], ["09:12 AM"])

    def test_xlsx_export_contains_all_filtered_rows(self):
        response = self.get(f"{BASE}attendance-master/export/", start_date=self.today,
                            end_date=self.today, branch=self.branch_a.pk, export_format="xlsx")
        self.assertEqual(response.status_code, 200, response.content)
        workbook = load_workbook(BytesIO(response.content), read_only=True)
        rows = list(workbook.active.values)
        self.assertEqual(rows[0][0:5], ("Employee", "Employee ID", "Role", "Department", "Date"))
        self.assertEqual(len(rows), 4)

    @unittest.skipUnless(importlib.util.find_spec("reportlab"), "reportlab is installed from backend requirements")
    def test_pdf_export_is_a_real_pdf_attachment(self):
        response = self.get(f"{BASE}attendance-master/export/", start_date=self.today,
                            end_date=self.today, export_format="pdf")
        self.assertEqual(response.status_code, 200, response.content[:200])
        self.assertEqual(response["Content-Type"], "application/pdf")
        self.assertTrue(response.content.startswith(b"%PDF"))
