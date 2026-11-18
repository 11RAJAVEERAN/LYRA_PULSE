import shutil
import tempfile
import uuid
from datetime import timedelta
from io import BytesIO
from unittest.mock import patch

from django.contrib import admin
from django.contrib.auth.models import Permission
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import Client, TestCase, override_settings
from django.urls import reverse
from django.utils import timezone
from PIL import Image
from rest_framework.test import APIClient

from apps.attendance.models import (
    Attendance,
    AttendanceEvent,
    DeviceAttendanceEvent,
    MobileAttendanceRequest,
)
from apps.accounts.models import OTPVerification, User
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.devices.models import Device
from apps.designations.models import Designation
from apps.employees.models import (
    AttendancePermissionAudit,
    Employee,
    EmployeeDocument,
    EmployeeType,
    PayrollGroup,
)
from apps.fingerprints.models import EmployeeFingerprint, FingerprintEnrollment
from apps.organizations.models import Organization
from apps.shifts.models import AssignmentWeekOff, Shift, ShiftAssignment

PRIVATE_ROOT = tempfile.mkdtemp(prefix="lyra_private_")


def image_bytes(fmt="PNG"):
    buffer = BytesIO()
    Image.new("RGB", (8, 8), "red").save(buffer, format=fmt)
    return buffer.getvalue()


def grant(user, *codenames):
    for codename in codenames:
        user.user_permissions.add(Permission.objects.get(codename=codename, content_type__app_label="employees"))


@override_settings(ROOT_URLCONF="config.urls", PRIVATE_MEDIA_ROOT=PRIVATE_ROOT)
class EmployeeAdminDeletionTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            "9000000099",
            password="test-admin-password",
        )
        self.organization = Organization.objects.create(name="Deletion Org", code="DEL-ORG")
        self.branch = Branch.objects.create(
            organization=self.organization,
            name="Deletion Branch",
            code="DEL-BR",
        )
        self.department = Department.objects.create(name="Deletion Department", branch=self.branch)
        self.designation = Designation.objects.create(
            name="Deletion Designation",
            department=self.department,
        )
        self.device = Device.objects.create(
            device_id="DEL-DEVICE",
            branch=self.branch,
            token_hash="test-hash",
        )
        self.shift = Shift.objects.create(branch=self.branch, name="Deletion Shift")
        self.admin_client = Client()
        self.admin_client.force_login(self.admin)

    def create_employee(self, code, phone_number):
        user = User.objects.create_user(
            phone_number,
            role=User.Role.EMPLOYEE,
            first_name="Test",
            last_name=code,
        )
        employee = Employee.objects.create(
            employee_code=code,
            user=user,
            branch=self.branch,
            department=self.department,
            designation=self.designation,
        )
        return employee

    def add_employee_records(self, employee, slot):
        now = timezone.now()
        attendance = Attendance.objects.create(
            employee=employee,
            device=self.device,
            created_by=employee.user,
            source=AttendanceEvent.Method.BIOMETRIC,
            branch=self.branch,
            attendance_date=timezone.localdate(),
            check_in_at=now - timedelta(seconds=1),
            check_in_photo="attendance/checkin/test.jpg",
        )
        device_event = DeviceAttendanceEvent.objects.create(
            device=self.device,
            event_id=uuid.uuid4(),
            fingerprint_slot=slot,
            occurred_at=now - timedelta(seconds=1),
            attendance=attendance,
        )
        action = AttendanceEvent.objects.create(
            attendance=attendance,
            action=AttendanceEvent.Action.CHECK_IN,
            method=AttendanceEvent.Method.BIOMETRIC,
            actor=employee.user,
            device=self.device,
            device_event=device_event,
            occurred_at=now - timedelta(seconds=1),
        )
        mobile_request = MobileAttendanceRequest.objects.create(
            key="delete-%s" % employee.employee_code,
            employee=employee,
            action=AttendanceEvent.Action.CHECK_IN,
            payload_fingerprint="a" * 64,
            outcome=MobileAttendanceRequest.Outcome.SUCCEEDED,
            attendance=attendance,
        )
        fingerprint = EmployeeFingerprint.objects.create(
            employee=employee,
            device=self.device,
            fingerprint_slot=slot,
            finger=FingerprintEnrollment.Finger.RIGHT_INDEX,
        )
        enrollment = FingerprintEnrollment.objects.create(
            employee=employee,
            device=self.device,
            finger=FingerprintEnrollment.Finger.RIGHT_INDEX,
            status=FingerprintEnrollment.Status.SUCCESS,
            actual_slot=slot,
            created_by=employee.user,
            expires_at=now + timedelta(days=1),
        )
        audit = AttendancePermissionAudit.objects.create(
            employee=employee,
            actor=employee.user,
            previous_values={},
            new_values={},
        )
        assignment = ShiftAssignment.objects.create(
            employee=employee,
            shift=self.shift,
            effective_from=timezone.localdate(),
            assigned_by=self.admin,
        )
        week_off = AssignmentWeekOff.objects.create(
            assignment=assignment,
            weekday="SUNDAY",
        )
        document = EmployeeDocument.objects.create(
            employee=employee,
            doc_type=EmployeeDocument.DocType.PAN,
            side=EmployeeDocument.Side.SINGLE,
            file="employee_documents/test/pan.pdf",
            original_name="pan.pdf",
            content_type="application/pdf",
            size=1,
        )
        otp = OTPVerification.objects.create(
            phone_number=employee.user.phone_number,
            otp_hash="test-hash",
            expires_at=now + timedelta(minutes=5),
        )
        return {
            "attendance": attendance,
            "device_event": device_event,
            "action": action,
            "mobile_request": mobile_request,
            "fingerprint": fingerprint,
            "enrollment": enrollment,
            "audit": audit,
            "assignment": assignment,
            "week_off": week_off,
            "document": document,
            "otp": otp,
        }

    def employee_delete_url(self, employee):
        return reverse("admin:employees_employee_delete", args=(employee.pk,))

    def test_admin_delete_removes_employee_user_and_exclusive_records_only(self):
        employee = self.create_employee("DEL-001", "9000000101")
        unrelated = self.create_employee("DEL-002", "9000000102")
        employee_records = self.add_employee_records(employee, 1)
        unrelated_records = self.add_employee_records(unrelated, 2)

        confirmation = self.admin_client.get(self.employee_delete_url(employee))
        self.assertEqual(confirmation.status_code, 200)
        self.assertContains(confirmation, "Employee: DEL-001")
        self.assertContains(confirmation, "Associated Django User")
        self.assertContains(confirmation, employee.user.phone_number)

        response = self.admin_client.post(self.employee_delete_url(employee), {"post": "yes"})

        self.assertEqual(response.status_code, 302)
        self.assertFalse(Employee.objects.filter(pk=employee.pk).exists())
        self.assertFalse(User.objects.filter(pk=employee.user_id).exists())
        for key, record in employee_records.items():
            self.assertFalse(type(record).objects.filter(pk=record.pk).exists(), key)

        unrelated.refresh_from_db()
        self.assertTrue(User.objects.filter(pk=unrelated.user_id).exists())
        for key, record in unrelated_records.items():
            self.assertTrue(type(record).objects.filter(pk=record.pk).exists(), key)
        self.assertTrue(Branch.objects.filter(pk=self.branch.pk).exists())
        self.assertTrue(Device.objects.filter(pk=self.device.pk).exists())
        self.assertTrue(Department.objects.filter(pk=self.department.pk).exists())
        self.assertTrue(Designation.objects.filter(pk=self.designation.pk).exists())
        self.assertTrue(Shift.objects.filter(pk=self.shift.pk).exists())

    def test_bulk_admin_delete_uses_the_same_employee_and_user_cleanup(self):
        first = self.create_employee("DEL-008", "9000000108")
        second = self.create_employee("DEL-009", "9000000109")
        first_records = self.add_employee_records(first, 8)
        second_records = self.add_employee_records(second, 9)

        admin.site._registry[Employee].delete_queryset(
            None,
            Employee.objects.filter(pk__in=(first.pk, second.pk)),
        )

        self.assertFalse(Employee.objects.filter(pk__in=(first.pk, second.pk)).exists())
        self.assertFalse(User.objects.filter(pk__in=(first.user_id, second.user_id)).exists())
        for record in (*first_records.values(), *second_records.values()):
            self.assertFalse(type(record).objects.filter(pk=record.pk).exists())
        self.assertTrue(Branch.objects.filter(pk=self.branch.pk).exists())
        self.assertTrue(Device.objects.filter(pk=self.device.pk).exists())

    def test_admin_delete_rolls_back_all_rows_when_user_deletion_fails(self):
        employee = self.create_employee("DEL-003", "9000000103")
        records = self.add_employee_records(employee, 3)

        with patch.object(User, "delete", side_effect=RuntimeError("simulated delete failure")):
            with self.assertRaises(RuntimeError):
                admin.site._registry[Employee].delete_model(None, employee)

        self.assertTrue(Employee.objects.filter(pk=employee.pk).exists())
        self.assertTrue(User.objects.filter(pk=employee.user_id).exists())
        for record in records.values():
            self.assertTrue(type(record).objects.filter(pk=record.pk).exists())

    def test_protected_references_from_another_employee_block_deletion(self):
        employee = self.create_employee("DEL-004", "9000000104")
        unrelated = self.create_employee("DEL-005", "9000000105")
        external_attendance = Attendance.objects.create(
            employee=unrelated,
            created_by=employee.user,
            branch=self.branch,
            attendance_date=timezone.localdate(),
            check_in_at=timezone.now() - timedelta(seconds=1),
        )

        confirmation = self.admin_client.get(self.employee_delete_url(employee))
        self.assertContains(confirmation, "protected")
        response = self.admin_client.post(self.employee_delete_url(employee), {"post": "yes"})

        self.assertEqual(response.status_code, 200)
        self.assertTrue(Employee.objects.filter(pk=employee.pk).exists())
        self.assertTrue(User.objects.filter(pk=employee.user_id).exists())
        self.assertTrue(Attendance.objects.filter(pk=external_attendance.pk).exists())

    def test_employee_linked_user_cannot_be_deleted_from_user_admin(self):
        employee = self.create_employee("DEL-006", "9000000106")
        url = reverse("admin:accounts_user_delete", args=(employee.user_id,))

        response = self.admin_client.get(url)

        self.assertEqual(response.status_code, 403)
        self.assertTrue(Employee.objects.filter(pk=employee.pk).exists())
        self.assertTrue(User.objects.filter(pk=employee.user_id).exists())

    def test_public_api_and_ordinary_employee_cannot_delete_employee_or_user(self):
        employee = self.create_employee("DEL-007", "9000000107")

        api_client = APIClient()
        api_client.force_authenticate(self.admin)
        response = api_client.delete("/api/v1/employees/%s/" % employee.pk)
        self.assertIn(response.status_code, (403, 405))
        self.assertTrue(Employee.objects.filter(pk=employee.pk).exists())
        self.assertTrue(User.objects.filter(pk=employee.user_id).exists())

        ordinary_client = Client()
        ordinary_client.force_login(employee.user)
        response = ordinary_client.get(self.employee_delete_url(employee))
        self.assertEqual(response.status_code, 302)
        self.assertTrue(Employee.objects.filter(pk=employee.pk).exists())
        self.assertTrue(User.objects.filter(pk=employee.user_id).exists())


@override_settings(ROOT_URLCONF="config.urls", PRIVATE_MEDIA_ROOT=PRIVATE_ROOT)
class EmployeeDetailsFormTests(TestCase):
    @classmethod
    def tearDownClass(cls):
        super().tearDownClass()
        shutil.rmtree(PRIVATE_ROOT, ignore_errors=True)

    def setUp(self):
        self.client = APIClient()
        self.org = Organization.objects.create(name="Devi", code="DEVI")
        self.branch = Branch.objects.create(organization=self.org, name="Chennai", code="CHN")
        self.department = Department.objects.create(name="Maintenance", branch=self.branch)
        self.designation = Designation.objects.create(name="Technician", department=self.department)
        self.employee_type = EmployeeType.objects.create(name="Permanent")
        self.payroll_group = PayrollGroup.objects.create(name="Group A")
        self.superadmin = User.objects.create_user("9000000000", role=User.Role.SUPERADMIN, is_superuser=True)
        # HR with employee view/add/change but NOT the sensitive permissions
        self.hr = User.objects.create_user("9111111111", role=User.Role.HR, organization=self.org)
        self.hr.allowed_branches.add(self.branch)
        grant(self.hr, "view_employee", "add_employee", "change_employee")
        # HR with the sensitive permissions too
        self.payroll_hr = User.objects.create_user("9222222222", role=User.Role.HR, organization=self.org)
        self.payroll_hr.allowed_branches.add(self.branch)
        grant(self.payroll_hr, "view_employee", "add_employee", "change_employee", "view_employee_sensitive", "change_employee_sensitive")

    def payload(self, **extra):
        data = {
            "employee_code": "120", "first_name": "Palanivel", "last_name": "D", "phone_number": "9876500001",
            "branch": self.branch.pk, "department": self.department.pk, "designation": self.designation.pk,
            "display_name": "Palani", "employee_type": self.employee_type.pk, "door_lock_permission": True,
            "uan_number": "123456789012", "esic_number": "1234567890", "pf_number": "PF/001",
            "address": "Chennai", "date_of_birth": "1990-05-01", "joining_date": "2024-01-01",
            "salary_type": "MONTHLY", "monthly_salary": "15000.50", "payroll_group": self.payroll_group.pk,
            "bank_name": "SBI", "bank_branch_name": "T Nagar", "bank_account_number": "998877665544", "bank_ifsc_code": "sbin0001234",
            "emergency_contact_number": "+91 98765 00002", "emergency_contact_name": "Ravi",
            "emergency_contact_relation": "Brother", "emergency_contact_address": "Madurai",
        }
        data.update(extra)
        return data

    def create_employee(self, user=None, **extra):
        self.client.force_authenticate(user=user or self.superadmin)
        response = self.client.post("/api/v1/employees/", self.payload(**extra), format="json")
        self.assertEqual(response.status_code, 201, response.data)
        return response.data["data"]

    # ---- create / retrieve / update ----
    def test_create_persists_all_sections_and_normalizes_values(self):
        data = self.create_employee()
        employee = Employee.objects.get(pk=data["id"])
        self.assertEqual(employee.display_name, "Palani")
        self.assertEqual(employee.employee_type, self.employee_type)
        self.assertEqual(str(employee.monthly_salary), "15000.50")
        self.assertEqual(employee.bank_ifsc_code, "SBIN0001234")
        self.assertEqual(employee.emergency_contact, "9876500002")
        self.assertEqual(employee.emergency_contact_relation, "Brother")
        self.assertEqual(employee.payroll_group, self.payroll_group)
        self.assertTrue(employee.door_lock_permission)

    def test_detail_masks_account_number_and_never_returns_full_value(self):
        data = self.create_employee()
        response = self.client.get(f"/api/v1/employees/{data['id']}/")
        body = response.data["data"]
        self.assertEqual(body["bank_account_number_masked"], "XXXXXXXX5544")
        self.assertNotIn("bank_account_number", body)
        self.assertNotIn("998877665544", str(response.content))

    def test_list_omits_salary_bank_and_documents(self):
        self.create_employee()
        rows = self.client.get("/api/v1/employees/").data["data"]
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["organization"], self.org.pk)
        self.assertEqual(rows[0]["organization_name"], self.org.name)
        for key in ("monthly_salary", "bank_name", "bank_account_number_masked", "bank_ifsc_code", "documents", "salary_type"):
            self.assertNotIn(key, rows[0])
        self.assertEqual(rows[0]["display_name"], "Palani")

    def test_company_branch_search_and_status_filters_are_scoped(self):
        employee = self.create_employee()
        other_org = Organization.objects.create(name="Other Company", code="OTHER")
        other_branch = Branch.objects.create(organization=other_org, name="Other Branch", code="OTH")
        other_department = Department.objects.create(name="Other Department", branch=other_branch)
        other_designation = Designation.objects.create(name="Other Designation", department=other_department)
        other = self.create_employee(
            employee_code="121", phone_number="9876500003", first_name="Other", last_name="Person",
            branch=other_branch.pk, department=other_department.pk, designation=other_designation.pk,
        )

        self.client.force_authenticate(user=self.hr)
        scoped = self.client.get("/api/v1/employees/").data["data"]
        self.assertEqual([row["id"] for row in scoped], [employee["id"]])
        self.assertEqual(
            self.client.get(f"/api/v1/employees/?organization={other_org.pk}").data["data"],
            [],
        )
        self.assertEqual(self.client.get(f"/api/v1/employees/{other['id']}/").status_code, 404)
        cross_company_update = self.client.patch(
            f"/api/v1/employees/{other['id']}/", {"display_name": "Unauthorized"}, format="json",
        )
        self.assertEqual(cross_company_update.status_code, 404)
        for query in (
            "search=120",
            "search=9876500001",
            f"branch={self.branch.pk}",
            f"department={self.department.pk}",
            f"designation={self.designation.pk}",
        ):
            result = self.client.get(f"/api/v1/employees/?{query}")
            self.assertEqual(result.status_code, 200, result.data)
            self.assertEqual([row["id"] for row in result.data["data"]], [employee["id"]], query)
        self.assertEqual(self.client.get("/api/v1/employees/?status=unsupported").status_code, 400)
        self.assertEqual(self.client.get("/api/v1/employees/?branch=invalid").data["data"], [])

        self.client.force_authenticate(user=self.superadmin)
        response = self.client.patch(
            f"/api/v1/employees/{employee['id']}/", {"is_active": False}, format="json",
        )
        self.assertEqual(response.status_code, 200, response.data)
        inactive = self.client.get("/api/v1/employees/?status=inactive").data["data"]
        self.assertEqual([row["id"] for row in inactive], [employee["id"]])
        self.assertEqual(self.client.get("/api/v1/employees/?status=active").data["data"][0]["id"], other["id"])
        self.assertFalse(Employee.objects.get(pk=employee["id"]).user.is_active)

    def test_update_preserves_employee_and_user_identity(self):
        data = self.create_employee()
        employee = Employee.objects.get(pk=data["id"])
        user_id = employee.user_id

        response = self.client.patch(
            f"/api/v1/employees/{data['id']}/", {"display_name": "Updated"}, format="json",
        )

        self.assertEqual(response.status_code, 200, response.data)
        employee.refresh_from_db()
        self.assertEqual(employee.pk, data["id"])
        self.assertEqual(employee.user_id, user_id)
        self.assertEqual(employee.display_name, "Updated")

    def test_partial_update_keeps_account_number_when_blank(self):
        data = self.create_employee()
        response = self.client.patch(f"/api/v1/employees/{data['id']}/", {"bank_account_number": "", "display_name": "P"}, format="json")
        self.assertEqual(response.status_code, 200, response.data)
        employee = Employee.objects.get(pk=data["id"])
        self.assertEqual(employee.bank_account_number, "998877665544")
        self.assertEqual(employee.display_name, "P")

    def test_legacy_create_payload_still_works(self):
        self.client.force_authenticate(user=self.superadmin)
        response = self.client.post("/api/v1/employees/", {
            "employee_code": "EMP900", "first_name": "Old", "last_name": "Client", "phone_number": "9876500009",
            "email": "old@example.com", "branch": self.branch.pk, "is_active": True,
        }, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data["data"]["salary_type"], "MONTHLY")

    # ---- validation ----
    def test_validation_errors(self):
        self.client.force_authenticate(user=self.superadmin)
        cases = {
            "bank_ifsc_code": "BAD123", "uan_number": "123", "esic_number": "12",
            "date_of_birth": "2999-01-01", "monthly_salary": "-5", "emergency_contact_number": "123",
            "bank_account_number": "12-3",
        }
        for field, value in cases.items():
            response = self.client.post("/api/v1/employees/", self.payload(**{field: value}), format="json")
            self.assertEqual(response.status_code, 400, field)
            self.assertIn(field, response.data["errors"], field)

    def test_duplicate_employee_code_and_phone_rejected(self):
        self.create_employee()
        response = self.client.post("/api/v1/employees/", self.payload(phone_number="9876500003"), format="json")
        self.assertEqual(response.status_code, 400)
        self.assertIn("employee_code", response.data["errors"])
        response = self.client.post("/api/v1/employees/", self.payload(employee_code="121"), format="json")
        self.assertIn("phone_number", response.data["errors"])

    def test_inactive_employee_type_rejected(self):
        self.employee_type.is_active = False
        self.employee_type.save()
        self.client.force_authenticate(user=self.superadmin)
        response = self.client.post("/api/v1/employees/", self.payload(), format="json")
        self.assertEqual(response.status_code, 400)
        self.assertIn("employee_type", response.data["errors"])

    # ---- permissions ----
    def test_anonymous_rejected(self):
        self.assertEqual(self.client.get("/api/v1/employees/").status_code, 401)

    def test_hr_without_sensitive_permission_cannot_see_or_write_salary_and_bank(self):
        data = self.create_employee()  # created by superadmin with salary + bank
        self.client.force_authenticate(user=self.hr)
        body = self.client.get(f"/api/v1/employees/{data['id']}/").data["data"]
        for key in ("monthly_salary", "bank_name", "bank_account_number_masked", "documents", "payroll_group"):
            self.assertNotIn(key, body)
        self.assertEqual(self.client.patch(f"/api/v1/employees/{data['id']}/", {"monthly_salary": "1"}, format="json").status_code, 403)
        # non-sensitive edits still work
        self.assertEqual(self.client.patch(f"/api/v1/employees/{data['id']}/", {"display_name": "X"}, format="json").status_code, 200)
        self.assertEqual(Employee.objects.get(pk=data["id"]).monthly_salary, 15000.50)

    def test_sensitive_hr_sees_salary_and_bank(self):
        data = self.create_employee()
        self.client.force_authenticate(user=self.payroll_hr)
        body = self.client.get(f"/api/v1/employees/{data['id']}/").data["data"]
        self.assertEqual(body["monthly_salary"], "15000.50")
        self.assertEqual(body["bank_name"], "SBI")

    def test_form_access_endpoint(self):
        self.client.force_authenticate(user=self.hr)
        self.assertEqual(self.client.get("/api/v1/employees/form-access/").data["data"],
                         {"can_view_sensitive": False, "can_change_sensitive": False, "can_edit_attendance_permissions": False})
        self.client.force_authenticate(user=self.payroll_hr)
        self.assertTrue(self.client.get("/api/v1/employees/form-access/").data["data"]["can_change_sensitive"])

    def test_option_endpoints_return_active_only(self):
        EmployeeType.objects.create(name="Retired", is_active=False)
        self.client.force_authenticate(user=self.superadmin)
        branch = self.client.get("/api/v1/branches/").data["data"][0]
        self.assertEqual(branch["organization"]["id"], self.org.pk)
        self.assertEqual(branch["organization"]["name"], self.org.name)
        self.client.force_authenticate(user=self.hr)
        self.assertEqual([i["name"] for i in self.client.get("/api/v1/employee-types/").data["data"]], ["Permanent"])
        self.assertEqual([i["name"] for i in self.client.get("/api/v1/payroll-groups/").data["data"]], ["Group A"])

    # ---- documents ----
    def upload(self, employee_id, name="aadhaar.png", content=None, doc_type="AADHAAR", side="FRONT", user=None):
        self.client.force_authenticate(user=user or self.payroll_hr)
        file = SimpleUploadedFile(name, content if content is not None else image_bytes())
        return self.client.post(f"/api/v1/employees/{employee_id}/documents/",
                                {"doc_type": doc_type, "side": side, "file": file}, format="multipart")

    def test_upload_download_replace_and_delete_document(self):
        employee = self.create_employee()
        response = self.upload(employee["id"])
        self.assertEqual(response.status_code, 201, response.data)
        doc = response.data["data"]
        self.assertEqual(doc["content_type"], "image/png")
        stored = EmployeeDocument.objects.get(pk=doc["id"])
        old_path = stored.file.path
        # replace the same slot: still one row, new file on disk, old file removed
        with self.captureOnCommitCallbacks(execute=True):
            replaced = self.upload(employee["id"], name="new.jpg", content=image_bytes("JPEG"))
        self.assertEqual(replaced.status_code, 201, replaced.data)
        self.assertEqual(EmployeeDocument.objects.filter(employee_id=employee["id"]).count(), 1)
        self.assertEqual(replaced.data["data"]["content_type"], "image/jpeg")
        import os
        self.assertFalse(os.path.exists(old_path))
        # download requires auth + sensitive permission
        url = replaced.data["data"]["download_url"]
        download = self.client.get(url)
        self.assertEqual(download.status_code, 200)
        self.assertEqual(download["X-Content-Type-Options"], "nosniff")
        self.assertEqual(b"".join(download.streaming_content)[:3], b"\xff\xd8\xff")
        self.client.force_authenticate(user=self.hr)
        self.assertEqual(self.client.get(url).status_code, 403)
        self.client.logout()
        self.assertEqual(self.client.get(url).status_code, 401)
        # detail shows documents; update of an unrelated field keeps them
        self.client.force_authenticate(user=self.payroll_hr)
        self.client.patch(f"/api/v1/employees/{employee['id']}/", {"display_name": "Z"}, format="json")
        self.assertEqual(len(self.client.get(f"/api/v1/employees/{employee['id']}/").data["data"]["documents"]), 1)
        # delete
        with self.captureOnCommitCallbacks(execute=True):
            self.assertEqual(self.client.delete(url.replace("/download/", "/")).status_code, 200)
        self.assertEqual(EmployeeDocument.objects.count(), 0)

    def test_document_upload_rejections(self):
        employee = self.create_employee()
        eid = employee["id"]
        bad = [
            ("script.exe", b"MZ\x90\x00", "AADHAAR", "FRONT"),                      # extension
            ("fake.png", b"not an image at all", "AADHAAR", "FRONT"),               # content is not an image
            ("fake.pdf", b"not a pdf", "PAN", "SINGLE"),                           # content is not a pdf
            ("mismatch.jpg", image_bytes("PNG"), "PAN", "SINGLE"),                 # PNG content, .jpg name
            ("big.pdf", b"%PDF-1.4\n" + b"0" * (1024 * 1024 + 1), "PAN", "SINGLE"),  # PDF over 1 MB
            ("empty.png", b"", "PAN", "SINGLE"),
        ]
        for name, content, doc_type, side in bad:
            response = self.upload(eid, name=name, content=content, doc_type=doc_type, side=side)
            self.assertEqual(response.status_code, 400, name)
            self.assertIn("file", response.data["errors"], name)
        self.assertEqual(self.upload(eid, doc_type="NOPE").status_code, 400)
        self.assertEqual(self.upload(eid, doc_type="AADHAAR", side="SINGLE").status_code, 400)
        self.assertEqual(self.upload(eid, doc_type="PAN", side="FRONT").status_code, 400)
        self.assertEqual(EmployeeDocument.objects.count(), 0)

    def test_valid_small_pdf_accepted(self):
        employee = self.create_employee()
        response = self.upload(employee["id"], name="pan.pdf", content=b"%PDF-1.4\n%%EOF", doc_type="PAN", side="SINGLE")
        self.assertEqual(response.status_code, 201, response.data)
        self.assertEqual(response.data["data"]["content_type"], "application/pdf")

    def test_document_upload_requires_change_sensitive_permission(self):
        employee = self.create_employee()
        self.assertEqual(self.upload(employee["id"], user=self.hr).status_code, 403)

    def test_documents_are_scoped_to_admin_branches(self):
        employee = self.create_employee()
        other_org = Organization.objects.create(name="Other", code="OTH")
        other_branch = Branch.objects.create(organization=other_org, name="Elsewhere", code="ELS")
        outsider = User.objects.create_user("9333333333", role=User.Role.HR, organization=other_org)
        outsider.allowed_branches.add(other_branch)
        grant(outsider, "view_employee", "view_employee_sensitive", "change_employee_sensitive")
        self.assertEqual(self.upload(employee["id"], user=outsider).status_code, 404)

    def test_private_documents_have_no_public_url(self):
        employee = self.create_employee()
        self.upload(employee["id"])
        document = EmployeeDocument.objects.get()
        with self.assertRaises(ValueError):
            document.file.url

    def test_employee_branch_department_and_designation_must_match(self):
        other_branch = Branch.objects.create(organization=self.org, name="Madurai", code="MDU")
        other_department = Department.objects.create(name="Other Department", branch=other_branch)
        other_designation = Designation.objects.create(name="Other Designation", department=other_department)

        self.client.force_authenticate(user=self.superadmin)
        invalid_create = self.client.post(
            "/api/v1/employees/",
            self.payload(department=other_department.pk),
            format="json",
        )
        self.assertEqual(invalid_create.status_code, 400, invalid_create.data)

        employee = self.create_employee()
        invalid_update = self.client.patch(
            f"/api/v1/employees/{employee['id']}/",
            {"designation": other_designation.pk},
            format="json",
        )
        self.assertEqual(invalid_update.status_code, 400, invalid_update.data)
