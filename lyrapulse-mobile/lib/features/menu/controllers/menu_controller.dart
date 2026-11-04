
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../notification/views/notification_screen.dart';
import '../views/upcoming_shifts_screen.dart';
import '../views/holidays_screen.dart';
import '../views/payslips_screen.dart';
import '../views/loans_advances_screen.dart';
import '../views/arrears_screen.dart';

class LyraMenuController extends GetxController {
  final RxString selectedMenu = 'Menu'.obs;

  // Profile
  void openProfile() {
    selectedMenu.value = 'My Profile';
    Get.toNamed('/profile');
  }

  // Notifications
  void openNotifications() {
    selectedMenu.value = 'Notifications';
    Get.to(() => NotificationScreen());
  }

  // Schedule
  void openUpcomingShifts() {
    selectedMenu.value = 'Upcoming Shifts';
    Get.to(() => const UpcomingShiftsScreen());
  }

  void openHolidays() {
    selectedMenu.value = 'Holidays';
    Get.to(() => const HolidaysScreen());
  }

  // Pay & Benefits
  void openPayslips() {
    selectedMenu.value = 'Payslips';
    Get.to(() => const PayslipsScreen());
  }

  void openLoansAdvances() {
    selectedMenu.value = 'Loans & Advances';
    Get.to(() => const LoansAdvancesScreen());
  }

  void openArrears() {
    selectedMenu.value = 'Arrears';
    Get.to(() => const ArrearsScreen());
  }

  // Settings

  void openAppLanguage() {
    selectedMenu.value = 'App Language';
    showComingSoon('App Language');
  }

  void openAppTheme() {
    selectedMenu.value = 'App Theme';
    showComingSoon('App Theme');
  }

  void checkForUpdates() {
    selectedMenu.value = 'Check for Updates';
    showComingSoon('Check for Updates');
  }

  // Coming Soon
  void showComingSoon(String feature) {
    Get.snackbar(
      feature,
      '$feature will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: AppColors.primary,
      colorText: AppColors.surface,
      duration: const Duration(seconds: 2),
    );
  }

  // Logout
  // Confirmation dialog is handled in MenuScreen.
  void logout() {
    Get.offAllNamed('/login');
  }
}
