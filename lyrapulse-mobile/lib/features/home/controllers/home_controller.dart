import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../../attendance/views/attendance_history_screen.dart';
import '../../auth/controllers/auth_controller.dart';

/// UI state for the Home shell (selected tab, drawer). Attendance data lives in
/// AttendanceController; employee data in AuthController.
class HomeController extends GetxController {
  static const int homeTab = 0;
  static const int attendanceTab = 1;
  static const int profileTab = 3;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final tabIndex = homeTab.obs;

  @override
  void onInit() {
    super.onInit();
    // Start on Home again after a sign-out / sign-in (this controller outlives the Home route).
    ever(Get.find<AuthController>().employee, (employee) {
      if (employee == null) tabIndex.value = homeTab;
    });
  }

  void openDrawer() => scaffoldKey.currentState?.openDrawer();

  void closeDrawer() => scaffoldKey.currentState?.closeDrawer();

  void showHome() => tabIndex.value = homeTab;

  void showProfile() => tabIndex.value = profileTab;

  void openAttendanceHistory() {
    Get.to(
      () => const AttendanceHistoryScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );
  }

  void onTabSelected(int index) {
    if (index == homeTab || index == profileTab) {
      tabIndex.value = index;
    } else if (index == attendanceTab) {
      openAttendanceHistory();
    } else {
      comingSoon('Leave');
    }
  }

  void comingSoon(String feature) =>
      AppSnackbar.show('$feature is coming soon.');
}
