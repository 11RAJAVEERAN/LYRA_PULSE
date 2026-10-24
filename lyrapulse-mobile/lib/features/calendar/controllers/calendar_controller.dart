import 'package:get/get.dart';

class CalendarController extends GetxController {
  final currentMonth = DateTime.now().obs;
  final selectedDate = DateTime.now().obs;
  final isCalendarView = true.obs;
  final selectedFilter = 'All Days'.obs;

  // Sample attendance data for October 2026.
  // Replace this map with API data when the backend is ready.
  final Map<String, String> attendanceStatus = {
    '2026-10-01': 'absent',
    '2026-10-02': 'absent',
    '2026-10-03': 'absent',
    '2026-10-04': 'absent',
    '2026-10-05': 'absent',
    '2026-10-06': 'absent',
    '2026-10-07': 'absent',
    '2026-10-08': 'present',
    '2026-10-09': 'present',
    '2026-10-10': 'weekOff',
    '2026-10-11': 'present',
    '2026-10-12': 'late',
    '2026-10-13': 'punchError',
    '2026-10-14': 'present',
    '2026-10-15': 'present',
    '2026-10-16': 'present',
    '2026-10-17': 'present',
    '2026-10-18': 'weekOff',
    '2026-10-19': 'upcoming',
    '2026-10-20': 'upcoming',
    '2026-10-21': 'upcoming',
    '2026-10-22': 'upcoming',
    '2026-10-23': 'upcoming',
    '2026-10-24': 'weekOff',
    '2026-10-25': 'weekOff',
    '2026-10-26': 'upcoming',
    '2026-10-27': 'upcoming',
    '2026-10-28': 'upcoming',
    '2026-10-29': 'upcoming',
    '2026-10-30': 'upcoming',
    '2026-10-31': 'weekOff',
  };

  DateTime get displayedMonth => currentMonth.value;

  int get daysInMonth {
    final month = currentMonth.value;
    return DateTime(month.year, month.month + 1, 0).day;
  }

  // Monday = 0, Tuesday = 1 ... Sunday = 6.
  int get firstWeekdayOffset {
    final month = currentMonth.value;
    return DateTime(month.year, month.month, 1).weekday - 1;
  }

  String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String statusForDay(int day) {
    final month = currentMonth.value;
    final date = DateTime(month.year, month.month, day);
    return attendanceStatus[dateKey(date)] ?? 'upcoming';
  }

  void previousMonth() {
    final month = currentMonth.value;
    currentMonth.value = DateTime(month.year, month.month - 1);
  }

  void nextMonth() {
    final month = currentMonth.value;
    currentMonth.value = DateTime(month.year, month.month + 1);
  }

  void selectDate(int day) {
    final month = currentMonth.value;
    selectedDate.value = DateTime(month.year, month.month, day);
  }

  void selectFullDate(DateTime date) {
    selectedDate.value = date;
  }

  void toggleView(bool calendarView) {
    isCalendarView.value = calendarView;
  }

  void changeFilter(String filter) {
    selectedFilter.value = filter;
  }

  String get monthTitle {
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

    final month = currentMonth.value;
    return '${months[month.month - 1]} ${month.year}';
  }

  String weekdayShort(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  String statusLabel(String status) {
    switch (status) {
      case 'present':
        return 'Present';
      case 'absent':
        return 'Absent';
      case 'leave':
        return 'On Leave';
      case 'halfDay':
        return 'Half Day';
      case 'weekOff':
        return 'Week Off';
      case 'holiday':
        return 'Holiday';
      case 'late':
        return 'Late';
      case 'punchError':
        return 'Punch Error';
      default:
        return 'Upcoming';
    }
  }

  List<int> get visibleDays {
    final days = List<int>.generate(daysInMonth, (index) => index + 1);
    final filter = selectedFilter.value;

    if (filter == 'All Days') return days;

    return days.where((day) {
      final status = statusForDay(day);
      return statusLabel(status) == filter;
    }).toList();
  }
}
