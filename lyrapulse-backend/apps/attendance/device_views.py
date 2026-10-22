from django.db import IntegrityError, transaction
from django.utils import timezone
from rest_framework import status
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.devices.authentication import DeviceTokenAuthentication
from apps.devices.models import Device
from apps.devices.permissions import IsAuthenticatedDevice
from apps.employees.models import Employee
from apps.fingerprints.models import EmployeeFingerprint
from apps.common.responses import success_response

from .device_serializers import DeviceAttendanceEventSerializer
from .models import Attendance, AttendanceEvent, DeviceAttendanceEvent


class FingerprintAttendanceEventView(APIView):
    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsAuthenticatedDevice]

    def post(self, request):
        device = request.auth
        serializer = DeviceAttendanceEventSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        values = serializer.validated_data
        event_id = values["event_id"]
        prior = DeviceAttendanceEvent.objects.filter(device=device, event_id=event_id).first()
        if prior:
            payload = dict(prior.response)
            payload.setdefault("duplicate", True)
            return Response(payload, status=payload.get("http_status", status.HTTP_200_OK))

        try:
            with transaction.atomic():
                device = Device.objects.select_for_update().select_related("branch").get(pk=device.pk)
                if not device.is_active or not device.branch.is_active:
                    raise PermissionDenied("The device or its branch is inactive.")
                ledger = DeviceAttendanceEvent.objects.create(device=device, event_id=event_id,
                    fingerprint_slot=values["fingerprint_slot"], occurred_at=values["occurred_at"])
                mapping = EmployeeFingerprint.objects.filter(device=device, fingerprint_slot=values["fingerprint_slot"], is_active=True).select_related("employee__user", "employee__branch").first()
                if mapping is None:
                    raise NotFound("No active fingerprint mapping exists for this device and slot.")
                employee = Employee.objects.select_for_update().select_related("user", "branch").get(pk=mapping.employee_id)
                if not employee.is_active or not employee.user.is_active:
                    raise PermissionDenied("The employee is inactive.")
                if not employee.biometric_attendance_enabled:
                    raise PermissionDenied("Biometric attendance is not enabled for this employee.")
                if employee.branch_id != device.branch_id:
                    raise PermissionDenied("The employee and device are assigned to different branches.")

                happened = values["occurred_at"]
                if happened > timezone.now():
                    raise ValidationError({"occurred_at": "Device timestamp is ahead of the backend clock; synchronize the device clock."})
                open_session = Attendance.objects.select_for_update().filter(employee=employee, check_out_at__isnull=True).order_by("-check_in_at").first()
                latest = Attendance.objects.filter(employee=employee).order_by("-check_out_at", "-check_in_at").first()
                if open_session:
                    if happened <= open_session.check_in_at:
                        raise ValidationError({"occurred_at": "Event is older than the open session; check the device queue order."})
                    open_session.check_out_at = happened
                    open_session.save(update_fields=("check_out_at", "updated_at"))
                    attendance, action, result = open_session, AttendanceEvent.Action.CHECK_OUT, "CHECKED_OUT"
                else:
                    if latest and latest.check_out_at and happened <= latest.check_out_at:
                        raise ValidationError({"occurred_at": "Event is older than the latest attendance action."})
                    from django.utils import timezone as tz
                    attendance = Attendance.objects.create(employee=employee, branch=device.branch,
                        attendance_date=tz.localdate(happened), check_in_at=happened,
                        source=AttendanceEvent.Method.BIOMETRIC, device=device)
                    action, result = AttendanceEvent.Action.CHECK_IN, "CHECKED_IN"
                AttendanceEvent.objects.create(attendance=attendance, action=action,
                    method=AttendanceEvent.Method.BIOMETRIC, device=device, device_event=ledger, occurred_at=happened)
                ledger.attendance, ledger.outcome = attendance, result
                data = {"success": True, "message": "Fingerprint attendance recorded.", "data": {
                    "attendance_id": attendance.pk, "employee": {"id": employee.pk, "name": employee.user.full_name},
                    "status": result, "attendance_date": attendance.attendance_date.isoformat(),
                    "check_in_time": attendance.check_in_at.isoformat(), "check_out_time": attendance.check_out_at.isoformat() if attendance.check_out_at else None,
                }, "http_status": status.HTTP_200_OK}
                ledger.response = data
                ledger.save(update_fields=("attendance", "outcome", "response"))
                return Response(data, status=status.HTTP_200_OK)
        except IntegrityError:
            prior = DeviceAttendanceEvent.objects.filter(device=device, event_id=event_id).first()
            if prior:
                payload = dict(prior.response)
                payload.setdefault("duplicate", True)
                return Response(payload, status=payload.get("http_status", status.HTTP_200_OK))
            raise


class AdminManualAttendanceView(APIView):
    """Super Admin/Admin only; each action is based on the employee's locked open-session state."""
    from rest_framework.permissions import IsAuthenticated
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from apps.accounts.models import User
        from apps.accounts.scope import scope_queryset
        if request.user.role not in (User.Role.SUPERADMIN, User.Role.ADMIN):
            raise PermissionDenied("Only Super Admin and Admin users can record manual attendance.")
        employee_id = request.data.get("employee_id")
        try:
            employee_id = int(employee_id)
        except (TypeError, ValueError):
            raise ValidationError({"employee_id": "A valid employee ID is required."}) from None
        employee = scope_queryset(Employee.objects.select_related("user", "branch"), request.user, "branch").filter(pk=employee_id).first()
        if employee is None:
            raise NotFound("Employee not found in your scope.")
        if not employee.is_active or not employee.user.is_active or employee.branch_id is None or not employee.branch.is_active:
            raise PermissionDenied("The employee or assigned branch is inactive.")
        with transaction.atomic():
            employee = Employee.objects.select_for_update().get(pk=employee.pk)
            now = timezone.now()
            current = Attendance.objects.select_for_update().filter(employee=employee, check_out_at__isnull=True).order_by("-check_in_at").first()
            if current:
                if current.branch_id != employee.branch_id:
                    raise ValidationError({"employee_id": "Employee branch differs from the open session; resolve it before manual attendance."})
                current.check_out_at = now
                current.save(update_fields=("check_out_at", "updated_at"))
                action = AttendanceEvent.Action.CHECK_OUT
                attendance = current
            else:
                attendance = Attendance.objects.create(employee=employee, branch=employee.branch,
                    attendance_date=timezone.localdate(now), check_in_at=now,
                    source=AttendanceEvent.Method.MANUAL, created_by=request.user)
                action = AttendanceEvent.Action.CHECK_IN
            AttendanceEvent.objects.create(attendance=attendance, action=action,
                method=AttendanceEvent.Method.MANUAL, actor=request.user, occurred_at=now)
        return success_response({"attendance_id": attendance.pk, "action": action, "check_in_at": attendance.check_in_at,
            "check_out_at": attendance.check_out_at, "attendance_date": attendance.attendance_date}, "Manual attendance recorded.")
