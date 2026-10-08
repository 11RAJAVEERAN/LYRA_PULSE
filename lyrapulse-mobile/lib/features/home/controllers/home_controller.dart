import 'dart:async';

import 'package:flutter/material.dart';
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

  final isCheckedIn = false.obs;
  final attendanceStatus = 'NOT CHECKED IN'.obs;
  final checkInTime = '--'.obs;
  final checkOutTime = '--'.obs;
  final workingHours = '0h 00m'.obs;
  final workingMinutes = 0.obs;
  final progress = 0.0.obs;

  static const int totalShiftMinutes = 8 * 60;

  // --------------------------------------------------
  // Live Location
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
  // Workplace Location
  // --------------------------------------------------

  static const double workplaceLatitude = 11.7364;
  static const double workplaceLongitude = 79.7627;

  // Allowed attendance radius
  static const double workplaceRadius = 100;

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
  // Init
  // --------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    _startLiveClock();
    startLiveLocation();
  }

Future<void> _showLocationOffDialog() async {
  if (Get.isDialogOpen == true) {
    return;
  }

  await Get.dialog(
    AlertDialog(
      title: const Text(
        'Location is Off',
        style: TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
      content: const Text(
        'Please turn on your phone location to continue.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            await Geolocator.openLocationSettings();
          },
          child: const Text('Turn On Location'),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

  // --------------------------------------------------
  // Start Live Clock
  // --------------------------------------------------

  void _startLiveClock() {
    _updateClock();

    _clockTimer?.cancel();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        _updateClock();
      },
    );
  }

  // --------------------------------------------------
  // Update Clock
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

  // --------------------------------------------------
  // Date Format
  // --------------------------------------------------

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
  // Live Location
  // --------------------------------------------------

  Future<void> startLiveLocation() async {
    isLocationLoading.value = true;
    locationError.value = '';

    try {

final serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

if (!serviceEnabled) {
  locationError.value =
      'Location service is turned off';

  locationName.value =
      'GPS Disabled';

  locationDistance.value = '--';

  isLocationVerified.value = false;

  isLocationLoading.value = false;

  await _showLocationOffDialog();

  return;
}








      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
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

      if (permission == LocationPermission.deniedForever) {
        locationError.value =
            'Location permission permanently denied';

        locationName.value = 'Permission Required';
        locationDistance.value = '--';
        isLocationVerified.value = false;
        isLocationLoading.value = false;

        return;
      }

      await _getCurrentLocation();

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
  debugPrint('LIVE LOCATION ERROR: $e');

  locationError.value =
      'Location error occurred';

  locationName.value =
      'Location unavailable';

  locationDistance.value = '--';

  isLocationVerified.value = false;

  isLocationLoading.value = false;
}

  }
  // --------------------------------------------------
  // Get Current Location
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
       }
        catch (e) {
    debugPrint('LOCATION ERROR: $e');

    locationError.value =
        'Unable to get current location';

    locationName.value =
        'Location unavailable';

    locationDistance.value = '--';

    isLocationVerified.value = false;

    isLocationLoading.value = false;
       }}



  // --------------------------------------------------
  // Update Location
  // --------------------------------------------------
 
void _updateLocation(Position position) {
  currentLatitude.value = position.latitude;
  currentLongitude.value = position.longitude;

  final distanceInMeters = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    workplaceLatitude,
    workplaceLongitude,
  );

  final isInside = distanceInMeters <= workplaceRadius;

  debugPrint('CURRENT LAT: ${position.latitude}');
  debugPrint('CURRENT LNG: ${position.longitude}');
  debugPrint('OFFICE LAT: $workplaceLatitude');
  debugPrint('OFFICE LNG: $workplaceLongitude');
  debugPrint('DISTANCE: $distanceInMeters');
  debugPrint('INSIDE: $isInside');

  isLocationVerified.value = isInside;

  locationDistance.value = _formatDistance(distanceInMeters);

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
  // Distance Format
  // --------------------------------------------------

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m away';
    }

    final kilometers = meters / 1000;

    return '${kilometers.toStringAsFixed(1)}km away';
  }

  // --------------------------------------------------
  // Open Location Settings
  // --------------------------------------------------

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> openAppLocationSettings() async {
    await Geolocator.openAppSettings();
  }

  // --------------------------------------------------
  // Check In
  // --------------------------------------------------

  void checkIn() {
    if (isCheckedIn.value) {
      return;
    }

    if (!isLocationVerified.value) {
      Get.snackbar(
        'Location Required',
        'You must be inside the workplace area to check in.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
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
  // Check Out
  // --------------------------------------------------
 
      bool checkOut() {
  if (!isCheckedIn.value) {
    Get.snackbar(
      'Check Out Error',
      'You are not currently checked in.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );

    return false;
  }

  if (!isLocationVerified.value) {
    Get.snackbar(
      'Location Required',
      'You must be inside the workplace area to check out.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );

    return false;
  }

  final now = DateTime.now();

  checkOutTime.value = _formatTime(now);
  isCheckedIn.value = false;
  attendanceStatus.value = 'CHECKED OUT';

  _workingTimer?.cancel();

  _calculateWorkingHours();

  progress.value = 1.0;

  return true;
}




  // --------------------------------------------------
  // Working Timer
  // --------------------------------------------------

  void _startWorkingTimer() {
    _workingTimer?.cancel();

    _workingTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!isCheckedIn.value) {
          return;
        }

        _calculateWorkingHours();
      },
    );
  }

  // --------------------------------------------------
  // Calculate Working Hours
  // --------------------------------------------------

  void _calculateWorkingHours() {
    if (_checkInDateTime == null) {
      return;
    }

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
        (minutes / totalShiftMinutes)
            .clamp(0.0, 1.0);
  }

  // --------------------------------------------------
  // Format Time
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
  // API Ready Methods
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
  // Close
  // --------------------------------------------------

  @override
  void onClose() {
    _clockTimer?.cancel();
    _workingTimer?.cancel();
    _positionSubscription?.cancel();

    super.onClose();
  }
}