from django.conf import settings
from django.db import IntegrityError, transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.authentication import SessionAuthentication
from rest_framework.exceptions import APIException, ValidationError
from rest_framework.generics import GenericAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.accounts.permissions import IsHROrAdmin
from apps.common.responses import success_response
from apps.devices.authentication import DeviceTokenAuthentication
from apps.devices.models import Device
from apps.devices.permissions import IsAuthenticatedDevice
from apps.employees.models import Employee

from .models import EmployeeFingerprint, FingerprintEnrollment
from .serializers import (
    DeviceEnrollmentResultSerializer,
    FingerprintEnrollmentStartSerializer,
    FingerprintEnrollmentStatusSerializer,
)


class EnrollmentConflict(APIException):
    status_code = status.HTTP_409_CONFLICT
    default_detail = "The enrollment can no longer be completed."
    default_code = "enrollment_conflict"


class EmployeeFingerprintEnrollmentStartView(GenericAPIView):
    permission_classes = [IsAuthenticated, IsHROrAdmin]
    serializer_class = FingerprintEnrollmentStartSerializer

    def post(self, request, employee_id):
        employee = get_object_or_404(
            Employee.objects.select_related("branch"),
            pk=employee_id,
        )
        if not employee.is_active or not employee.user.is_active:
            raise ValidationError({"employee_id": "The employee is inactive."})
        if employee.branch_id is None or not employee.branch.is_active:
            raise ValidationError({"employee_id": "The employee must belong to an active branch."})

        serializer = self.get_serializer(
            data=request.data,
            context={"request": request, "employee": employee},
        )
        serializer.is_valid(raise_exception=True)
        try:
            with transaction.atomic():
                enrollment = serializer.save()
        except IntegrityError as exc:
            raise EnrollmentConflict("This device already has an active enrollment.") from exc

        data = {
            "enrollment_id": str(enrollment.id),
            "employee_id": employee.id,
            "device_id": enrollment.device.device_id,
            "finger": enrollment.finger,
            "status": enrollment.status,
            "expires_at": enrollment.expires_at,
        }
        return success_response(data, "Fingerprint enrollment started", status.HTTP_201_CREATED)


class EmployeeFingerprintEnrollmentStatusView(GenericAPIView):
    permission_classes = [IsAuthenticated, IsHROrAdmin]
    serializer_class = FingerprintEnrollmentStatusSerializer

    def get(self, request, employee_id, enrollment_id):
        enrollment = get_object_or_404(
            FingerprintEnrollment.objects.select_related("device"),
            pk=enrollment_id,
            employee_id=employee_id,
        )
        if enrollment.status in FingerprintEnrollment.ACTIVE_STATUSES and enrollment.expires_at <= timezone.now():
            FingerprintEnrollment.objects.filter(
                pk=enrollment.pk,
                status__in=FingerprintEnrollment.ACTIVE_STATUSES,
            ).update(
                status=FingerprintEnrollment.Status.EXPIRED,
                completed_at=timezone.now(),
                failure_reason="EXPIRED",
            )
            enrollment.refresh_from_db()
        return success_response(self.get_serializer(enrollment).data, "Fingerprint enrollment status retrieved")


class DeviceEnrollmentPendingView(GenericAPIView):
    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsAuthenticatedDevice]

    def get(self, request, device_id):
        device = request.auth
        if device.device_id != device_id:
            raise EnrollmentConflict("The credential is not authorized for this device.")

        now = timezone.now()
        with transaction.atomic():
            enrollment = (
                FingerprintEnrollment.objects.select_for_update()
                .select_related("employee")
                .filter(device=device, status__in=FingerprintEnrollment.ACTIVE_STATUSES)
                .order_by("created_at")
                .first()
            )
            if enrollment is None:
                return success_response(None, "No pending enrollment")
            if enrollment.expires_at <= now:
                enrollment.status = FingerprintEnrollment.Status.EXPIRED
                enrollment.completed_at = now
                enrollment.failure_reason = "EXPIRED"
                enrollment.save(update_fields=("status", "completed_at", "failure_reason", "updated_at"))
                return success_response(None, "No pending enrollment")
            if not enrollment.employee.is_active or not enrollment.employee.user.is_active:
                enrollment.status = FingerprintEnrollment.Status.FAILED
                enrollment.completed_at = now
                enrollment.failure_reason = "EMPLOYEE_INACTIVE"
                enrollment.save(update_fields=("status", "completed_at", "failure_reason", "updated_at"))
                return success_response(None, "No pending enrollment")
            if enrollment.employee.branch_id != device.branch_id or not device.branch.is_active:
                enrollment.status = FingerprintEnrollment.Status.FAILED
                enrollment.completed_at = now
                enrollment.failure_reason = "BRANCH_MISMATCH"
                enrollment.save(update_fields=("status", "completed_at", "failure_reason", "updated_at"))
                return success_response(None, "No pending enrollment")

            if enrollment.status == FingerprintEnrollment.Status.PENDING:
                enrollment.status = FingerprintEnrollment.Status.WAITING_FOR_FINGER
                enrollment.started_at = now
                enrollment.save(update_fields=("status", "started_at", "updated_at"))

        command = {
            "enrollment_id": str(enrollment.id),
            "employee_id": enrollment.employee_id,
            "action": "ENROLL_FINGERPRINT",
            "finger": enrollment.finger,
        }
        return success_response(command, "Enrollment command retrieved")


class DeviceEnrollmentResultView(GenericAPIView):
    authentication_classes = [DeviceTokenAuthentication]
    permission_classes = [IsAuthenticatedDevice]
    serializer_class = DeviceEnrollmentResultSerializer

    def post(self, request, device_id, enrollment_id):
        device = request.auth
        if device.device_id != device_id:
            raise EnrollmentConflict("The credential is not authorized for this device.")

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        now = timezone.now()
        conflict_message = None
        already_recorded = False

        try:
            with transaction.atomic():
                enrollment = (
                    FingerprintEnrollment.objects.select_for_update()
                    .select_related("employee")
                    .filter(pk=enrollment_id, device=device)
                    .first()
                )
                if enrollment is None:
                    raise EnrollmentConflict("Enrollment does not exist for this device.")
                if enrollment.status not in FingerprintEnrollment.ACTIVE_STATUSES:
                    already_recorded = (
                        enrollment.status == FingerprintEnrollment.Status.SUCCESS
                        and data["status"] == FingerprintEnrollment.Status.SUCCESS
                        and enrollment.actual_slot == data.get("fingerprint_slot")
                        and EmployeeFingerprint.objects.filter(
                            employee=enrollment.employee,
                            device=device,
                            fingerprint_slot=enrollment.actual_slot,
                            is_active=True,
                        ).exists()
                    )
                    if not already_recorded:
                        raise EnrollmentConflict("Enrollment is already complete.")
                if already_recorded:
                    pass
                elif enrollment.expires_at <= now:
                    enrollment.status = FingerprintEnrollment.Status.EXPIRED
                    enrollment.completed_at = now
                    enrollment.failure_reason = "EXPIRED"
                    enrollment.save(update_fields=("status", "completed_at", "failure_reason", "updated_at"))
                    conflict_message = "Enrollment has expired."
                elif not device.is_active or not enrollment.employee.is_active or not enrollment.employee.user.is_active:
                    enrollment.status = FingerprintEnrollment.Status.FAILED
                    enrollment.completed_at = now
                    enrollment.failure_reason = "DEVICE_OR_EMPLOYEE_INACTIVE"
                    enrollment.save(update_fields=("status", "completed_at", "failure_reason", "updated_at"))
                    conflict_message = "The device or employee is inactive."
                elif enrollment.employee.branch_id != device.branch_id or not device.branch.is_active:
                    enrollment.status = FingerprintEnrollment.Status.FAILED
                    enrollment.completed_at = now
                    enrollment.failure_reason = "BRANCH_MISMATCH"
                    enrollment.save(update_fields=("status", "completed_at", "failure_reason", "updated_at"))
                    conflict_message = "The device and employee are no longer in the same active branch."
                else:
                    new_status = data["status"]
                    if new_status == FingerprintEnrollment.Status.WAITING_FOR_SECOND_SCAN:
                        if enrollment.status != FingerprintEnrollment.Status.WAITING_FOR_FINGER:
                            raise EnrollmentConflict("Invalid enrollment state transition.")
                        enrollment.status = new_status
                        enrollment.save(update_fields=("status", "updated_at"))
                    elif new_status == FingerprintEnrollment.Status.PROCESSING:
                        if enrollment.status != FingerprintEnrollment.Status.WAITING_FOR_SECOND_SCAN:
                            raise EnrollmentConflict("Invalid enrollment state transition.")
                        enrollment.status = new_status
                        enrollment.save(update_fields=("status", "updated_at"))
                    elif new_status == FingerprintEnrollment.Status.FAILED:
                        enrollment.status = new_status
                        enrollment.failure_reason = data["error_code"]
                        enrollment.completed_at = now
                        enrollment.save(update_fields=("status", "failure_reason", "completed_at", "updated_at"))
                    else:
                        if enrollment.status != FingerprintEnrollment.Status.PROCESSING:
                            raise EnrollmentConflict("Enrollment must be processing before success is reported.")
                        slot = data["fingerprint_slot"]
                        if slot >= getattr(settings, "R307_MAX_TEMPLATE_COUNT", 1000):
                            raise ValidationError({"fingerprint_slot": "The reported slot exceeds sensor capacity."})
                        if EmployeeFingerprint.objects.filter(
                            device=device,
                            fingerprint_slot=slot,
                            is_active=True,
                        ).exists():
                            raise EnrollmentConflict("The reported sensor slot is already mapped.")
                        if EmployeeFingerprint.objects.filter(
                            employee=enrollment.employee,
                            device=device,
                            finger=enrollment.finger,
                            is_active=True,
                        ).exists():
                            raise EnrollmentConflict("This employee finger is already mapped on this device.")

                        EmployeeFingerprint.objects.create(
                            employee=enrollment.employee,
                            device=device,
                            fingerprint_slot=slot,
                            finger=enrollment.finger,
                        )
                        enrollment.status = FingerprintEnrollment.Status.SUCCESS
                        enrollment.actual_slot = slot
                        enrollment.completed_at = now
                        enrollment.failure_reason = ""
                        enrollment.save(
                            update_fields=(
                                "status",
                                "actual_slot",
                                "completed_at",
                                "failure_reason",
                                "updated_at",
                            )
                        )
        except IntegrityError as exc:
            raise EnrollmentConflict("The fingerprint slot or employee finger is already mapped.") from exc

        if conflict_message:
            raise EnrollmentConflict(conflict_message)

        return success_response(
            {
                "enrollment_id": str(enrollment.id),
                "status": enrollment.status,
                "fingerprint_slot": enrollment.actual_slot,
            },
            "Enrollment result recorded",
        )
