import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/providers/api_provider.dart';
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
  final currentShiftTiming = 'Not available'.obs;
  final isLoadingShiftTiming = false.obs;

  final _apiProvider = Get.find<ApiProvider>();

  @override
  void onInit() {
    super.onInit();
    // Start on Home again after a sign-out / sign-in (this controller outlives the Home route).
    ever(Get.find<AuthController>().employee, (employee) {
      if (employee == null) tabIndex.value = homeTab;
    });
  }

  void openDrawer() => scaffoldKey.currentState?.openDrawer();

  Future<void> loadCurrentShiftTiming() async {
    if (isLoadingShiftTiming.value) return;
    isLoadingShiftTiming.value = true;
    try {
      final response = await _apiProvider.getCurrentEmployeeShiftAssignment();
      final body = _asMap(response.data);
      final assignment = _asMap(body['data']);
      final start = _formatTime(assignment['start_time']);
      final end = _formatTime(assignment['end_time']);
      currentShiftTiming.value = start != null && end != null
          ? '$start - $end'
          : 'Not available';
    } catch (_) {
      currentShiftTiming.value = 'Not available';
    } finally {
      isLoadingShiftTiming.value = false;
    }
  }

  static String? _formatTime(dynamic value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.toString());
    if (match == null) return null;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return Formatters.time12(DateTime(2000, 1, 1, hour, minute));
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

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
