
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notification/views/notification_screen.dart';
import 'upcoming_shifts_controller.dart';
import '../views/upcoming_shifts_screen.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../profile/views/profile_screen.dart';

class LyraMenuController extends GetxController {
  final RxString selectedMenu = 'Menu'.obs;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    if (auth.employee.value != null) {
      unawaited(auth.reloadEmployeeProfile().then<void>(
        (_) {},
        onError: (Object _) {},
      ));
    }
  }

  // Profile
  void openProfile() {
    selectedMenu.value = 'My Profile';
    final auth = Get.find<AuthController>();
    unawaited(auth.reloadEmployeeProfile().then<void>(
      (_) {},
      onError: (Object _) {},
    ));
    Get.to(
      () => const ProfileScreen(),
      binding: ProfileBinding(),
    );
  }

  // Notifications
  void openNotifications() {
    selectedMenu.value = 'Notifications';
    Get.to(() => NotificationScreen());
  }

  // Schedule
  void openUpcomingShifts() {
    selectedMenu.value = 'Upcoming Shifts';
    Get.to(
      () => const UpcomingShiftsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<UpcomingShiftsController>(() => UpcomingShiftsController());
      }),
    );
  }

  void openHolidays() {
    selectedMenu.value = 'Holidays';
    showComingSoon('Holidays');
  }

  // Pay & Benefits
  void openPayslips() {
    selectedMenu.value = 'Payslips';
    showComingSoon('Payslips');
  }

  void openLoansAdvances() {
    selectedMenu.value = 'Loans & Advances';
    showComingSoon('Loans & Advances');
  }

  void openArrears() {
    selectedMenu.value = 'Arrears';
    showComingSoon('Arrears');
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
      'This feature is coming soon.',
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
    Get.find<AuthController>().logout();
  }
}
