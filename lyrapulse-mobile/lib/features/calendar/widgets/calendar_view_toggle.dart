import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/calendar_controller.dart';

class CalendarViewToggle extends StatelessWidget {
  final CalendarController controller;

  const CalendarViewToggle({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        // color: AppColors.surfaceMuted,
        // borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton(
            icon: Icons.calendar_month_rounded,
            selected: controller.isCalendarView.value,
            onTap: () => controller.toggleView(true),
          ),
          _toggleButton(
            icon: Icons.format_list_bulleted_rounded,
            selected: !controller.isCalendarView.value,
            onTap: () => controller.toggleView(false),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 44,
        decoration: BoxDecoration(
          // color: selected ? AppColors.surface : AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
          size: 23,
        ),
      ),
    );
  }
}
