import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/theme/app_colors.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../attendance/views/location_verification_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../notification/views/notification_screen.dart';

class HomeController extends GetxController {
  late final AttendanceController attendanceController;

  // Current time – Home UI only
  final Rx<DateTime> now = DateTime.now().obs;
  Timer? _clockTimer;

  // Calendar state
  final RxBool showMonthlyCalendar = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rx<DateTime> displayedMonth = DateTime.now().obs;

  // Bottom navigation
  final RxInt selectedIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();

    attendanceController = Get.find<AttendanceController>();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => now.value = DateTime.now(),
    );

    checkLocationService();
  }

  // Calendar methods
  void toggleMonthlyCalendar() {
    if (showMonthlyCalendar.value) {
      showMonthlyCalendar.value = false;
    } else {
      displayedMonth.value = DateTime(
        selectedDate.value.year,
        selectedDate.value.month,
      );
      showMonthlyCalendar.value = true;
    }
  }

  void previousMonth() {
    final month = displayedMonth.value;
    displayedMonth.value = DateTime(month.year, month.month - 1);
  }

  void nextMonth() {
    final month = displayedMonth.value;
    displayedMonth.value = DateTime(month.year, month.month + 1);
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    showMonthlyCalendar.value = false;
  }

  String monthName(int month) {
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

    return months[month - 1];
  }

  String get dateLabel {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    final date = selectedDate.value;

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${monthName(date.month)} ${date.year}';
  }

  String formatTime(DateTime? value) {
    if (value == null) return '--:-- --';

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  // Attendance action
  Future<void> attendanceAction() async {
    final checkingOut = attendanceController.isCheckedIn;

    if (checkingOut &&
        attendanceController.checkInTime.value == null) {
      Get.snackbar(
        'Attendance',
        'Please check in before checking out.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Get.to(
      () => LocationVerificationScreen(
        isCheckOut: checkingOut,
      ),
      transition: Transition.cupertino,
    );
  }

  // Bottom navigation
  void selectTab(int index) {
    selectedIndex.value = index;
  }

  void openPage(int index) {
    switch (index) {
      case 0:
      case 1:
      case 2:
      case 3:
        selectTab(index);
        break;

      case 4:
        Get.to(() => ProfileScreen());
        break;

      case 5:
        Get.to(() => NotificationScreen());
        break;
    }
  }

  Future<void> refreshHome() async {
    now.value = DateTime.now();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  // Location service check
  Future<void> checkLocationService() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (enabled) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(17, 17, 17, 19),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.primaryBlue,
                  size: 50,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Location is turned off',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please turn on your location to use '
                'Lyra Pulse attendance features.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () async {
                    Get.back();
                    await Geolocator.openLocationSettings();
                  },
                  icon: const Icon(Icons.location_on_rounded),
                  label: const Text(
                    'Turn On Location',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
    );
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }
}