from django.contrib import admin
from django.db import transaction
from django.db.models.deletion import ProtectedError

from apps.accounts.models import OTPVerification, User
from apps.attendance.models import (
    Attendance,
    AttendanceEvent,
    DeviceAttendanceEvent,
    MobileAttendanceRequest,
)
from apps.fingerprints.models import EmployeeFingerprint, FingerprintEnrollment
from apps.shifts.models import AssignmentWeekOff, ShiftAssignment

from .models import (
    AttendancePermissionAudit,
    Employee,
    EmployeeDocument,
    EmployeeType,
    PayrollGroup,
)


@admin.register(Employee)
class EmployeeAdmin(admin.ModelAdmin):
    list_display = ("employee_code", "user", "branch", "department", "is_active")
    search_fields = ("employee_code", "user__phone_number", "user__first_name", "user__last_name")
    list_filter = ("is_active", "branch", "department")
    ordering = ("employee_code",)

    def has_delete_permission(self, request, obj=None):
        return (
            super().has_delete_permission(request, obj)
            and request.user.has_perm("accounts.delete_user")
        )

    @staticmethod
    def _protected_references(employee_ids, user_ids, attendance_ids):
        protected = []
        protected.extend(
            Attendance.objects.filter(created_by_id__in=user_ids)
            .exclude(employee_id__in=employee_ids)
        )
        protected.extend(
            AttendanceEvent.objects.filter(actor_id__in=user_ids)
            .exclude(attendance__employee_id__in=employee_ids)
        )
        protected.extend(
            FingerprintEnrollment.objects.filter(created_by_id__in=user_ids)
            .exclude(employee_id__in=employee_ids)
        )
        protected.extend(
            AttendancePermissionAudit.objects.filter(actor_id__in=user_ids)
            .exclude(employee_id__in=employee_ids)
        )
        protected.extend(
            MobileAttendanceRequest.objects.filter(attendance_id__in=attendance_ids)
            .exclude(employee_id__in=employee_ids)
        )
        protected.extend(
            AttendanceEvent.objects.filter(device_event__attendance_id__in=attendance_ids)
            .exclude(attendance_id__in=attendance_ids)
        )
        return list({(obj._meta.label_lower, obj.pk): obj for obj in protected}.values())

    @classmethod
    def _deletion_summary(cls, employees):
        employee_ids = {employee.pk for employee in employees}
        user_ids = {employee.user_id for employee in employees}
        attendance_ids = set(
            Attendance.objects.filter(employee_id__in=employee_ids)
            .values_list("pk", flat=True)
        )
        protected = cls._protected_references(employee_ids, user_ids, attendance_ids)
        counts = (
            (Employee, len(employees)),
            (User, len(user_ids)),
            (
                OTPVerification,
                OTPVerification.objects.filter(
                    phone_number__in=[employee.user.phone_number for employee in employees]
                ).count(),
            ),
            (EmployeeDocument, EmployeeDocument.objects.filter(employee_id__in=employee_ids).count()),
            (Attendance, len(attendance_ids)),
            (AttendanceEvent, AttendanceEvent.objects.filter(attendance_id__in=attendance_ids).count()),
            (
                DeviceAttendanceEvent,
                DeviceAttendanceEvent.objects.filter(attendance_id__in=attendance_ids).count(),
            ),
            (
                MobileAttendanceRequest,
                MobileAttendanceRequest.objects.filter(employee_id__in=employee_ids).count(),
            ),
            (
                AttendancePermissionAudit,
                AttendancePermissionAudit.objects.filter(employee_id__in=employee_ids).count(),
            ),
            (
                EmployeeFingerprint,
                EmployeeFingerprint.objects.filter(employee_id__in=employee_ids).count(),
            ),
            (
                FingerprintEnrollment,
                FingerprintEnrollment.objects.filter(employee_id__in=employee_ids).count(),
            ),
            (ShiftAssignment, ShiftAssignment.objects.filter(employee_id__in=employee_ids).count()),
            (
                AssignmentWeekOff,
                AssignmentWeekOff.objects.filter(assignment__employee_id__in=employee_ids).count(),
            ),
        )
        model_count = {
            model._meta.verbose_name_plural: count
            for model, count in counts
            if count
        }
        return employee_ids, user_ids, attendance_ids, protected, model_count

    def get_deleted_objects(self, objs, request):
        employees = list(objs)
        _, _, _, protected, model_count = self._deletion_summary(employees)
        deleted_objects = [
            [
                "Employee: %s (ID %s)" % (employee.employee_code, employee.pk),
                [
                    "Associated Django User: %s (%s, ID %s)"
                    % (employee.user.full_name, employee.user, employee.user_id),
                ],
            ]
            for employee in employees
        ]
        return deleted_objects, model_count, set(), [str(obj) for obj in protected]

    @classmethod
    def _delete_employee_records(cls, employee_ids):
        employee_ids = set(employee_ids)
        if not employee_ids:
            return

        with transaction.atomic():
            employees = list(
                Employee.objects.select_for_update()
                .select_related("user")
                .filter(pk__in=employee_ids)
                .order_by("pk")
            )
            if len(employees) != len(employee_ids):
                raise Employee.DoesNotExist("An employee selected for deletion no longer exists.")

            user_ids = {employee.user_id for employee in employees}
            users = list(
                User.objects.select_for_update().filter(pk__in=user_ids).order_by("pk")
            )
            if len(users) != len(user_ids):
                raise User.DoesNotExist("An employee's associated user no longer exists.")

            employee_ids, user_ids, attendance_ids, protected, _ = cls._deletion_summary(employees)
            if protected:
                raise ProtectedError(
                    "Protected records belonging to other employees prevent deletion.",
                    protected,
                )

            AttendanceEvent.objects.filter(attendance_id__in=attendance_ids).delete()
            DeviceAttendanceEvent.objects.filter(attendance_id__in=attendance_ids).delete()
            MobileAttendanceRequest.objects.filter(employee_id__in=employee_ids).delete()
            Attendance.objects.filter(pk__in=attendance_ids).delete()
            EmployeeFingerprint.objects.filter(employee_id__in=employee_ids).delete()
            FingerprintEnrollment.objects.filter(employee_id__in=employee_ids).delete()
            AttendancePermissionAudit.objects.filter(employee_id__in=employee_ids).delete()
            ShiftAssignment.objects.filter(employee_id__in=employee_ids).delete()
            OTPVerification.objects.filter(
                phone_number__in=[employee.user.phone_number for employee in employees]
            ).delete()

            for employee in employees:
                employee.delete()
            for user in users:
                user.delete()

    def delete_model(self, request, obj):
        self._delete_employee_records([obj.pk])

    def delete_queryset(self, request, queryset):
        self._delete_employee_records(queryset.values_list("pk", flat=True))


@admin.register(EmployeeType)
class EmployeeTypeAdmin(admin.ModelAdmin):
    list_display = ("name", "is_active")
    list_filter = ("is_active",)
    search_fields = ("name",)


@admin.register(PayrollGroup)
class PayrollGroupAdmin(admin.ModelAdmin):
    list_display = ("name", "is_active")
    list_filter = ("is_active",)
    search_fields = ("name",)


@admin.register(EmployeeDocument)
class EmployeeDocumentAdmin(admin.ModelAdmin):
    list_display = ("employee", "doc_type", "side", "original_name", "size", "uploaded_at")
    list_filter = ("doc_type",)
    readonly_fields = ("file", "original_name", "content_type", "size", "uploaded_at")