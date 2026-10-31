from datetime import timedelta

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.employees.models import Employee
from apps.shifts.models import Shift, ShiftAssignment, ShiftDaySchedule, Weekday


def week_payload(start="09:00", end="17:00"):
    return [
        {"weekday": weekday, "is_working": weekday not in (Weekday.SUNDAY, Weekday.SATURDAY),
         "start_time": start if weekday not in (Weekday.SUNDAY, Weekday.SATURDAY) else None,
         "end_time": end if weekday not in (Weekday.SUNDAY, Weekday.SATURDAY) else None,
         "break_start_time": "13:00" if weekday not in (Weekday.SUNDAY, Weekday.SATURDAY) else None,
         "break_end_time": "13:30" if weekday not in (Weekday.SUNDAY, Weekday.SATURDAY) else None}
        for weekday in Weekday.values
    ]


class ShiftManagementTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.admin = User.objects.create_user("9000000001", role=User.Role.SUPERADMIN, is_superuser=True)
        self.client.force_authenticate(self.admin)
        self.branch = Branch.objects.create(name="Main", code="MAIN")
        self.employee_user = User.objects.create_user("9000000002", first_name="Ada", last_name="Lovelace")
        self.employee = Employee.objects.create(employee_code="EMP-1", user=self.employee_user, branch=self.branch)

    def create_shift(self, name="Day shift", days=None, **extra):
        payload = {"name": name, "branch": self.branch.pk, "schedule_effective_from": timezone.localdate().isoformat(), "days": days or week_payload()}
        payload.update(extra)
        response = self.client.post("/api/v1/shifts/", payload, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        return response.data["data"]

    def test_create_shift_stores_full_week_and_derives_net_hours(self):
        result = self.create_shift()
        self.assertEqual(len(result["current_schedule"]["days"]), 7)
        monday = next(day for day in result["current_schedule"]["days"] if day["weekday"] == Weekday.MONDAY)
        self.assertEqual(monday["scheduled_working_seconds"], 7 * 3600 + 30 * 60)
        shift = Shift.objects.get(pk=result["id"])
        self.assertEqual(shift.schedule_revisions.count(), 1)
        self.assertEqual(ShiftDaySchedule.objects.filter(revision__shift=shift).count(), 7)

    def test_schedule_rejects_overnight_and_invalid_break(self):
        days = week_payload()
        days[1]["start_time"], days[1]["end_time"] = "22:00", "06:00"
        overnight = self.client.post("/api/v1/shifts/", {"name": "Night", "branch": self.branch.pk, "schedule_effective_from": timezone.localdate().isoformat(), "days": days}, format="json")
        self.assertEqual(overnight.status_code, 400)
        days = week_payload()
        days[1]["break_start_time"], days[1]["break_end_time"] = "16:00", "17:30"
        invalid_break = self.client.post("/api/v1/shifts/", {"name": "Bad break", "branch": self.branch.pk, "schedule_effective_from": timezone.localdate().isoformat(), "days": days}, format="json")
        self.assertEqual(invalid_break.status_code, 400)

    def test_assignment_records_week_off_and_reassignment_preserves_history(self):
        first = self.create_shift()
        second = self.create_shift("Late shift", week_payload("10:00", "18:00"))
        effective = timezone.localdate()
        response = self.client.post("/api/v1/shift-assignments/", {
            "employee_id": self.employee.pk, "shift_id": first["id"], "effective_from": effective.isoformat(),
            "week_off_days": [Weekday.SUNDAY],
        }, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        future = effective + timedelta(days=3)
        response = self.client.post("/api/v1/shift-assignments/", {
            "employee_id": self.employee.pk, "shift_id": second["id"], "effective_from": future.isoformat(),
            "week_off_days": [Weekday.SATURDAY, Weekday.SUNDAY],
        }, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        rows = list(ShiftAssignment.objects.filter(employee=self.employee).order_by("effective_from"))
        self.assertEqual(len(rows), 2)
        self.assertEqual(rows[0].effective_to, future - timedelta(days=1))
        self.assertEqual(rows[0].week_off_days, [Weekday.SUNDAY])
        self.assertEqual(rows[1].week_off_days, [Weekday.SUNDAY, Weekday.SATURDAY])
        history = self.client.get(f"/api/v1/shift-assignments/history/{self.employee.pk}/")
        self.assertEqual(history.status_code, 200)
        self.assertEqual(history.data["data"]["count"], 2)

    def test_assignment_creation_with_nullable_employee_relations(self):
        # department, designation, branch, and optional profile fields are nullable in Employee.
        # PostgreSQL must lock only the Employee row, not the nullable select_related join side.
        self.assertIsNone(self.employee.department_id)
        self.assertIsNone(self.employee.designation_id)
        shift = self.create_shift()
        response = self.client.post("/api/v1/shift-assignments/", {
            "employee_id": self.employee.pk, "shift_id": shift["id"],
            "effective_from": timezone.localdate().isoformat(), "week_off_days": [Weekday.SUNDAY],
        }, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertTrue(ShiftAssignment.objects.filter(employee=self.employee, shift_id=shift["id"]).exists())

    def test_bulk_assignment_is_atomic_when_any_employee_invalid(self):
        second_user = User.objects.create_user("9000000003")
        second_employee = Employee.objects.create(employee_code="EMP-2", user=second_user, branch=self.branch, is_active=False)
        shift = self.create_shift()
        response = self.client.post("/api/v1/shift-assignments/bulk/", {
            "employee_ids": [self.employee.pk, second_employee.pk], "shift_id": shift["id"],
            "effective_from": timezone.localdate().isoformat(), "week_off_days": [Weekday.SUNDAY],
        }, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(ShiftAssignment.objects.exists())

    def test_bulk_assignment_creates_assignments_for_employees_with_nullable_relations(self):
        second_user = User.objects.create_user("9000000004")
        second_employee = Employee.objects.create(employee_code="EMP-3", user=second_user, branch=self.branch)
        shift = self.create_shift()
        response = self.client.post("/api/v1/shift-assignments/bulk/", {
            "employee_ids": [self.employee.pk, second_employee.pk], "shift_id": shift["id"],
            "effective_from": timezone.localdate().isoformat(), "week_off_days": [Weekday.SUNDAY],
        }, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data["data"]["created_count"], 2)
        self.assertEqual(ShiftAssignment.objects.filter(shift_id=shift["id"]).count(), 2)

    def test_schedule_revision_must_be_future(self):
        shift = self.create_shift()
        response = self.client.patch(f"/api/v1/shifts/{shift['id']}/", {
            "schedule_effective_from": timezone.localdate().isoformat(), "days": week_payload("08:00", "16:00"),
        }, format="json")
        self.assertEqual(response.status_code, 400)
        self.assertEqual(Shift.objects.get(pk=shift["id"]).schedule_revisions.count(), 1)
