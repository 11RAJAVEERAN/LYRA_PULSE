import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../controllers/leave_controller.dart';

class LeaveBalanceCard extends GetView<LeaveController> {
  const LeaveBalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final balance = controller.selectedLeaveBalance;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primaryBlue,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
color: AppColors.primaryBlue.withValues(alpha: 0.18),              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Available Leave Balance',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.event_available,
                  color: AppColors.surface,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Text(
                  '${balance.toStringAsFixed(1)} Days',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.surface),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Remaining Balance',
                  style: TextStyle(color: AppColors.surface),
                ),
                Text(
                  '${balance.toStringAsFixed(1)} Days',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}