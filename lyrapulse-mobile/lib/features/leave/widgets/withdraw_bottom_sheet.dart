import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../controllers/leave_controller.dart';
import '../models/leave_model.dart';

class WithdrawBottomSheet extends GetView<LeaveController> {
  final LeaveModel leave;

  const WithdrawBottomSheet({
    super.key,
    required this.leave,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Withdraw Leave?',
              style: GoogleFonts.inter(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to withdraw this leave application?',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.hover,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${leave.leaveType} • ${leave.startDate.day}/${leave.startDate.month}/${leave.startDate.year}',
                style:  GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.surface,
                    ),
                    onPressed: () {
                      controller.withdrawLeave(leave.id);
                    },
                    child: const Text('Yes, Withdraw'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}