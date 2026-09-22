import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';

class QuickActionCard extends StatelessWidget {
  const QuickActionCard(
      {required this.icon,
      required this.title,
      required this.color,
      super.key});
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        onTap: () => Get.snackbar('Lyra Pulse', 'Coming Soon',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 14,
            backgroundColor: AppColors.primaryDark,
            colorText: Colors.white),
        child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                border: Border.all(color: AppColors.border)),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 19)),
                  Text(title, style: AppTextStyles.label)
                ])),
      );
}
