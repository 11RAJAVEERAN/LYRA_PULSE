from datetime import timedelta
from zoneinfo import ZoneInfo

from django.conf import settings
from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework.exceptions import NotFound, PermissionDenied

from apps.devices.models import Device
from apps.employees.models import Employee
from apps.fingerprints.models import EmployeeFingerprint

from .models import Attendance

def _attendance_response(mapping, attendance, status, duplicate=False):
    employee = mapping.employee
    data = {
        "attendance_id": attendance.pk,
        "employee": {
            "id": employee.pk,
            "name": employee.user.full_name,
        },
        "status": status,
        "attendance_date": attendance.attendance_date,
        "check_in_time": attendance.check_in_at,
        "check_out_time": attendance.check_out_at,
    }
    if duplicate:
        data["duplicate"] = True
    return data


def _serialize_session(attendance):
    status = "CHECKED_OUT" if attendance.check_out_at else "CHECKED_IN"
    return {
        "attendance_id": attendance.pk,
        "check_in_time": attendance.check_in_at,
        "check_out_time": attendance.check_out_at,
        "status": status,
        "source": attendance.source,
        "branch_id": attendance.branch_id,
        "device_id": attendance.device.device_id,
    }


def get_employee_attendance_history(employee_id, attendance_date):
    employee = Employee.objects.select_related("user").filter(pk=employee_id).first()
    if employee is None:
        raise NotFound("Employee does not exist.")

    sessions = list(
        Attendance.objects.select_related("device")
        .filter(employee=employee, attendance_date=attendance_date)
        .order_by("check_in_at", "pk")
    )
    total_working_seconds = int(sum(
        (session.check_out_at - session.check_in_at).total_seconds()
        for session in sessions
        if session.check_out_at is not None
    ))
    return {
        "employee": {
            "id": employee.pk,
            "name": employee.user.full_name,
        },
        "date": attendance_date,
        "sessions": [_serialize_session(session) for session in sessions],
        "total_working_seconds": total_working_seconds,
        "total_working_hours": round(total_working_seconds / 3600, 2),
    }


@transaction.atomic
def record_fingerprint_attendance(device, fingerprint_slot):
    device = Device.objects.select_for_update().select_related("branch").get(pk=device.pk)
    if not device.is_active:
        raise PermissionDenied("The attendance device is inactive.")
    if not device.branch.is_active:
        raise PermissionDenied("The attendance device branch is inactive.")

    mapping = (
        EmployeeFingerprint.objects.select_related("employee", "employee__user")
        .filter(device=device, fingerprint_slot=fingerprint_slot, is_active=True)
        .first()
    )
    if mapping is None:
        raise NotFound("No active fingerprint mapping exists for this device and slot.")

    employee = Employee.objects.select_for_update().select_related("user").get(pk=mapping.employee_id)
    if not employee.is_active or not employee.user.is_active:
        raise PermissionDenied("The employee is inactive.")
    if employee.branch_id != device.branch_id:
        raise PermissionDenied("The employee and attendance device are assigned to different branches.")

    now = timezone.now()
    attendance_date = timezone.localtime(now, ZoneInfo(settings.TIME_ZONE)).date()
    attendance = (
        Attendance.objects.select_for_update()
        .filter(employee=employee, attendance_date=attendance_date)
        .order_by("-check_in_at", "-pk")
        .first()
    )

    cooldown_seconds = max(
        0,
        getattr(settings, "ATTENDANCE_FINGERPRINT_SCAN_COOLDOWN_SECONDS", 5),
    )
    cooldown = timedelta(seconds=cooldown_seconds)
    last_action_at = None
    if attendance is not None:
        last_action_at = attendance.check_out_at or attendance.check_in_at
    if last_action_at is not None and now - last_action_at < cooldown:
        current_status = "CHECKED_OUT" if attendance.check_out_at else "CHECKED_IN"
        return (
            _attendance_response(mapping, attendance, current_status, duplicate=True),
            "Duplicate scan ignored",
        )

    if attendance is not None and attendance.check_out_at is None:
        attendance.check_out_at = now
        attendance.save(update_fields=("check_out_at", "updated_at"))
        return (
            _attendance_response(mapping, attendance, "CHECKED_OUT"),
            "Check-out successful",
        )

    try:
        with transaction.atomic():
            attendance = Attendance.objects.create(
                employee=employee,
                branch=device.branch,
                device=device,
                attendance_date=attendance_date,
                check_in_at=now,
                source="BIOMETRIC",
            )
    except IntegrityError:
        open_attendance = (
            Attendance.objects.select_for_update()
            .filter(
                employee=employee,
                attendance_date=attendance_date,
                check_out_at__isnull=True,
            )
            .order_by("-check_in_at", "-pk")
            .first()
        )
        if open_attendance is None:
            raise
        return (
            _attendance_response(mapping, open_attendance, "CHECKED_IN", duplicate=True),
            "Duplicate scan ignored",
        )

    return _attendance_response(mapping, attendance, "CHECKED_IN"), "Check-in successful"
