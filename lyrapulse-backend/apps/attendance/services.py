"""Attendance business logic: location verification, employee/branch resolution, check-in and check-out.

Views only orchestrate HTTP; everything that decides whether an attendance action is allowed lives here so
check-in, check-out and the pre-camera "verify location" call share exactly the same rules.
"""
import logging
import math
from dataclasses import dataclass
from decimal import Decimal
from typing import Optional

from django.db import IntegrityError, transaction
from django.utils import timezone

from apps.employees.models import Employee

from .exceptions import AttendanceError
from .models import Attendance

logger = logging.getLogger(__name__)

EARTH_RADIUS_METERS = 6_371_008.8  # IUGG mean Earth radius
MAX_GPS_ACCURACY_METERS = 10_000  # sanity bound only; real GPS-quality policy can be added in verify_attendance_location

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


def verify_attendance_location(branch, latitude, longitude, accuracy=None):
    """Compare the device location with the branch attendance location.

    Raises AttendanceError for invalid input or an unconfigured branch (it never defaults to 0/0).
    Returns a LocationVerification; `verified` is True when the distance is within the branch radius.
    GPS-quality policies (e.g. rejecting very poor accuracy) can be added here later.
    """
    lat, lon, acc = validate_coordinates(latitude, longitude, accuracy)
    if not branch.has_attendance_location:
        raise AttendanceError("BRANCH_LOCATION_NOT_CONFIGURED", "Attendance location is not configured for this branch.", 409)
    distance = calculate_distance_meters(lat, lon, float(branch.latitude), float(branch.longitude))
    radius = branch.attendance_radius_meters
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


def check_in(*, employee, branch, latitude, longitude, accuracy, photo):
    _require_accuracy(accuracy)
    verification = verify_attendance_location(branch, latitude, longitude, accuracy)
    if not verification.verified:
        raise _outside_radius_error(verification)

    now = timezone.now()  # server time; any client-supplied time is ignored
    today = timezone.localdate(now)
    already_checked_in = AttendanceError("ALREADY_CHECKED_IN", "You have already checked in today.", 409)
    if _todays_attendance_exists(employee, today):  # fast path; the unique constraint is the real guard
        raise already_checked_in

    lat, lon, _ = validate_coordinates(latitude, longitude)
    attendance = Attendance(
        employee=employee, branch=branch, attendance_date=today, check_in_at=now,
        check_in_latitude=_decimal7(lat), check_in_longitude=_decimal7(lon),
        check_in_accuracy=verification.accuracy_meters, check_in_distance_meters=verification.distance_meters,
        check_in_location_verified=True, check_in_photo=photo,
    )
    try:
        with transaction.atomic():
            attendance.save(force_insert=True)  # writes the photo, then INSERTs
    except IntegrityError:
        _discard_file(attendance.check_in_photo)
        if Attendance.objects.filter(employee=employee, attendance_date=today).exists():
            raise already_checked_in from None  # lost a race with a concurrent request
        raise
    except Exception:
        _discard_file(attendance.check_in_photo)
        raise
    return attendance


def check_out(*, employee, branch, latitude, longitude, accuracy, photo):
    _require_accuracy(accuracy)
    verification = verify_attendance_location(branch, latitude, longitude, accuracy)
    if not verification.verified:
        raise _outside_radius_error(verification)

    now = timezone.now()
    today = timezone.localdate(now)
    lat, lon, _ = validate_coordinates(latitude, longitude)
    attendance = None
    try:
        with transaction.atomic():
            # Row lock serialises concurrent check-out taps: the second one sees check_out_at already set.
            attendance = Attendance.objects.select_for_update().filter(employee=employee, attendance_date=today).first()
            if attendance is None:
                raise AttendanceError("NOT_CHECKED_IN", "You have not checked in today.", 409)
            if attendance.check_out_at is not None:
                raise AttendanceError("ALREADY_CHECKED_OUT", "You have already checked out today.", 409)
            if attendance.branch_id != branch.pk:
                raise AttendanceError("BRANCH_MISMATCH", "Your branch changed since check-in. Please contact HR.", 409)
            attendance.check_out_at = now
            attendance.check_out_latitude = _decimal7(lat)
            attendance.check_out_longitude = _decimal7(lon)
            attendance.check_out_accuracy = verification.accuracy_meters
            attendance.check_out_distance_meters = verification.distance_meters
            attendance.check_out_location_verified = True
            attendance.check_out_photo = photo
            attendance.save(update_fields=CHECK_OUT_FIELDS)
    except AttendanceError:
        raise
    except Exception:
        if attendance is not None:
            _discard_file(attendance.check_out_photo)
        raise
    return attendance


def today_state(employee):
    today = timezone.localdate()
    attendance = Attendance.objects.filter(employee=employee, attendance_date=today).first()
    if attendance is None:
        return {"attendance_date": today, "state": Attendance.State.NOT_CHECKED_IN.value, "check_in_at": None, "check_out_at": None}
    return {
        "attendance_date": attendance.attendance_date, "state": attendance.state.value,
        "check_in_at": attendance.check_in_at, "check_out_at": attendance.check_out_at,
    }
