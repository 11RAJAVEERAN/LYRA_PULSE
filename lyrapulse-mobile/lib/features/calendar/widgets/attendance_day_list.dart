import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../controllers/calendar_controller.dart';

class AttendanceDayList extends StatelessWidget {
  final CalendarController controller;

  /// Date click pannum pothu andha date-oda home page open panna
  final void Function(DateTime date)? onDateTap;

  const AttendanceDayList({
    super.key,
    required this.controller,
    this.onDateTap,
  });

  static const _knownStatuses = {
    'present',
    'absent',
    'leave',
    'halfDay',
    'late',
    'punchError',
    'holiday',
    'weekOff',
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return AppColors.success;
      case 'absent':
        return AppColors.error;
      case 'leave':
        return AppColors.secondary;
      case 'halfDay':
      case 'late':
      case 'punchError':
        return AppColors.warning;
      case 'holiday':
        return AppColors.accent;
      case 'weekOff':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Past date + no valid attendance record => Absent
  String _effectiveStatus(DateTime date, String status) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isBefore(today) && !_knownStatuses.contains(status)) {
      return 'absent';
    }
    return status;
  }

  @override
  Widget build(BuildContext context) {
    final days = controller.visibleDays;

    if (days.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 42,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              'No attendance records found',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: days.map((day) {
        final month = controller.currentMonth.value;
        final date = DateTime(month.year, month.month, day);
        final status = _effectiveStatus(date, controller.statusForDay(day));
        final isAbsent = status == 'absent';
        final color = _statusColor(status);
        final selected = controller.selectedDate.value.year == date.year &&
            controller.selectedDate.value.month == date.month &&
            controller.selectedDate.value.day == date.day;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                controller.selectDate(day);
                onDateTap?.call(date);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected
                        ? AppColors.primaryBlue
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    // Date box (absent na mattum solid red)
                    Container(
                      width: 56,
                      height: 62,
                      decoration: BoxDecoration(
                        color: isAbsent
                            ? AppColors.error
                            : color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$day',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isAbsent ? Colors.white : color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.weekdayShort(date),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isAbsent
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.statusLabel(status),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${controller.monthTitle} • ${controller.weekdayShort(date)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: color,
                      size: 25,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}