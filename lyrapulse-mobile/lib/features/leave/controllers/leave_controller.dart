import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../models/leave_model.dart';
import '../services/leave_service.dart';

class LeaveController extends GetxController {
  final LeaveService _service = Get.find<LeaveService>();
  final RxList<LeaveModel> leaveList = <LeaveModel>[].obs;

  final RxMap<String, double> leaveBalances = <String, double>{}.obs;

  final RxInt selectedTab = 0.obs;

  final RxString selectedLeaveType = ''.obs;
  final RxString selectedDuration = 'Full Day'.obs;

  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  final Rx<DateTime> calendarMonth = DateTime.now().obs;

  final TextEditingController reasonController = TextEditingController();

  final RxString reason = ''.obs;

  final RxBool isLoading = false.obs;

  // Project A exposes no employee leave API or leave-type configuration.
  // Keep the UI state empty until a real A contract is available.
  final List<String> leaveTypes = const [];

  List<LeaveModel> get pendingLeaves =>
      leaveList.where((e) => e.status == 'Pending').toList();

  List<LeaveModel> get historyLeaves =>
      leaveList.where((e) => e.status != 'Pending').toList();

  double get totalAvailableLeaves {
    return leaveBalances.entries
        .where((e) => e.key != 'LWP')
        .fold(0.0, (sum, e) => sum + e.value);
  }

  double get selectedLeaveBalance {
    return leaveBalances[selectedLeaveType.value] ?? 0;
  }

  bool get hasSelectedLeaveBalance =>
      leaveBalances.containsKey(selectedLeaveType.value);

  double get calculatedDays {
    if (startDate.value == null || endDate.value == null) {
      return 0;
    }

    final days = endDate.value!.difference(startDate.value!).inDays + 1;

    if (selectedDuration.value == 'Half Day') {
      return 0.5;
    }

    return days.toDouble();
  }

  bool get isFormValid {
    if (selectedLeaveType.value.isEmpty ||
        startDate.value == null ||
        endDate.value == null ||
        reason.value.trim().isEmpty) {
      return false;
    }

    if (endDate.value!.isBefore(startDate.value!)) {
      return false;
    }

    if (selectedLeaveType.value != 'LWP' &&
        calculatedDays > selectedLeaveBalance) {
      return false;
    }
    if (selectedDuration.value == 'Half Day' &&
        !DateUtils.isSameDay(startDate.value, endDate.value)) {
      return false;
    }

    return true;
  }

  @override
  void onInit() {
    super.onInit();
    loadLeaves();
  }

  void loadLeaves() {
    leaveList.assignAll(_service.getLeaves());
    leaveBalances.assignAll(_service.getLeaveBalances());
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  void selectLeaveType(String? value) {
    if (value == null) return;
    selectedLeaveType.value = value;
  }

  void selectDuration(String value) {
    selectedDuration.value = value;
  }

  void selectDate(DateTime date) {
    final selected = DateTime(date.year, date.month, date.day);

    if (startDate.value == null ||
        endDate.value != null ||
        selected.isBefore(startDate.value!)) {
      startDate.value = selected;
      endDate.value = null;
    } else {
      endDate.value = selected;
    }
  }

  void changeMonth(int offset) {
    final current = calendarMonth.value;

    calendarMonth.value = DateTime(
      current.year,
      current.month + offset,
    );
  }

  void resetDateSelection() {
    startDate.value = null;
    endDate.value = null;
  }

  void clearForm() {
    selectedLeaveType.value = '';
    selectedDuration.value = 'Full Day';
    startDate.value = null;
    endDate.value = null;
    reason.value = '';
    reasonController.clear();
    calendarMonth.value = DateTime.now();
  }

  Future<void> submitLeave() async {
    if (!isFormValid) {
      Get.snackbar(
        'Invalid Details',
        'Please complete all required fields.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;

    try {
      final leave = LeaveModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        leaveType: selectedLeaveType.value,
        startDate: startDate.value!,
        endDate: endDate.value!,
        duration: selectedDuration.value,
        totalDays: calculatedDays,
        reason: reason.value.trim(),
        status: 'Pending',
        appliedDate: DateTime.now(),
      );

      final success = await _service.applyLeave(leave);

      if (success) {
        loadLeaves();
        clearForm();

        Get.back();

        // UI only: dialog styling
        Get.dialog(
          Dialog(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(24, 30, 24, 22),
              child: LeaveSuccessContent(),
            ),
          ),
          barrierDismissible: false,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Unable to apply leave.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> withdrawLeave(String id) async {
    final success = await _service.withdrawLeave(id);

    if (success) {
      loadLeaves();

      Get.back();

      Get.snackbar(
        'Success',
        'Leave withdrawn successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Error',
        'Unable to withdraw this leave.',
      );
    }
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}

class LeaveSuccessContent extends StatelessWidget {
  const LeaveSuccessContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated double-ring check icon
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.successBackground,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),

        Text(
          'Leave Applied!',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your leave request has been submitted successfully.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),

        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.warningBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pending_actions_rounded,
                size: 15,
                color: AppColors.warningDark,
              ),
              const SizedBox(width: 6),
              Text(
                'Pending approval',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warningDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}