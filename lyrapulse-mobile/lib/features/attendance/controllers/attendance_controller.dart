import 'dart:async';
import 'dart:io';
import 'dart:math';

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
  final profileError = RxnString();
  Future<void>? _refreshFuture;
  int _refreshGeneration = 0;
  bool _employeePermissionsFresh = true;

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
  String? _idempotencyKey;
  bool _isStartingFlow = false;

  // ---------------------------------------------------------------------------
  // HISTORY
  // ---------------------------------------------------------------------------
  final attendanceHistory = <AttendanceHistoryRecord>[].obs;
  final isLoadingHistory = false.obs;
  final historyError = RxnString();
  final historyHasNext = false.obs;
  int _historyPage = 0;
  int _historyGeneration = 0;
  DateTime? _historyStartDate;
  DateTime? _historyEndDate;

  bool get isCheckIn => action.value == AttendanceAction.checkIn;
  bool get mobileAttendanceEnabled =>
      _employeePermissionsFresh &&
      (_auth.employee.value?.mobileAttendanceEnabled ?? false);
  bool get photoRequired =>
      _auth.employee.value?.photoAttendanceEnabled ?? false;
  bool get locationRequired =>
      _auth.employee.value?.locationAttendanceEnabled ?? false;

  AttendanceState? get state => today.value?.state;
  bool get canCheckIn => state?.allowsCheckIn ?? false;
  bool get canCheckOut => state?.allowsCheckOut ?? false;
  bool get canAttemptCheckIn =>
      canCheckIn || (state?.mayNeedCheckInRefresh ?? false);
  bool get canTriggerAttendanceAction =>
      canAttemptCheckIn || canCheckOut;
  bool get isOnBreak => state == AttendanceState.onBreak;

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

  /// Breaks are the gaps between preserved work-session rows. The last gap
  /// keeps ticking while the backend reports that today's state is ON_BREAK.
  Duration get breakDuration {
    final sessions = today.value?.sessions ?? const <TodaySession>[];
    var total = Duration.zero;
    for (var index = 0; index < sessions.length; index++) {
      final ended = sessions[index].checkOutAt;
      if (ended == null) continue;
      final resumed = index + 1 < sessions.length
          ? sessions[index + 1].checkInAt
          : (isOnBreak ? _now.value : null);
      if (resumed == null) continue;
      final gap = resumed.difference(ended);
      if (!gap.isNegative) total += gap;
    }
    return total;
  }

  String get formattedBreakDuration {
    final duration = breakDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  /// B's home card expects a clock-style duration. The duration still comes
  /// from Project A's server timestamps; the local ticker only updates it.
  String get formattedWorkingDuration {
    final duration = workingDuration;
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String get statusLabel {
    switch (state) {
      case AttendanceState.checkedIn:
        return 'Checked in';
      case AttendanceState.checkedOut:
        return 'Completed';
      case AttendanceState.onBreak:
        return 'On break';
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
        _employeePermissionsFresh = false;
        _reset();
      } else {
        _employeePermissionsFresh = true;
        unawaited(refreshToday());
      }
    });
    if (_auth.employee.value != null) unawaited(refreshToday());
  }

  Future<void> refreshToday() {
    final pending = _refreshFuture;
    if (pending != null) return pending;
    if (_auth.employee.value == null) return Future<void>.value();

    final generation = ++_refreshGeneration;
    isLoadingToday.value = true;
    todayError.value = null;
    profileError.value = null;
    final todayRequest = _repository.fetchToday().then<void>((value) {
      if (generation == _refreshGeneration) _applyToday(value);
    }, onError: (Object error) {
      if (generation == _refreshGeneration) {
        todayError.value = error is AttendanceFailure
            ? error.message
            : _auth.errorMessage(error);
      }
    });
    final profileRequest = _auth.reloadEmployeeProfile().then<void>((_) {
      if (generation == _refreshGeneration) {
        _employeePermissionsFresh = true;
      }
    }, onError: (Object error) {
      if (generation == _refreshGeneration) {
        _employeePermissionsFresh = false;
        profileError.value = _auth.errorMessage(error);
      }
    });

    late final Future<void> refresh;
    refresh =
        Future.wait<void>([todayRequest, profileRequest]).whenComplete(() {
      if (generation == _refreshGeneration) isLoadingToday.value = false;
      if (identical(_refreshFuture, refresh)) _refreshFuture = null;
    });
    _refreshFuture = refresh;
    return refresh;
  }

  Future<void> loadHistory(
      {DateTime? startDate, DateTime? endDate, bool append = false}) async {
    if (append && isLoadingHistory.value) return;
    if (append && !historyHasNext.value) return;
    if (!append) {
      final today = DateTime.now();
      _historyStartDate =
          _dateOnly(startDate ?? DateTime(today.year, today.month));
      _historyEndDate = _dateOnly(endDate ?? today);
      _historyPage = 0;
      historyHasNext.value = false;
      attendanceHistory.clear();
      historyError.value = null;
      _historyGeneration++;
    }

    final generation = _historyGeneration;
    final nextPage = append ? _historyPage + 1 : 1;
    isLoadingHistory.value = true;
    historyError.value = null;
    try {
      final result = await _repository.fetchHistory(
        startDate: _historyStartDate!,
        endDate: _historyEndDate!,
        page: nextPage,
      );
      if (generation != _historyGeneration) return;
      if (append) {
        attendanceHistory.addAll(result.results);
      } else {
        attendanceHistory.assignAll(result.results);
      }
      _historyPage = result.page;
      historyHasNext.value = result.hasNext;
    } on AttendanceFailure catch (failure) {
      if (generation == _historyGeneration) {
        historyError.value = failure.message;
      }
    } finally {
      if (generation == _historyGeneration) isLoadingHistory.value = false;
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  void _applyToday(TodayAttendance value) {
    today.value = value;
    _syncTicker();
  }

  void _syncTicker() {
    if (state == AttendanceState.checkedIn || state == AttendanceState.onBreak) {
      _now.value = DateTime.now();
      _ticker ??= Timer.periodic(
          const Duration(seconds: 1), (_) => _now.value = DateTime.now());
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
    if (isSubmitting.value || _isStartingFlow) return;
    if (!mobileAttendanceEnabled) {
      AppSnackbar.show(_auth.employee.value?.biometricAttendanceEnabled == true
          ? 'Mobile attendance is disabled. Use your assigned biometric device.'
          : 'Mobile attendance is not enabled for your account. Contact your administrator.');
      return;
    }
    if (state == null) {
      AppSnackbar.show(
          'Attendance status is not loaded yet. Please try again.');
      unawaited(refreshToday());
      return;
    }
    _isStartingFlow = true;
    try {
      // A cached CHECKED_OUT state can become stale when the previous checkout
      // was an in-shift break. Refresh from the server before blocking Check In.
      if (requested == AttendanceAction.checkIn &&
          (state?.mayNeedCheckInRefresh ?? false)) {
        await refreshToday();
        if (todayError.value != null || state == null) {
          AppSnackbar.show(
              'Attendance status could not be refreshed. Please try again.');
          return;
        }
        if (!mobileAttendanceEnabled) {
          AppSnackbar.show(_auth.employee.value?.biometricAttendanceEnabled == true
              ? 'Mobile attendance is disabled. Use your assigned biometric device.'
              : 'Mobile attendance is not enabled for your account. Contact your administrator.');
          return;
        }
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
    } finally {
      _isStartingFlow = false;
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
        fix: fix,
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
    Get.toNamed(photoRequired
        ? AppRoutes.attendanceCamera
        : AppRoutes.attendanceConfirm);
  }

  void setPhoto(String path) {
    if (photoPath.value != path) _idempotencyKey = null;
    unawaited(_deletePhotoFile(photoPath.value));
    photoPath.value = path;
  }

  /// Drops the captured photo and removes its temporary file.
  Future<void> discardPhoto() async {
    final path = photoPath.value;
    photoPath.value = null;
    _idempotencyKey = null;
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
    if ((locationRequired &&
            (fix == null || verification.value?.verified != true)) ||
        (photoRequired && path == null)) {
      AppSnackbar.show(locationRequired
          ? (photoRequired
              ? 'Verify your location and take a photo first.'
              : 'Verify your location first.')
          : 'Take your attendance photo first.');
      return;
    }
    isSubmitting.value = true;
    submitError.value = null;
    _idempotencyKey ??= _newIdempotencyKey();
    try {
      final done = isCheckIn
          ? await _repository.checkIn(
              idempotencyKey: _idempotencyKey!,
              location: locationRequired ? fix : null,
              photoPath: path)
          : await _repository.checkOut(
              idempotencyKey: _idempotencyKey!,
              location: locationRequired ? fix : null,
              photoPath: path);
      result.value = done;
      await discardPhoto();
      // Backend is the source of truth: re-fetch rather than patching local state.
      await _refreshAfterAction();
      Get.offNamedUntil(AppRoutes.attendanceSuccess,
          (route) => route.settings.name == AppRoutes.home);
    } on AttendanceFailure catch (failure) {
      if (_isStateConflict(failure.code)) {
        // Today's state changed on the server (e.g. checked in from another device).
        await discardPhoto();
        await _refreshAfterAction();
        Get.until((route) => route.settings.name == AppRoutes.home);
        AppSnackbar.show(failure.message);
      } else {
        if (!failure.isConnectivity) _idempotencyKey = null;
        submitError.value = failure.message;
        if (Get.currentRoute == AppRoutes.home) {
          AppSnackbar.show(failure.message);
        }
        if (_requiresFreshLocation(failure.code)) {
          position.value = null;
          verification.value = null;
          locationStatus.value = LocationStatus.failed;
          locationMessage.value = failure.message;
          Get.offNamed(AppRoutes.attendanceLocation);
        }
        await _refreshAfterAction();
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _refreshAfterAction() async {
    final pending = _refreshFuture;
    if (pending != null) await pending;
    await refreshToday();
  }

  static bool _isStateConflict(String? code) =>
      code == 'ALREADY_CHECKED_IN' ||
      code == 'ALREADY_CHECKED_OUT' ||
      code == 'NOT_CHECKED_IN';

  static bool _requiresFreshLocation(String? code) =>
      code == 'STALE_LOCATION' ||
      code == 'FUTURE_LOCATION' ||
      code == 'INVALID_LOCATION_TIMESTAMP' ||
      code == 'INVALID_GPS_ACCURACY' ||
      code == 'GPS_ACCURACY_EXCEEDS_RADIUS' ||
      code == 'OUTSIDE_ATTENDANCE_RADIUS';

  static String _newIdempotencyKey() {
    final random = Random.secure();
    return List.generate(32, (_) => random.nextInt(16).toRadixString(16))
        .join();
  }

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
    _idempotencyKey = null;
  }

  void _reset() {
    _ticker?.cancel();
    _ticker = null;
    today.value = null;
    todayError.value = null;
    profileError.value = null;
    _refreshGeneration++;
    _refreshFuture = null;
    isLoadingToday.value = false;
    _historyGeneration++;
    attendanceHistory.clear();
    isLoadingHistory.value = false;
    historyError.value = null;
    historyHasNext.value = false;
    _historyPage = 0;
    unawaited(_resetFlow());
  }

  Future<void> _deletePhotoFile(String? path) async {
    if (path == null) {
      return;
    }
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Could not delete temporary attendance photo: $error');
      }
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _employeeWorker?.dispose();
    _refreshGeneration++;
    super.onClose();
  }
}
