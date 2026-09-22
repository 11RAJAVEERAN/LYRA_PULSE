import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) => CircularProgressIndicator(
      strokeWidth: 2.5, color: onDark ? Colors.white : AppColors.primary);
}
