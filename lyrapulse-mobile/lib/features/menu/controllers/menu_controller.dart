
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../profile/views/profile_screen.dart';
import '../../notification/views/notification_screen.dart';
import '../views/upcoming_shifts_screen.dart';
import '../views/holidays_screen.dart';
import '../views/payslips_screen.dart';
import '../views/loans_advances_screen.dart';
import '../views/arrears_screen.dart';

class LyraMenuController extends GetxController {
  final RxString selectedMenu = 'Menu'.obs;

  void openProfile() {
    selectedMenu.value = 'My Profile';
   Get.toNamed('/profile');
  }

  void openNotifications() {
    selectedMenu.value = 'Notifications';
    Get.to(() => NotificationScreen());
  }

  void openUpcomingShifts() {
    selectedMenu.value = 'Upcoming Shifts';
    Get.to(() => const UpcomingShiftsScreen());
  }

  void openHolidays() {
    selectedMenu.value = 'Holidays';
    Get.to(() => const HolidaysScreen());
  }

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

  void showComingSoon(String feature) {
    Get.snackbar(
      feature,
      '$feature will be available soon.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF172554),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.offAllNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
