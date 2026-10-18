import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/attendance_model.dart';
import '../../attendance/controllers/attendance_controller.dart';

/// "Today at a glance": four live tiles driven by the backend attendance state.
class TodayStatusCard extends GetView<AttendanceController> {
  const TodayStatusCard({super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final today = controller.today.value;
        final state = controller.state;
        final Color statusColor;
        switch (state) {
          case AttendanceState.checkedIn:
            statusColor = AppColors.success;
          case AttendanceState.checkedOut:
            statusColor = AppColors.info;
          case AttendanceState.notCheckedIn:
            statusColor = AppColors.warning;
          case null:
            statusColor = AppColors.textSecondary;
        }
        final hours = (state == null || today?.checkInAt == null)
            ? '--'
            : Formatters.durationShort(controller.workingDuration);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: _Tile(
                  icon: Icons.login_rounded,
                  label: 'Check In',
                  value: Formatters.time12(today?.checkInAt, placeholder: '--'),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Tile(
                  icon: Icons.logout_rounded,
                  label: 'Check Out',
                  value: Formatters.time12(today?.checkOutAt, placeholder: '--'),
                  color: AppColors.warning,
                ),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _Tile(
                  icon: Icons.timer_outlined,
                  label: 'Total Hours',
                  value: hours,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Tile(
                  icon: Icons.insights_rounded,
                  label: 'Status',
                  value: controller.statusLabel,
                  color: statusColor,
                ),
              ),
            ]),
          ]),
        );
      });
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.value, required this.color});

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        ),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      );
}
