import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/attendance_model.dart';
import '../../attendance/controllers/attendance_controller.dart';

/// "Today" timeline: check-in and check-out as recorded by the backend.
class TodaySummaryCard extends GetView<AttendanceController> {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(color: AppColors.border)),
        child: Obx(() {
          final today = controller.today.value;
          final state = controller.state;
          final hasCheckIn = today?.checkInAt != null;
          final hasCheckOut = today?.checkOutAt != null;
          final String hint;
          if (state == null) {
            hint = controller.isLoadingToday.value ? 'Loading today\'s attendance…' : 'Attendance is unavailable right now.';
          } else if (state == AttendanceState.notCheckedIn) {
            hint = 'No attendance marked yet';
          } else if (state == AttendanceState.checkedIn) {
            hint = 'You are checked in';
          } else {
            hint = 'Attendance completed for today';
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Today', style: AppTextStyles.title)),
              Text(hint, style: AppTextStyles.bodySmall),
            ]),
            const SizedBox(height: 14),
            _TimelineRow(
              icon: Icons.login_rounded,
              title: 'Check In',
              subtitle: 'Branch entry',
              time: Formatters.time12(today?.checkInAt, placeholder: '--'),
              done: hasCheckIn,
              color: AppColors.success,
              showLine: true,
            ),
            _TimelineRow(
              icon: Icons.logout_rounded,
              title: 'Check Out',
              subtitle: 'Branch exit',
              time: Formatters.time12(today?.checkOutAt, placeholder: '--'),
              done: hasCheckOut,
              color: AppColors.warning,
              showLine: false,
            ),
            if ((today?.sessions.length ?? 0) > 1) ...[
              const SizedBox(height: 10),
              Text(
                today!.sessions.asMap().entries.map((entry) {
                  final session = entry.value;
                  final start = Formatters.time12(session.checkInAt, placeholder: '--');
                  final end = Formatters.time12(session.checkOutAt, placeholder: 'Open');
                  return '${entry.key + 1}. $start – $end';
                }).join('   •   '),
                style: AppTextStyles.bodySmall,
              ),
            ],
          ]);
        }),
      );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.done,
    required this.color,
    required this.showLine,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final bool done;
  final Color color;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final tone = done ? color : AppColors.disabled;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(
          width: 36,
          child: Column(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: tone.withValues(alpha: .12), shape: BoxShape.circle),
              child: Icon(icon, size: 17, color: tone),
            ),
            if (showLine)
              Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.border)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: showLine ? 14 : 4, top: 2),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppTextStyles.label),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ]),
              ),
              Text(time, style: AppTextStyles.label.copyWith(color: done ? AppColors.textPrimary : AppColors.textSecondary)),
            ]),
          ),
        ),
      ]),
    );
  }
}
