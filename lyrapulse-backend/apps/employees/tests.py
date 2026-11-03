import shutil
import tempfile
from io import BytesIO

from django.contrib.auth.models import Permission
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase, override_settings
from PIL import Image
from rest_framework.test import APIClient

from apps.accounts.models import User
from apps.branches.models import Branch
from apps.departments.models import Department
from apps.designations.models import Designation
from apps.employees.models import Employee, EmployeeDocument, EmployeeType, PayrollGroup
from apps.organizations.models import Organization

PRIVATE_ROOT = tempfile.mkdtemp(prefix="lyra_private_")


def image_bytes(fmt="PNG"):
    buffer = BytesIO()
    Image.new("RGB", (8, 8), "red").save(buffer, format=fmt)
    return buffer.getvalue()


def grant(user, *codenames):
    for codename in codenames:
        user.user_permissions.add(Permission.objects.get(codename=codename, content_type__app_label="employees"))


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
        for key in ("monthly_salary", "bank_name", "bank_account_number_masked", "bank_ifsc_code", "documents", "salary_type"):
            self.assertNotIn(key, rows[0])
        self.assertEqual(rows[0]["display_name"], "Palani")

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
