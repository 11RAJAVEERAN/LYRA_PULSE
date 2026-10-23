import 'package:flutter/material.dart';
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
        return const Color(0xFFDDF5E6);
      case 'absent':
        return const Color(0xFFFCE3E4);
      case 'leave':
        return const Color(0xFFEDE5FC);
      case 'halfDay':
        return const Color(0xFFFFF0D5);
      case 'weekOff':
        return const Color(0xFFEEF2F5);
      case 'holiday':
        return const Color(0xFFDDF4F5);
      case 'late':
      case 'punchError':
        return const Color(0xFFFFF0D5);
      default:
        return const Color(0xFFF7F9FB);
    }
  }

  Color _textColor(String status) {
    switch (status) {
      case 'present':
        return const Color(0xFF168347);
      case 'absent':
        return const Color(0xFFC82D38);
      case 'leave':
        return const Color(0xFF7845CF);
      case 'halfDay':
      case 'late':
      case 'punchError':
        return const Color(0xFFAD7400);
      case 'holiday':
        return const Color(0xFF087F8C);
      case 'weekOff':
        return const Color(0xFF788592);
      default:
        return const Color(0xFF233246);
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
                    style: TextStyle(
                      color: Color(0xFF84909C),
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
                  color: selected ? const Color(0xFFE7F3FF) : baseColor,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF1684B8)
                        : isToday
                            ? const Color(0xFF1684B8)
                            : const Color(0xFFE1E7ED),
                    width: selected || isToday ? 1.8 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF1677B8)
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
                          color: const Color(0xFFE69A0A),
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
