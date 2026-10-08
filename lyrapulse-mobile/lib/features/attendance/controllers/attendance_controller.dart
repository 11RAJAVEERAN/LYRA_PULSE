import 'dart:async';

import 'package:get/get.dart';

class AttendanceController extends GetxController {
  // ================================================================
  // ATTENDANCE TIMES
  // ================================================================

  final Rxn<DateTime> checkInTime = Rxn<DateTime>();
  final Rxn<DateTime> checkOutTime = Rxn<DateTime>();

  // Live working duration
  final Rx<Duration> workingDuration = Duration.zero.obs;

  Timer? _timer;

  // ================================================================
  // CHECK IN
  // ================================================================

  void checkInNow() {
    final now = DateTime.now();

    checkInTime.value = now;
    checkOutTime.value = null;

    workingDuration.value = Duration.zero;

    _startLiveTimer();
  }

  // ================================================================
  // CHECK OUT
  // ================================================================

  void checkOutNow() {
    if (checkInTime.value == null) {
      return;
    }

    final now = DateTime.now();

    checkOutTime.value = now;

    workingDuration.value =
        now.difference(checkInTime.value!);

    _stopLiveTimer();
  }

  // ================================================================
  // LIVE TIMER
  // ================================================================

  void _startLiveTimer() {
    _stopLiveTimer();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (checkInTime.value != null &&
            checkOutTime.value == null) {
          workingDuration.value =
              DateTime.now().difference(checkInTime.value!);
        }
      },
    );
  }

  void _stopLiveTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ================================================================
  // FORMAT TIME
  // ================================================================

  String formatTime(DateTime? time) {
    if (time == null) {
      return '--:--';
    }

    int hour = time.hour;
    final minute = time.minute;

    final period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    final hourText = hour.toString().padLeft(2, '0');
    final minuteText = minute.toString().padLeft(2, '0');

    return '$hourText:$minuteText $period';
  }

  // ================================================================
  // FORMAT WORKING HOURS
  // ================================================================

  String get totalHoursText {
    final duration = workingDuration.value;

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    final hoursText = hours.toString().padLeft(2, '0');
    final minutesText = minutes.toString().padLeft(2, '0');

    return '${hoursText}h ${minutesText}m';
  }

  // ================================================================
  // STATUS
  // ================================================================

  String get attendanceStatus {
    if (checkInTime.value == null) {
      return 'Not Marked';
    }

    if (checkOutTime.value == null) {
      return 'Checked In';
    }

    return 'Completed';
  }

  // ================================================================
  // IS CHECKED IN
  // ================================================================

  bool get isCheckedIn {
    return checkInTime.value != null &&
        checkOutTime.value == null;
  }

  // ================================================================
  // IS COMPLETED
  // ================================================================

  bool get isCompleted {
    return checkInTime.value != null &&
        checkOutTime.value != null;
  }

  // ================================================================
  // RESET
  // ================================================================

  void resetAttendance() {
    checkInTime.value = null;
    checkOutTime.value = null;
    workingDuration.value = Duration.zero;

    _stopLiveTimer();
  }

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void onClose() {
    _stopLiveTimer();
    super.onClose();
  }
}