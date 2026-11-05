import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/attendance_model.dart';

/// Accent for an attendance action, from the app theme tokens.
Color attendanceAccent(AttendanceAction action) =>
    action == AttendanceAction.checkIn ? AppColors.primaryBlue : AppColors.warning;

String attendanceTitle(AttendanceAction action) =>
    action == AttendanceAction.checkIn ? 'Check In' : 'Check Out';

/// Back button, title and "Step x of y" progress shared by the flow screens.
class FlowHeader extends StatelessWidget {
  const FlowHeader({
    required this.action,
    required this.step,
    required this.subtitle,
    this.totalSteps = 3,
    this.onDark = false,
    super.key,
  });

  final AttendanceAction action;
  final int step;
  final int totalSteps;
  final String subtitle;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? Colors.white : AppColors.textPrimary;
    final mutedColor = onDark ? AppColors.sidebarText : AppColors.textSecondary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        IconButton(
          onPressed: Get.back,
          style: IconButton.styleFrom(
              backgroundColor: onDark ? AppColors.sidebarHover : AppColors.surface),
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(attendanceTitle(action),
                style: AppTextStyles.title.copyWith(color: textColor)),
            Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: mutedColor)),
          ]),
        ),
        Text('Step $step of $totalSteps',
            style: AppTextStyles.bodySmall.copyWith(color: mutedColor, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        for (var index = 1; index <= totalSteps; index++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: index <= step
                    ? attendanceAccent(action)
                    : (onDark ? AppColors.sidebarDivider : AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (index != totalSteps) const SizedBox(width: 6),
        ],
      ]),
    ]);
  }
}

class FlowCard extends StatelessWidget {
  const FlowCard({required this.child, this.padding = const EdgeInsets.all(18), super.key});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class FlowInfoRow extends StatelessWidget {
  const FlowInfoRow({required this.icon, required this.label, required this.value, super.key});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label),
          ),
        ]),
      );
}

/// Inline error / warning banner built from the status tokens.
class FlowBanner extends StatelessWidget {
  const FlowBanner({required this.message, this.isError = true, super.key});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.warningDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isError ? AppColors.errorBackground : AppColors.warningBackground,
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: AppTextStyles.bodySmall.copyWith(color: color))),
      ]),
    );
  }
}
