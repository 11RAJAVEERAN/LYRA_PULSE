import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  // --------------------------------------------------
  // Employee Details
  // --------------------------------------------------

  final employeeName = 'Rajavveeran K.'.obs;
  final designation = 'Information Technology'.obs;
  final employeeId = 'EMP-001'.obs;

  // --------------------------------------------------
  // Clock
  // --------------------------------------------------

  final currentTime = ''.obs;
  final currentDate = ''.obs;

  Timer? _clockTimer;
  Timer? _workingTimer;

  DateTime? _checkInDateTime;

  // --------------------------------------------------
  // Attendance
  // --------------------------------------------------

  final isCheckedIn = true.obs;

  final attendanceStatus = 'PRESENT'.obs;

  final checkInTime = '08:52 AM'.obs;
  final checkOutTime = '--'.obs;
  final workingHours = '4h 12m'.obs;
  final workingMinutes = 252.obs;

  final shiftStart = '09:00 AM'.obs;
  final shiftEnd = '06:00 PM'.obs;
  final totalShiftMinutes = 480.obs;

  final progress = 0.52.obs;

  // --------------------------------------------------
  // LIVE LOCATION
  // --------------------------------------------------

  final isLocationVerified = false.obs;

  final locationName = 'Checking location...'.obs;

  final locationDistance = '--'.obs;

  final currentLatitude = 0.0.obs;
  final currentLongitude = 0.0.obs;

  final locationError = ''.obs;

  final isLocationLoading = true.obs;

  StreamSubscription<Position>? _positionSubscription;

  // --------------------------------------------------
  // WORKPLACE LOCATION
  // --------------------------------------------------
  //
  // IMPORTANT:
  // Replace these with your actual workplace
  // latitude and longitude.
  //

  static const double workplaceLatitude = 11.7364;
  static const double workplaceLongitude = 79.7627;

  // Allowed attendance radius in meters.
  static const double workplaceRadius = 50;

  // --------------------------------------------------
  // Attendance Summary
  // --------------------------------------------------

  final presentDays = 22.obs;
  final absentDays = 2.obs;
  final lateDays = 3.obs;
  final leaveDays = 4.obs;

  // --------------------------------------------------
  // Weekly Attendance
  // --------------------------------------------------

  final weeklyAttendance = <String, String>{
    'M': 'present',
    'T': 'present',
    'W': 'late',
    'T2': 'present',
    'F': 'absent',
    'S': 'present',
    'S2': 'off',
  }.obs;

  // --------------------------------------------------
  // INIT
  // --------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    _updateClock();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateClock(),
    );

    if (isCheckedIn.value) {
      _startWorkingTimer();
    }

    // Start live GPS tracking
    startLiveLocation();
  }

  // --------------------------------------------------
  // CLOCK
  // --------------------------------------------------

  void _updateClock() {
    final now = DateTime.now();

    final hour = now.hour > 12
        ? now.hour - 12
        : now.hour == 0
            ? 12
            : now.hour;

    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    final period = now.hour >= 12 ? 'pm' : 'am';

    currentTime.value = '$hour:$minute:$second $period';

    currentDate.value = _formatDate(now);
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]}';
  }

  // --------------------------------------------------
  // LIVE LOCATION
  // --------------------------------------------------

  Future<void> startLiveLocation() async {
    isLocationLoading.value = true;
    locationError.value = '';

    try {
      // Check whether GPS is enabled.
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        locationError.value =
            'Location service is turned off';

        locationName.value = 'GPS Disabled';
        locationDistance.value = '--';
        isLocationVerified.value = false;
        isLocationLoading.value = false;

        return;
      }

      // Check permission.
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        locationError.value =
            'Location permission denied';

        locationName.value = 'Permission Required';
        locationDistance.value = '--';
        isLocationVerified.value = false;
        isLocationLoading.value = false;

        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        locationError.value =
            'Location permission permanently denied';

        locationName.value = 'Permission Required';
        locationDistance.value = '--';
        isLocationVerified.value = false;
        isLocationLoading.value = false;

        return;
      }

      // Get current location immediately.
      await _getCurrentLocation();

      // Start live location stream.
      _positionSubscription?.cancel();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _updateLocation(position);
        },
        onError: (error) {
          locationError.value =
              'Unable to track location';

          isLocationLoading.value = false;
        },
      );
    } catch (e) {
      locationError.value =
          'Location error occurred';

      locationName.value = 'Location unavailable';
      locationDistance.value = '--';
      isLocationVerified.value = false;
      isLocationLoading.value = false;
    }
  }

  // --------------------------------------------------
  // GET CURRENT LOCATION
  // --------------------------------------------------

  Future<void> _getCurrentLocation() async {
    try {
      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _updateLocation(position);
    } catch (e) {
      locationError.value =
          'Unable to get current location';

      locationName.value = 'Location unavailable';
      locationDistance.value = '--';
      isLocationVerified.value = false;
      isLocationLoading.value = false;
    }
  }

  // --------------------------------------------------
  // UPDATE LOCATION
  // --------------------------------------------------

  void _updateLocation(Position position) {
    currentLatitude.value = position.latitude;
    currentLongitude.value = position.longitude;

    final distanceInMeters =
        Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      workplaceLatitude,
      workplaceLongitude,
    );

    final isInside =
        distanceInMeters <= workplaceRadius;

    isLocationVerified.value = isInside;

    locationDistance.value =
        _formatDistance(distanceInMeters);

    if (isInside) {
      locationName.value = 'Hotel Devi';
      locationError.value = '';
    } else {
      locationName.value = 'Outside workplace';
      locationError.value =
          'Move inside the attendance area';
    }

    isLocationLoading.value = false;
  }

  // --------------------------------------------------
  // DISTANCE FORMAT
  // --------------------------------------------------

  String _formatDistance(double meters) {
    if (meters < 50) {
      return '${meters.round()}m from boundary';
    }

    final kilometers = meters / 50;

    return '${kilometers.toStringAsFixed(1)}km from boundary';
  }

  // --------------------------------------------------
  // OPEN LOCATION SETTINGS
  // --------------------------------------------------

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  // --------------------------------------------------
  // CHECK IN
  // --------------------------------------------------

  void checkIn() {
    if (isCheckedIn.value) return;

    if (!isLocationVerified.value) {
      Get.snackbar(
        'Location Required',
        'You must be inside the workplace area to check in.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    final now = DateTime.now();

    _checkInDateTime = now;

    isCheckedIn.value = true;
    attendanceStatus.value = 'PRESENT';

    checkInTime.value = _formatTime(now);
    checkOutTime.value = '--';

    workingMinutes.value = 0;
    workingHours.value = '0h 00m';

    progress.value = 0;

    _startWorkingTimer();
  }

  // --------------------------------------------------
  // CHECK OUT
  // --------------------------------------------------

  void checkOut() {
    if (!isCheckedIn.value) return;

    if (!isLocationVerified.value) {
      Get.snackbar(
        'Location Required',
        'You must be inside the workplace area to check out.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return;
    }

    final now = DateTime.now();

    checkOutTime.value = _formatTime(now);

    isCheckedIn.value = false;

    _workingTimer?.cancel();

    _calculateWorkingHours();

    progress.value = 1.0;
  }

  // --------------------------------------------------
  // WORKING TIMER
  // --------------------------------------------------

  void _startWorkingTimer() {
    _workingTimer?.cancel();

    _workingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!isCheckedIn.value) return;

        _calculateWorkingHours();
      },
    );
  }

  void _calculateWorkingHours() {
    if (_checkInDateTime == null) return;

    final now = DateTime.now();

    final difference =
        now.difference(_checkInDateTime!);

    final minutes = difference.inMinutes;

    workingMinutes.value = minutes;

    final hours = minutes ~/ 60;

    final remainingMinutes = minutes % 60;

    workingHours.value =
        '${hours}h '
        '${remainingMinutes.toString().padLeft(2, '0')}m';

    progress.value =
        (minutes / totalShiftMinutes.value)
            .clamp(0.0, 1.0);
  }

  // --------------------------------------------------
  // FORMAT TIME
  // --------------------------------------------------

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : date.hour == 0
            ? 12
            : date.hour;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // --------------------------------------------------
  // API READY METHODS
  // --------------------------------------------------

  Future<void> fetchAttendance() async {
    // API integration will be added here.
  }

  Future<void> fetchEmployeeDetails() async {
    // API integration will be added here.
  }

  Future<void> submitCheckIn() async {
    // API integration will be added here.
  }

  Future<void> submitCheckOut() async {
    // API integration will be added here.
  }

  // --------------------------------------------------
  // CLOSE
  // --------------------------------------------------

  @override
  void onClose() {
    _clockTimer?.cancel();
    _workingTimer?.cancel();
    _positionSubscription?.cancel();

    super.onClose();
  }
}