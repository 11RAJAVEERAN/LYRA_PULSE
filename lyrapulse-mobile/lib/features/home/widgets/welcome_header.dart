import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({required this.employeeName, required this.employeeCode, required this.onNotificationTap, super.key});

  final String employeeName;
  final String employeeCode;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.accent,
          child: Text(employeeName.isEmpty ? 'E' : employeeName.substring(0, 1).toUpperCase(),
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18))),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome, $employeeName 👋', style: AppTextStyles.title),
        SizedBox(height: 4),
        Text(employeeCode.isEmpty ? 'Employee account' : 'Employee ID: $employeeCode', style: AppTextStyles.bodySmall),
      ])),
      IconButton(
          onPressed: onNotificationTap,
          style: IconButton.styleFrom(backgroundColor: AppColors.surface),
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppColors.textPrimary)),
    ]);
  }
}
