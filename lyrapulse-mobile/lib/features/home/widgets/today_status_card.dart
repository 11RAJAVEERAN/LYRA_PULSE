import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';

class TodayStatusCard extends StatelessWidget {
  const TodayStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A172033), blurRadius: 24, offset: Offset(0, 8))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Today's Status", style: AppTextStyles.title),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(30)),
              child: Text('Present',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.success, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 22),
        const Row(children: [
          _StatusMetric(
              icon: Icons.login_rounded, label: 'Check In', value: '09:28 AM'),
          _StatusMetric(
              icon: Icons.logout_rounded, label: 'Check Out', value: '--'),
          _StatusMetric(
              icon: Icons.access_time_rounded,
              label: 'Working Hours',
              value: '--'),
        ]),
      ]),
    );
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 9),
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.label)
      ]));
}
