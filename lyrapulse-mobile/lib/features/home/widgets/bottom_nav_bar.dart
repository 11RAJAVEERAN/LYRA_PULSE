import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar(
      {required this.selectedIndex, required this.onChanged, super.key});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onChanged,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: .12),
        labelTextStyle: WidgetStatePropertyAll(
            AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon:
                  Icon(Icons.calendar_month_rounded, color: AppColors.primary),
              label: 'Attendance'),
          NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon:
                  Icon(Icons.description_rounded, color: AppColors.primary),
              label: 'Leave'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon:
                  Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profile'),
        ],
      );
}
