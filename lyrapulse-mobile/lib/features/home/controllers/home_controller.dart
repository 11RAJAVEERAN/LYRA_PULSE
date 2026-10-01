import 'package:get/get.dart';

class HomeController extends GetxController {
  // ==============================
  // Employee Details
  // ==============================

  final employeeName = 'Rajavveeran K.'.obs;

  final designation = 'information technology'.obs;

  final employeeId = 'EMP-2024-0147'.obs;

  // ==============================
  // Attendance
  // ==============================

  final isCheckedIn = true.obs;

  final attendanceStatus = 'PRESENT'.obs;

  final checkInTime = '08:52 AM'.obs;

  final checkOutTime = '--'.obs;

  final workingHours = '4h 12m'.obs;

  // ==============================
  // Current Time
  // ==============================

  final currentTime = '11:55:08 am'.obs;

  final currentDate = 'Thursday, 1 October'.obs;

  // ==============================
  // Today's Progress
  // ==============================

  final progress = 0.52.obs;

  final totalShiftHours = '8h'.obs;

  // ==============================
  // Location
  // ==============================

  final isLocationVerified = true.obs;

  final locationName = 'Lyra Grand Hotel'.obs;

  final locationDistance = '12m from boundary'.obs;

  // ==============================
  // Monthly Summary
  // ==============================

  final presentDays = 22.obs;

  final absentDays = 2.obs;

  final lateDays = 3.obs;

  final leaveDays = 4.obs;

  // ==============================
  // Check In
  // ==============================

  void checkIn() {
    isCheckedIn.value = true;

    attendanceStatus.value = 'PRESENT';

    checkInTime.value = '09:00 AM';

    checkOutTime.value = '--';

    workingHours.value = '0h 00m';

    progress.value = 0.0;
  }

  // ==============================
  // Check Out
  // ==============================

  void checkOut() {
    isCheckedIn.value = false;

    checkOutTime.value = '06:00 PM';

    workingHours.value = '8h 00m';

    progress.value = 1.0;
  }
}