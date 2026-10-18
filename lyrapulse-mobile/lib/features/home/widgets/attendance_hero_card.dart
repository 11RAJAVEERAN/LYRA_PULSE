import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/attendance_model.dart';
import '../../attendance/controllers/attendance_controller.dart';

/// Hero card: live working time (from the backend check-in time) and the
/// Check In / Check Out actions. Everything shown comes from AttendanceController.
class AttendanceHeroCard extends GetView<AttendanceController> {
  const AttendanceHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius + 6),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Obx(() {
        final state = controller.state;
        final hasError = controller.todayError.value != null;
        final loading = controller.isLoadingToday.value;
        final showTimer = state != null;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _Pill(
              dot: state == AttendanceState.checkedIn ? AppColors.success : AppColors.sidebarMuted,
              label: controller.statusLabel.toUpperCase(),
            ),
            const Spacer(),
            Text(
              Formatters.dayLabel(DateTime.now()),
              style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: .75), fontWeight: FontWeight.w600),
            ),
          ]),
          const SizedBox(height: 16),
          Text('Working time',
              style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: .85))),
          const SizedBox(height: 4),
          Text(
            showTimer ? Formatters.durationHms(controller.workingDuration) : '--:--:--',
            style: AppTextStyles.display.copyWith(
              color: Colors.white,
              fontSize: 34,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white.withValues(alpha: .85)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  showTimer ? 'Couldn\'t refresh attendance.' : (controller.todayError.value ?? ''),
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: .85)),
                ),
              ),
              TextButton(
                onPressed: loading ? null : controller.refreshToday,
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white, minimumSize: const Size(0, 30), padding: const EdgeInsets.symmetric(horizontal: 8)),
                child: const Text('Retry'),
              ),
            ]),
          ],
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.login_rounded,
                label: 'Check In',
                enabled: controller.canCheckIn,
                onTap: () => controller.startFlow(AttendanceAction.checkIn),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.logout_rounded,
                label: 'Check Out',
                enabled: controller.canCheckOut,
                onTap: () => controller.startFlow(AttendanceAction.checkOut),
              ),
            ),
          ]),
        ]);
      }),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.dot, required this.label});

  final Color dot;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
        ]),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.enabled, required this.onTap});

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled ? AppColors.primary : Colors.white.withValues(alpha: .55);
    return Material(
      color: enabled ? Colors.white : Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          height: 48,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 19, color: foreground),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.label.copyWith(color: foreground, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}
