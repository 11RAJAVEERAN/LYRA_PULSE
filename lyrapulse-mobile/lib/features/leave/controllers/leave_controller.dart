import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../models/leave_model.dart';
import '../services/leave_service.dart';

class LeaveController extends GetxController {
final LeaveService _service = Get.find<LeaveService>();
  final RxList<LeaveModel> leaveList = <LeaveModel>[].obs;

  final RxMap<String, double> leaveBalances =
      <String, double>{}.obs;

  final RxInt selectedTab = 0.obs;

  final RxString selectedLeaveType = ''.obs;
  final RxString selectedDuration = 'Full Day'.obs;

  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  final Rx<DateTime> calendarMonth = DateTime.now().obs;

  final TextEditingController reasonController =
      TextEditingController();

  final RxString reason = ''.obs;

  final RxBool isLoading = false.obs;

  final List<String> leaveTypes = ['CL', 'SL', 'EL', 'LWP'];

  List<LeaveModel> get pendingLeaves =>
      leaveList.where((e) => e.status == 'Pending').toList();

  List<LeaveModel> get historyLeaves => leaveList
      .where((e) => e.status != 'Pending')
      .toList();

  double get totalAvailableLeaves {
    return leaveBalances.entries
        .where((e) => e.key != 'LWP')
        .fold(0.0, (sum, e) => sum + e.value);
  }

  double get selectedLeaveBalance {
    return leaveBalances[selectedLeaveType.value] ?? 0;
  }

  double get calculatedDays {
    if (startDate.value == null || endDate.value == null) {
      return 0;
    }



    final days =
        endDate.value!.difference(startDate.value!).inDays + 1;

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

        Get.dialog(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: const LeaveSuccessContent(),
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
        const CircleAvatar(
          radius: 35,
          backgroundColor: AppColors.successBackground,
          child: Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Leave Applied!',
          style: GoogleFonts.inter(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Leave has been applied successfully.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }
}