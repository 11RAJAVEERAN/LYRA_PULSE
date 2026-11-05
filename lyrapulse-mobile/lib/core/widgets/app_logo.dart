import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.onDark = false, this.compact = false});

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final titleStyle = (compact ? AppTextStyles.title : AppTextStyles.headline)
        .copyWith(color: onDark ? Colors.white : AppColors.textPrimary);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary]),
          ),
          child: Icon(Icons.bolt_rounded,
              color: Colors.white, size: compact ? 20 : 25),
        ),
        const SizedBox(width: 10),
        Text('Lyra Pulse', style: titleStyle),
      ],
    );
  }
}
