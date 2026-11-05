import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../../auth/controllers/auth_controller.dart';

/// UI state for the Home shell (selected tab, drawer). Attendance data lives in
/// AttendanceController; employee data in AuthController.
class HomeController extends GetxController {
  static const int homeTab = 0;
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

  /// Bottom navigation: only Home and Profile exist today; the rest have no
  /// backend yet, so they show a clean "Coming Soon" and keep the current tab.
  void onTabSelected(int index) {
    if (index == homeTab || index == profileTab) {
      tabIndex.value = index;
    } else {
      comingSoon(index == 1 ? 'Attendance history' : 'Leave');
    }
  }

  void comingSoon(String feature) => AppSnackbar.show('$feature is coming soon.');
}
