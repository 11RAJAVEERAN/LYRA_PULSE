import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({required this.onNotificationTap, super.key});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.accent,
          child: Text('R',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18))),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Good Morning, Rajaveeran 👋', style: AppTextStyles.title),
        SizedBox(height: 4),
        Text("Here's your today's overview", style: AppTextStyles.bodySmall),
      ])),
      IconButton(
          onPressed: onNotificationTap,
          style: IconButton.styleFrom(backgroundColor: AppColors.surface),
          icon: const Icon(Icons.notifications_none_rounded,
              color: AppColors.textPrimary)),
    ]);
  }
}
