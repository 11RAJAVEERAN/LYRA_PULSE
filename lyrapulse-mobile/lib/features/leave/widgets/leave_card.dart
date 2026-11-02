import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../models/leave_model.dart';
import 'leave_status_chip.dart';

class LeaveCard extends StatelessWidget {
  final LeaveModel leave;
  final VoidCallback? onWithdraw;

  const LeaveCard({
    super.key,
    required this.leave,
    this.onWithdraw,
  });

  String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${leave.leaveType} Leave',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${leave.totalDays} Day(s) • ${leave.duration}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              LeaveStatusChip(status: leave.status),
            ],
          ),
          const SizedBox(height: 16),
          _detail(
            Icons.calendar_month_outlined,
            leave.startDate == leave.endDate
                ? formatDate(leave.startDate)
                : '${formatDate(leave.startDate)} - ${formatDate(leave.endDate)}',
          ),
          const SizedBox(height: 10),
          _detail(Icons.description_outlined, leave.reason),
          const SizedBox(height: 14),
          if (onWithdraw != null)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onWithdraw,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Withdraw'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
