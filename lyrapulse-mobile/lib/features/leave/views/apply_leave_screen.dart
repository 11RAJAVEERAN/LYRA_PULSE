import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../controllers/leave_controller.dart';
import '../widgets/leave_balance_card.dart';
import '../widgets/leave_calendar_sheet.dart';

class ApplyLeaveScreen extends GetView<LeaveController> {
  const ApplyLeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text(
          'Apply Leave',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LeaveBalanceCard(),
            const SizedBox(height: 25),

            _heading('Leave Type'),
            const SizedBox(height: 10),

            Obx(
              () => DropdownButtonFormField<String>(
  initialValue: controller.selectedLeaveType.value.isEmpty
      ? null
      : controller.selectedLeaveType.value,
                decoration: _decoration(
                  'Select Leave Type',
                  Icons.category_outlined,
                ),
                items: controller.leaveTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text('$type Leave'),
                  );
                }).toList(),
                onChanged: controller.selectLeaveType,
              ),
            ),

            const SizedBox(height: 22),
            _heading('Select Date'),
            const SizedBox(height: 10),

            Obx(() {
              final start = controller.startDate.value;
              final end = controller.endDate.value;

              return InkWell(
                onTap: () {
                  Get.bottomSheet(
                    const LeaveCalendarSheet(),
                    isScrollControlled: true,
                    backgroundColor: AppColors.surface,
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              start == null
                                  ? 'Select Start & End Date'
                                  : '${_date(start)} - ${end == null ? 'Select End Date' : _date(end)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Tap to open calendar',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 22),
            _heading('Applying Leave For'),
            const SizedBox(height: 10),

            Obx(
              () => Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _durationOption('Full Day'),
                        const SizedBox(width: 10),
                        _durationOption('Half Day'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Leave Days',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        Text(
                          '${controller.calculatedDays} Days',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),
            _heading('Mention Reason'),
            const SizedBox(height: 10),

            TextField(
              controller: controller.reasonController,
              maxLines: 4,
              onChanged: (value) => controller.reason.value = value,
              decoration: _decoration(
                'Enter your leave reason...',
                Icons.edit_note,
              ).copyWith(
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 12),

            Obx(() {
              final exceeds = controller.selectedLeaveType.value.isNotEmpty &&
                  controller.selectedLeaveType.value != 'LWP' &&
                  controller.calculatedDays >
                      controller.selectedLeaveBalance;

              return exceeds
                  ? const Text(
                      'Insufficient leave balance.',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    )
                  : const SizedBox.shrink();
            }),

            const SizedBox(height: 30),

            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: controller.isFormValid &&
                          !controller.isLoading.value
                      ? controller.submitLeave
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.surface,
                    disabledBackgroundColor: AppColors.borderStrong,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(
                          color: AppColors.surface,
                        )
                      : const Text(
                          'Confirm Apply',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _heading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _durationOption(String value) {
    final selected = controller.selectedDuration.value == value;

    return Expanded(
      child: InkWell(
        onTap: () => controller.selectDuration(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.infoSurface
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppColors.primaryBlue
                  : AppColors.borderStrong,
            ),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: selected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _date(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}