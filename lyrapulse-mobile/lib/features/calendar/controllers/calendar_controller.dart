
import 'package:get/get.dart';

class CalendarController extends GetxController {
  final currentMonth = DateTime.now().obs;
  final selectedDate = DateTime.now().obs;
  final isCalendarView = true.obs;
  final selectedFilter = 'All Days'.obs;

  // Sample attendance data for October 2026.
  // Replace this map with API data when the backend is ready.
 
final Map<String, Map<String, String>> attendanceDetails = {
  '2026-10-17': {
    'checkIn': '09:15 AM',
    'checkOut': '06:10 PM',
    'workingTime': '8h 55m',
    'regularization': 'Pending',
  },
  '2026-10-16': {
    'checkIn': '09:05 AM',
    'checkOut': '06:00 PM',
    'workingTime': '8h 55m',
    'regularization': 'None',
  },
};

final Map<String, String> attendanceStatus = {
  '2026-10-17': 'present',
  '2026-10-16': 'present',
};

String get selectedDateKey {
  final date = selectedDate.value;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}-$month-$day';
}

Map<String, String> get selectedAttendance {
  return attendanceDetails[selectedDateKey] ??
      {
        'checkIn': '--:--',
        'checkOut': '--:--',
        'workingTime': '--',
        'regularization': 'None',
      };
}

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
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
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
