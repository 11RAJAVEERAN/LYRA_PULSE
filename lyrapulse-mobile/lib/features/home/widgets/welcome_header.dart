import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({
    required this.employeeName,
    required this.employeeCode,
    required this.onNotificationTap,
    this.onAvatarTap,
    super.key,
  });

  final String employeeName;
  final String employeeCode;
  final VoidCallback onNotificationTap;

  /// Opens the Home drawer when provided.
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      InkWell(
        onTap: onAvatarTap,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.accent,
            child: Text(employeeName.isEmpty ? 'E' : employeeName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18))),
      ),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome, $employeeName 👋', style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
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
