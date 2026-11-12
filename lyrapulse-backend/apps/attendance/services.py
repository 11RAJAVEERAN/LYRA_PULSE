"""Attendance business logic: location verification, employee/branch resolution, check-in and check-out.

Views only orchestrate HTTP; everything that decides whether an attendance action is allowed lives here so
check-in, check-out and the pre-camera "verify location" call share exactly the same rules.
"""
import logging
import math
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Optional

from django.db import IntegrityError, OperationalError, connection, transaction
from django.utils import timezone

from apps.employees.models import Employee

from .exceptions import AttendanceError
from .models import Attendance, AttendanceEvent, MobileAttendanceRequest

logger = logging.getLogger(__name__)

EARTH_RADIUS_METERS = 6_371_008.8  # IUGG mean Earth radius
MAX_GPS_ACCURACY_METERS = 10_000
MAX_LOCATION_FIX_AGE = timedelta(seconds=120)
MAX_LOCATION_FUTURE_SKEW = timedelta(seconds=30)

CHECK_OUT_FIELDS = [
    "check_out_at", "check_out_latitude", "check_out_longitude", "check_out_accuracy",
    "check_out_distance_meters", "check_out_location_verified", "check_out_photo", "updated_at",
]


# ----------------------------------------------------------------------------------------------------------------
# Location
# ----------------------------------------------------------------------------------------------------------------
def calculate_distance_meters(lat1, lon1, lat2, lon2):
    """Great-circle (haversine) distance in meters. Dependency-free and accurate at branch-radius scale."""
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)
    a = math.sin(d_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    return 2 * EARTH_RADIUS_METERS * math.asin(min(1.0, math.sqrt(a)))


@dataclass(frozen=True)
class LocationVerification:
    verified: bool
    distance_meters: float
    allowed_radius_meters: int
    accuracy_meters: Optional[float] = None


def _finite_float(value, error):
    try:
        number = float(value)
    except (TypeError, ValueError):
        raise error from None
    if not math.isfinite(number):
        raise error
    return number


def validate_coordinates(latitude, longitude, accuracy=None):
    """Return (latitude, longitude, accuracy) as floats or raise AttendanceError. Never treats bad input as valid."""
    lat = _finite_float(latitude, AttendanceError("INVALID_LATITUDE", "Latitude must be a number between -90 and 90."))
    lon = _finite_float(longitude, AttendanceError("INVALID_LONGITUDE", "Longitude must be a number between -180 and 180."))
    if not -90 <= lat <= 90:
        raise AttendanceError("INVALID_LATITUDE", "Latitude must be a number between -90 and 90.")
    if not -180 <= lon <= 180:
        raise AttendanceError("INVALID_LONGITUDE", "Longitude must be a number between -180 and 180.")
    acc = None
    if accuracy is not None:
        error = AttendanceError("INVALID_GPS_ACCURACY", f"GPS accuracy must be a number between 0 and {MAX_GPS_ACCURACY_METERS} meters.")
        acc = _finite_float(accuracy, error)
        if not 0 <= acc <= MAX_GPS_ACCURACY_METERS:
            raise error
    return lat, lon, acc


def _validate_location_timestamp(location_timestamp, now=None):
    if not isinstance(location_timestamp, datetime) or timezone.is_naive(location_timestamp):
        raise AttendanceError("INVALID_LOCATION_TIMESTAMP", "A timezone-aware location timestamp is required.")
    now = now or timezone.now()
    age = now - location_timestamp
    if age > MAX_LOCATION_FIX_AGE:
        raise AttendanceError("STALE_LOCATION", "The location fix must be no more than 120 seconds old.")
    if age < -MAX_LOCATION_FUTURE_SKEW:
        raise AttendanceError("FUTURE_LOCATION", "The location fix cannot be more than 30 seconds in the future.")


def verify_attendance_location(branch, latitude, longitude, accuracy=None, location_timestamp=None):
    """Compare the device location with the branch attendance location.

    Raises AttendanceError for invalid input or an unconfigured branch (it never defaults to 0/0).
    Returns a LocationVerification; `verified` is True when the distance is within the branch radius.
    """
    if accuracy is None:
        raise AttendanceError("INVALID_GPS_ACCURACY", "GPS accuracy is required.")
    # Timestamp checks apply to clients that send the additive field. Omitting it
    # remains accepted for compatibility with already released A mobile clients.
    if location_timestamp is not None:
        _validate_location_timestamp(location_timestamp)
    lat, lon, acc = validate_coordinates(latitude, longitude, accuracy)
    if not branch.has_attendance_location:
        raise AttendanceError("BRANCH_LOCATION_NOT_CONFIGURED", "Attendance location is not configured for this branch.", 409)
    branch_lat, branch_lon, _ = validate_coordinates(branch.latitude, branch.longitude)
    radius = branch.attendance_radius_meters
    if location_timestamp is not None and acc > radius:
        raise AttendanceError(
            "GPS_ACCURACY_EXCEEDS_RADIUS",
            "GPS accuracy must be no worse than the configured branch attendance radius.",
        )
    distance = calculate_distance_meters(lat, lon, branch_lat, branch_lon)
    return LocationVerification(
        verified=distance <= radius,
        distance_meters=round(distance, 2),
        allowed_radius_meters=radius,
        accuracy_meters=None if acc is None else round(acc, 2),
    )


def _outside_radius_error(verification):
    return AttendanceError(
        "OUTSIDE_ATTENDANCE_RADIUS", "You are outside the allowed attendance area.", 403,
        distance_meters=verification.distance_meters, allowed_radius_meters=verification.allowed_radius_meters,
    )


# ----------------------------------------------------------------------------------------------------------------
# Who is the employee, and which branch is valid for them (always decided by the server)
# ----------------------------------------------------------------------------------------------------------------
def resolve_employee(user):
    employee = Employee.objects.select_related("branch__organization").filter(user=user).first()
    if employee is None or not employee.is_active or not user.is_active:
        raise AttendanceError("EMPLOYEE_PROFILE_NOT_FOUND", "Active employee profile not found.", 403)
    return employee


def resolve_branch(employee):
    """An employee has one assigned branch. It must be active and, if it belongs to an organization, that must be active."""
    branch = employee.branch
    if branch is None or not branch.is_active or (branch.organization_id and not branch.organization.is_active):
        raise AttendanceError("NO_VALID_BRANCH", "You are not assigned to an active branch.", 403)
    return branch


# ----------------------------------------------------------------------------------------------------------------
# Check-in / check-out
# ----------------------------------------------------------------------------------------------------------------
def _decimal7(value):
    return Decimal(f"{value:.7f}")


def _require_accuracy(accuracy):
    if accuracy is None:
        raise AttendanceError("INVALID_GPS_ACCURACY", "GPS accuracy is required.")


def _discard_file(field_file):
    """Remove a photo that was written to storage by a save that did not complete."""
    if field_file and getattr(field_file, "_committed", False):
        try:
            field_file.storage.delete(field_file.name)
        except Exception:  # never mask the original error
            logger.exception("Could not remove orphaned attendance photo")


def _todays_attendance_exists(employee, today):
    return Attendance.objects.filter(employee=employee, attendance_date=today).exists()


def _is_open_attendance_conflict(error):
    cause = error.__cause__
    constraint = getattr(getattr(cause, "diag", None), "constraint_name", None)
    if constraint == "one_open_attendance_per_employee_day":
        return True
    message = str(cause or error).lower()
    return "one_open_attendance_per_employee_day" in message or (
        "attendance_attendance.employee_id" in message and "attendance_attendance.attendance_date" in message
    )


@transaction.atomic
def check_in(
    *, employee, branch, latitude=None, longitude=None, accuracy=None, location_timestamp=None, photo=None,
    location_required=True,
):
    employee = Employee.objects.select_for_update().get(pk=employee.pk)
    verification = None
    if location_required:
        _require_accuracy(accuracy)
        verification = verify_attendance_location(branch, latitude, longitude, accuracy, location_timestamp)
        if not verification.verified:
            raise _outside_radius_error(verification)

    now = timezone.now()  # server time; any client-supplied time is ignored
    today = timezone.localdate(now)
    already_checked_in = AttendanceError("ALREADY_CHECKED_IN", "You already have an open attendance session.", 409)
    if _todays_attendance_exists(employee, today) and Attendance.objects.filter(
        employee=employee, attendance_date=today, check_out_at__isnull=True
    ).exists():
        raise already_checked_in

    lat, lon, _ = validate_coordinates(latitude, longitude) if location_required else (None, None, None)
    attendance = Attendance(
        employee=employee, branch=branch, attendance_date=today, check_in_at=now,
        check_in_latitude=_decimal7(lat) if lat is not None else None,
        check_in_longitude=_decimal7(lon) if lon is not None else None,
        check_in_accuracy=verification.accuracy_meters if verification else None,
        check_in_distance_meters=verification.distance_meters if verification else None,
        check_in_location_verified=True if verification else None, check_in_photo=photo or "",
    )
    try:
        with transaction.atomic():
            attendance.save(force_insert=True)  # writes the photo, then INSERTs
            AttendanceEvent.objects.create(attendance=attendance, action=AttendanceEvent.Action.CHECK_IN, method=AttendanceEvent.Method.MOBILE_GPS, occurred_at=now)
    except IntegrityError as error:
        _discard_file(attendance.check_in_photo)
        # Row locks serialize on databases that support them; this partial unique index is
        # the final guard for backends where select_for_update is a no-op (including SQLite).
        # Convert the expected race into the same conflict response as the pre-check.
        if _is_open_attendance_conflict(error):
            raise already_checked_in from error
        raise
    except Exception:
        _discard_file(attendance.check_in_photo)
        raise
    return attendance


@transaction.atomic
def check_out(
    *, employee, branch, latitude=None, longitude=None, accuracy=None, location_timestamp=None, photo=None,
    location_required=True,
):
    employee = Employee.objects.select_for_update().get(pk=employee.pk)
    verification = None
    if location_required:
        _require_accuracy(accuracy)
        verification = verify_attendance_location(branch, latitude, longitude, accuracy, location_timestamp)
        if not verification.verified:
            raise _outside_radius_error(verification)

    now = timezone.now()
    today = timezone.localdate(now)
    lat, lon, _ = validate_coordinates(latitude, longitude) if location_required else (None, None, None)
    attendance = None
    try:
        with transaction.atomic():
            # Row lock serialises concurrent check-out taps: the second one sees check_out_at already set.
            attendance = Attendance.objects.select_for_update().filter(
                employee=employee, attendance_date=today, check_out_at__isnull=True
            ).order_by("-check_in_at").first()
            if attendance is None:
                if Attendance.objects.filter(employee=employee, attendance_date=today, check_out_at__isnull=False).exists():
                    raise AttendanceError("ALREADY_CHECKED_OUT", "There is no open session to check out.", 409)
                raise AttendanceError("NOT_CHECKED_IN", "You do not have an open attendance session.", 409)
            if attendance.branch_id != branch.pk:
                raise AttendanceError("BRANCH_MISMATCH", "Your branch changed since check-in. Please contact HR.", 409)
            attendance.check_out_at = now
            attendance.check_out_latitude = _decimal7(lat) if lat is not None else None
            attendance.check_out_longitude = _decimal7(lon) if lon is not None else None
            attendance.check_out_accuracy = verification.accuracy_meters if verification else None
            attendance.check_out_distance_meters = verification.distance_meters if verification else None
            attendance.check_out_location_verified = True if verification else None
            attendance.check_out_photo = photo or ""
            attendance.save(update_fields=CHECK_OUT_FIELDS)
            AttendanceEvent.objects.create(attendance=attendance, action=AttendanceEvent.Action.CHECK_OUT, method=AttendanceEvent.Method.MOBILE_GPS, occurred_at=now)
    except AttendanceError:
        raise
    except Exception:
        if attendance is not None:
            _discard_file(attendance.check_out_photo)
        raise
    return attendance


@dataclass(frozen=True)
class MobilePunchResult:
    status_code: int
    body: dict
    replayed: bool = False


def idempotent_mobile_punch(*, key, employee, action, payload_fingerprint, perform, serialize_result, success_message, success_status):
    for attempt in range(10):
        try:
            return _idempotent_mobile_punch_once(
                key=key,
                employee=employee,
                action=action,
                payload_fingerprint=payload_fingerprint,
                perform=perform,
                serialize_result=serialize_result,
                success_message=success_message,
                success_status=success_status,
            )
        except OperationalError as error:
            if connection.vendor != "sqlite" or "locked" not in str(error).lower() or attempt == 9:
                raise
            time.sleep(0.02 * (attempt + 1))


@transaction.atomic
def _idempotent_mobile_punch_once(*, key, employee, action, payload_fingerprint, perform, serialize_result, success_message, success_status):
    record, created = MobileAttendanceRequest.objects.get_or_create(
        key=key,
        defaults={
            "employee": employee,
            "action": action,
            "payload_fingerprint": payload_fingerprint,
        },
    )
    if not created:
        record = MobileAttendanceRequest.objects.select_for_update().get(pk=record.pk)
        if (
            record.employee_id != employee.pk
            or record.action != action
            or record.payload_fingerprint != payload_fingerprint
        ):
            raise AttendanceError(
                "IDEMPOTENCY_KEY_REUSED",
                "This idempotency key was already used for a different request.",
                409,
            )
        if record.http_status is None or not record.response:
            raise AttendanceError(
                "IDEMPOTENCY_REQUEST_IN_PROGRESS",
                "A request with this idempotency key is still being processed.",
                409,
            )
        if record.outcome == MobileAttendanceRequest.Outcome.PENDING:
            raise AttendanceError(
                "IDEMPOTENCY_REQUEST_IN_PROGRESS",
                "A request with this idempotency key is still being processed.",
                409,
            )
        return MobilePunchResult(record.http_status, record.response, replayed=True)

    try:
        attendance = perform()
    except AttendanceError as error:
        body = {"success": False, "message": error.message, "errors": {"code": error.code, **error.extra}}
        record.outcome = MobileAttendanceRequest.Outcome.REJECTED
        record.http_status = error.status_code
        record.response = body
        record.save(update_fields=("outcome", "http_status", "response"))
        return MobilePunchResult(error.status_code, body)

    body = {
        "success": True,
        "message": success_message,
        "data": {"attendance": serialize_result(attendance)},
    }
    record.outcome = MobileAttendanceRequest.Outcome.SUCCEEDED
    record.http_status = success_status
    record.response = body
    record.attendance = attendance
    record.save(update_fields=("outcome", "http_status", "response", "attendance"))
    return MobilePunchResult(success_status, body)


def today_state(employee):
    today = timezone.localdate()
    sessions = list(Attendance.objects.filter(employee=employee, attendance_date=today).order_by("check_in_at"))
    open_session = next((row for row in reversed(sessions) if row.check_out_at is None), None)
    attendance = open_session or (sessions[-1] if sessions else None)
    if attendance is None:
        return {"attendance_date": today, "state": Attendance.State.NOT_CHECKED_IN.value, "check_in_at": None, "check_out_at": None, "sessions": []}
    return {
        "attendance_date": attendance.attendance_date, "state": attendance.state.value,
        "check_in_at": attendance.check_in_at, "check_out_at": attendance.check_out_at,
        "sessions": [{"id": row.pk, "check_in_at": row.check_in_at, "check_out_at": row.check_out_at, "source": row.source} for row in sessions],
    }
