import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/calendar_controller.dart';

class AttendanceCalendarGrid extends StatelessWidget {
  final CalendarController controller;

  const AttendanceCalendarGrid({
    super.key,
    required this.controller,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.successBackground;
      case 'absent':
        return AppColors.errorBackground;
      case 'leave':
        return AppColors.secondarySoft;
      case 'halfDay':
        return AppColors.warningBackground;
      case 'weekOff':
        return AppColors.surfaceMuted;
      case 'holiday':
        return AppColors.infoSurface;
      case 'late':
      case 'punchError':
        return AppColors.warningBackground;
      default:
        return AppColors.surfaceMuted;
    }
  }

  Color _textColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.successDark;
      case 'absent':
        return AppColors.errorDark;
      case 'leave':
        return AppColors.secondaryDark;
      case 'halfDay':
      case 'late':
      case 'punchError':
        return AppColors.warningDark;
      case 'holiday':
        return AppColors.accent;
      case 'weekOff':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final offset = controller.firstWeekdayOffset;
    final totalDays = controller.daysInMonth;
    final cellCount = ((offset + totalDays + 6) ~/ 7) * 7;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children:
              ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
            return Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 0.88,
          ),
          itemBuilder: (context, index) {
            final day = index - offset + 1;

            if (day < 1 || day > totalDays) {
              return const SizedBox.shrink();
            }

            final month = controller.currentMonth.value;
            final date = DateTime(month.year, month.month, day);
            final selected = date.year == controller.selectedDate.value.year &&
                date.month == controller.selectedDate.value.month &&
                date.day == controller.selectedDate.value.day;
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;

            final status = controller.statusForDay(day);
            final baseColor = _statusColor(status);
            final baseTextColor = _textColor(status);

            return InkWell(
              onTap: () => controller.selectDate(day),
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: selected ? AppColors.infoSurface : baseColor,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryBlue
                        : isToday
                            ? AppColors.primaryBlue
                            : AppColors.border,
                    width: selected || isToday ? 1.8 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '$day',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: selected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.primaryBlue
                              : baseTextColor,
                        ),
                      ),
                    ),
                    if (status == 'late' || status == 'punchError')
                      Positioned(
                        bottom: 3,
                        left: 0,
                        right: 0,
                        child: Icon(
                          status == 'late'
                              ? Icons.access_time_rounded
                              : Icons.warning_amber_rounded,
                          size: 11,
                          color: AppColors.warning,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
