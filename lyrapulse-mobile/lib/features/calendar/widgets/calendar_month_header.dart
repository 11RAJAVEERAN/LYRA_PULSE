import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/calendar_controller.dart';

class CalendarMonthHeader extends StatelessWidget {
  final CalendarController controller;

  const CalendarMonthHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _arrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: controller.previousMonth,
        ),
        Expanded(
          child: Center(
            child: Text(
              controller.monthTitle,
              style:  GoogleFonts.inter(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        _arrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: controller.nextMonth,
        ),
      ],
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.infoSurface,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: AppColors.primaryBlue,
            size: 29,
          ),
        ),
      ),
    );
  }
}
