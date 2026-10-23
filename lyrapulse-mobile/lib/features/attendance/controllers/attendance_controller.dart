import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/location_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/repositories/attendance_repository.dart';
import '../../auth/controllers/auth_controller.dart';

enum LocationStatus { idle, checking, verified, outside, failed }

/// Owns today's attendance (always from the backend) and the Check In /
/// Check Out flow. It follows [AuthController.employee]: attendance is loaded
/// when an employee signs in and cleared when they sign out.
class AttendanceController extends GetxController {
  final _repository = Get.find<AttendanceRepository>();
  final _location = Get.find<LocationService>();
  final _auth = Get.find<AuthController>();

  // ---------------------------------------------------------------------------
  // TODAY (source of truth: GET attendance/today/)
  // ---------------------------------------------------------------------------
  final today = Rxn<TodayAttendance>();
  final isLoadingToday = false.obs;
  final todayError = RxnString();

  /// Ticks once a second while the employee is checked in; only drives the
  /// on-screen timer. The start time is always the backend `check_in_at`.
  final _now = DateTime.now().obs;
  Timer? _ticker;
  Worker? _employeeWorker;

  // ---------------------------------------------------------------------------
  // CHECK IN / CHECK OUT FLOW
  // ---------------------------------------------------------------------------
  final action = AttendanceAction.checkIn.obs;
  final locationStatus = LocationStatus.idle.obs;
  final locationMessage = ''.obs;
  final locationFailure = Rxn<LocationFailureType>();
  final position = Rxn<DevicePosition>();
  final verification = Rxn<LocationVerification>();
  final photoPath = RxnString();
  final isSubmitting = false.obs;
  final submitError = RxnString();
  final result = Rxn<AttendanceActionResult>();

  bool get isCheckIn => action.value == AttendanceAction.checkIn;
  bool get mobileAttendanceEnabled => _auth.employee.value?.mobileAttendanceEnabled ?? false;
  bool get photoRequired => _auth.employee.value?.photoAttendanceEnabled ?? false;
  bool get locationRequired => _auth.employee.value?.locationAttendanceEnabled ?? false;

  AttendanceState? get state => today.value?.state;
  bool get canCheckIn => state == AttendanceState.notCheckedIn || state == AttendanceState.checkedOut;
  bool get canCheckOut => state == AttendanceState.checkedIn;

  /// Worked time derived from the backend timestamps. Reactive: read inside Obx.
  Duration get workingDuration {
    final current = today.value;
    if (current == null) return Duration.zero;
    if (current.sessions.isEmpty) {
      final start = current.checkInAt;
      if (start == null) return Duration.zero;
      final difference = (current.checkOutAt ?? _now.value).difference(start);
      return difference.isNegative ? Duration.zero : difference;
    }
    var total = Duration.zero;
    for (final session in current.sessions) {
      final start = session.checkInAt;
      if (start == null) continue;
      final difference = (session.checkOutAt ?? _now.value).difference(start);
      if (!difference.isNegative) total += difference;
    }
    return total;
  }

  String get statusLabel {
    switch (state) {
      case AttendanceState.checkedIn:
        return 'Checked in';
      case AttendanceState.checkedOut:
        return 'Completed';
      case AttendanceState.notCheckedIn:
        return 'Not checked in';
      case null:
        return isLoadingToday.value ? 'Loading…' : 'Unavailable';
    }
  }

  @override
  void onInit() {
    super.onInit();
    _employeeWorker = ever<EmployeeModel?>(_auth.employee, (employee) {
      if (employee == null) {
        _reset();
      } else {
        unawaited(refreshToday());
      }
    });
    if (_auth.employee.value != null) unawaited(refreshToday());
  }

  Future<void> refreshToday() async {
    if (isLoadingToday.value) return;
    isLoadingToday.value = true;
    todayError.value = null;
    try {
      _applyToday(await _repository.fetchToday());
    } on AttendanceFailure catch (failure) {
      todayError.value = failure.message;
    } finally {
      isLoadingToday.value = false;
    }
  }

  void _applyToday(TodayAttendance value) {
    today.value = value;
    _syncTicker();
  }

  void _syncTicker() {
    if (state == AttendanceState.checkedIn) {
      _now.value = DateTime.now();
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _now.value = DateTime.now());
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  // ---------------------------------------------------------------------------
  // FLOW
  // ---------------------------------------------------------------------------

  /// Entry point from Home. Only starts when today's backend state allows it.
  Future<void> startFlow(AttendanceAction requested) async {
    if (isSubmitting.value) return;
    if (!mobileAttendanceEnabled) {
      AppSnackbar.show(_auth.employee.value?.biometricAttendanceEnabled == true
          ? 'Mobile attendance is disabled. Use your assigned biometric device.'
          : 'Mobile attendance is not enabled for your account. Contact your administrator.');
      return;
    }
    if (state == null) {
      AppSnackbar.show('Attendance status is not loaded yet. Please try again.');
      unawaited(refreshToday());
      return;
    }
    if (requested == AttendanceAction.checkIn && !canCheckIn) {
      AppSnackbar.show(state == AttendanceState.checkedIn
          ? 'You have already checked in today.'
          : 'Today\'s attendance is already completed.');
      return;
    }
    if (requested == AttendanceAction.checkOut && !canCheckOut) {
      AppSnackbar.show(state == AttendanceState.checkedOut
          ? 'You have already checked out today.'
          : 'Check in before you check out.');
      return;
    }
    await _resetFlow();
    action.value = requested;
    if (locationRequired) {
      Get.toNamed(AppRoutes.attendanceLocation);
      unawaited(verifyLocation());
    } else if (photoRequired) {
      Get.toNamed(AppRoutes.attendanceCamera);
    } else {
      unawaited(submit());
    }
  }

  /// Fresh GPS fix, then the real `verify-location/` call (pre-camera check only;
  /// check-in / check-out verify the location again on the server).
  Future<void> verifyLocation() async {
    if (locationStatus.value == LocationStatus.checking) return;
    locationStatus.value = LocationStatus.checking;
    locationMessage.value = '';
    locationFailure.value = null;
    position.value = null;
    verification.value = null;
    try {
      final fix = await _location.getCurrentPosition();
      position.value = fix;
      final checked = await _repository.verifyLocation(
        latitude: fix.latitude,
        longitude: fix.longitude,
        accuracy: fix.accuracy,
      );
      verification.value = checked;
      if (checked.verified) {
        locationStatus.value = LocationStatus.verified;
      } else {
        locationStatus.value = LocationStatus.outside;
        locationMessage.value = 'You are outside the allowed attendance area.';
      }
    } on LocationFailure catch (failure) {
      locationFailure.value = failure.type;
      locationMessage.value = failure.message;
      locationStatus.value = LocationStatus.failed;
    } on AttendanceFailure catch (failure) {
      locationMessage.value = failure.message;
      locationStatus.value = LocationStatus.failed;
    }
  }

  Future<void> openLocationSettings() async {
    if (locationFailure.value == LocationFailureType.deniedForever) {
      await _location.openAppSettings();
    } else {
      await _location.openLocationSettings();
    }
  }

  Future<void> openAppSettings() => _location.openAppSettings();

  void continueToCamera() {
    if (locationStatus.value != LocationStatus.verified) return;
    Get.toNamed(photoRequired ? AppRoutes.attendanceCamera : AppRoutes.attendanceConfirm);
  }

  void setPhoto(String path) {
    unawaited(_deletePhotoFile(photoPath.value));
    photoPath.value = path;
  }

  /// Drops the captured photo and removes its temporary file.
  Future<void> discardPhoto() async {
    final path = photoPath.value;
    photoPath.value = null;
    await _deletePhotoFile(path);
  }

  Future<void> retakePhoto() async {
    await discardPhoto();
    Get.back();
  }

  /// Uploads the photo with the verified location to the real Django API,
  /// then re-reads today's state from the backend.
  Future<void> submit() async {
    if (isSubmitting.value) return;
    final fix = position.value;
    final path = photoPath.value;
    if ((locationRequired && (fix == null || verification.value?.verified != true)) ||
        (photoRequired && path == null)) {
      AppSnackbar.show(locationRequired
          ? (photoRequired ? 'Verify your location and take a photo first.' : 'Verify your location first.')
          : 'Take your attendance photo first.');
      return;
    }
    isSubmitting.value = true;
    submitError.value = null;
    try {
      final done = isCheckIn
          ? await _repository.checkIn(
              latitude: fix?.latitude, longitude: fix?.longitude, accuracy: fix?.accuracy, photoPath: path)
          : await _repository.checkOut(
              latitude: fix?.latitude, longitude: fix?.longitude, accuracy: fix?.accuracy, photoPath: path);
      result.value = done;
      await discardPhoto();
      // Backend is the source of truth: re-fetch rather than patching local state.
      // (Clear the loading flag so a refresh already in flight cannot swallow this one.)
      isLoadingToday.value = false;
      await refreshToday();
      Get.offNamedUntil(AppRoutes.attendanceSuccess, (route) => route.settings.name == AppRoutes.home);
    } on AttendanceFailure catch (failure) {
      if (_isStateConflict(failure.code)) {
        // Today's state changed on the server (e.g. checked in from another device).
        await discardPhoto();
        await refreshToday();
        Get.until((route) => route.settings.name == AppRoutes.home);
        AppSnackbar.show(failure.message);
      } else {
        submitError.value = failure.message;
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  static bool _isStateConflict(String? code) =>
      code == 'ALREADY_CHECKED_IN' || code == 'ALREADY_CHECKED_OUT' || code == 'NOT_CHECKED_IN';

  Future<void> _resetFlow() async {
    await discardPhoto();
    locationStatus.value = LocationStatus.idle;
    locationMessage.value = '';
    locationFailure.value = null;
    position.value = null;
    verification.value = null;
    submitError.value = null;
    result.value = null;
    isSubmitting.value = false;
  }

  void _reset() {
    _ticker?.cancel();
    _ticker = null;
    today.value = null;
    todayError.value = null;
    isLoadingToday.value = false;
    unawaited(_resetFlow());
  }

  Future<void> _deletePhotoFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (error) {
      if (kDebugMode) debugPrint('Could not delete temporary attendance photo: $error');
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _employeeWorker?.dispose();
    super.onClose();
  }
}
