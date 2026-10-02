import 'dart:async';

import 'package:get/get.dart';

class HomeController extends GetxController {
  // ============================================================
  // Employee
  // ============================================================

  final employeeName = 'Rajavveeran K.'.obs;
  final designation = 'Information Technology'.obs;
  final employeeId = 'EMP-oo1'.obs;

  // ============================================================
  // Date / Time
  // ============================================================

  final currentTime = ''.obs;
  final currentDate = ''.obs;

  Timer? _clockTimer;
  Timer? _workingTimer;

  DateTime? _checkInDateTime;

  // ============================================================
  // Attendance
  // ============================================================

  final isCheckedIn = true.obs;

  final attendanceStatus = 'PRESENT'.obs;

  final checkInTime = '08:52 AM'.obs;

  final checkOutTime = '--'.obs;

  final workingHours = '4h 12m'.obs;

  final workingMinutes = 252.obs;

  // ============================================================
  // Shift
  // ============================================================

  final shiftStart = '09:00 AM'.obs;
  final shiftEnd = '06:00 PM'.obs;

  final totalShiftMinutes = 480.obs;

  // ============================================================
  // Location
  // ============================================================

  final isLocationVerified = true.obs;

  final locationName = 'Lyra Grand Hotel'.obs;

  final locationDistance = '12m from boundary'.obs;

  // ============================================================
  // Progress
  // ============================================================

  final progress = 0.52.obs;

  // ============================================================
  // Monthly Summary
  // ============================================================

  final presentDays = 22.obs;
  final absentDays = 2.obs;
  final lateDays = 3.obs;
  final leaveDays = 4.obs;

  // ============================================================
  // Weekly Attendance
  // ============================================================

  final weeklyAttendance = <String, String>{
    'M': 'present',
    'T': 'present',
    'W': 'late',
    'T2': 'present',
    'F': 'absent',
    'S': 'present',
    'S2': 'off',
  }.obs;

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
  }

  // ============================================================
  // Current Clock
  // ============================================================

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

    currentTime.value =
        '$hour:$minute:$second $period';

    currentDate.value =
        _formatDate(now);
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

  // ============================================================
  // Check In
  // ============================================================

  void checkIn() {
    if (isCheckedIn.value) return;

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

  // ============================================================
  // Check Out
  // ============================================================

  void checkOut() {
    if (!isCheckedIn.value) return;

    final now = DateTime.now();

    checkOutTime.value = _formatTime(now);

    isCheckedIn.value = false;

    _workingTimer?.cancel();

    _calculateWorkingHours();

    progress.value = 1.0;
  }

  // ============================================================
  // Working Timer
  // ============================================================

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
        '${hours}h ${remainingMinutes.toString().padLeft(2, '0')}m';

    progress.value =
        (minutes / totalShiftMinutes.value)
            .clamp(0.0, 1.0);
  }

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

  // ============================================================
  // API Ready Methods
  // ============================================================

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

  // ============================================================
  // Cleanup
  // ============================================================

  @override
  void onClose() {
    _clockTimer?.cancel();
    _workingTimer?.cancel();

    super.onClose();
  }
}