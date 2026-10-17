import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lyrapulse_mobile/features/regularization/views/regularization_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color primaryBlue = Color(0xFF1769D2);
  static const Color backgroundColor = Color(0xFFF7FAFD);
  static const Color textColor = Color(0xFF253858);

  DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime? _selectedDate;

  final List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  void _changeMonth(int difference) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + difference,
      );

      _selectedDate = null;
    });
  }

  List<DateTime?> _getCalendarDates() {
    final firstDay = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    final firstWeekdayOffset = firstDay.weekday - 1;

    return List<DateTime?>.generate(42, (index) {
      final dayNumber = index - firstWeekdayOffset + 1;

      if (dayNumber < 1 || dayNumber > daysInMonth) {
        return null;
      }

      return DateTime(
        _visibleMonth.year,
        _visibleMonth.month,
        dayNumber,
      );
    });
  }

  void _openRegularization(DateTime date) {
    setState(() {
      _selectedDate = date;
    });

    Get.to(
      () => RegularizationScreen(
        selectedDate: date,
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Calendar',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Select a date to regularize attendance.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF8795A8),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFE4EAF2),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                tooltip: 'Previous month',
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: primaryBlue,
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                tooltip: 'Next month',
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCard() {
    final dates = _getCalendarDates();
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 18, 13, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE6ECF3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: _weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8795A8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dates.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 43,
            ),
            itemBuilder: (context, index) {
              final date = dates[index];

              if (date == null) {
                return const SizedBox.shrink();
              }

              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              final isSelected = _selectedDate != null &&
                  date.year == _selectedDate!.year &&
                  date.month == _selectedDate!.month &&
                  date.day == _selectedDate!.day;

              return Padding(
                padding: const EdgeInsets.all(2),
                child: InkWell(
                  onTap: () => _openRegularization(date),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryBlue
                          : isToday
                              ? const Color(0xFFEAF3FF)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected
                          ? Border.all(
                              color: primaryBlue,
                              width: 1,
                            )
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${date.day}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isToday || isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? primaryBlue
                                  : textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Today',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF8795A8),
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  border: Border.all(color: primaryBlue),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Current date',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: const Color(0xFF8795A8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.touch_app_rounded,
            size: 24,
            color: primaryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need to correct attendance?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Tap any date on the calendar. The selected '
                  'date will automatically appear on the '
                  'Regularization screen.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.6,
                    color: const Color(0xFF54708F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMonthHeader(),
              const SizedBox(height: 22),
              _buildMonthCard(),
              const SizedBox(height: 18),
              _buildInstructionCard(),
            ],
          ),
        ),
      ),
    );
  }
}