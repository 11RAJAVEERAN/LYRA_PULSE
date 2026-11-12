import 'package:get/get.dart';

import '../../attendance/controllers/attendance_controller.dart';
import '../../../data/models/attendance_model.dart';

class CalendarController extends GetxController {
  final currentMonth = DateTime.now().obs;
  final selectedDate = DateTime.now().obs;
  final isCalendarView = true.obs;
  final selectedFilter = 'All Days'.obs;
  final attendanceStatus = <String, String>{}.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  late final AttendanceController _attendance;

  @override
  void onInit() {
    super.onInit();
    _attendance = Get.find<AttendanceController>();
    loadMonth();
  }

  Future<void> loadMonth() async {
    isLoading.value = true;
    errorMessage.value = null;
    final month = currentMonth.value;
    final start = DateTime(month.year, month.month);
    final todayDate = DateTime.now();
    final lastDay = DateTime(month.year, month.month + 1, 0);
    if (start.isAfter(DateTime(todayDate.year, todayDate.month, todayDate.day))) {
      attendanceStatus.clear();
      isLoading.value = false;
      return;
    }
    final end = lastDay.isAfter(todayDate)
        ? DateTime(todayDate.year, todayDate.month, todayDate.day)
        : lastDay;
    await _attendance.loadHistory(startDate: start, endDate: end);

    final records = _attendance.attendanceHistory;
    if (_attendance.historyError.value != null) {
      errorMessage.value = _attendance.historyError.value;
      isLoading.value = false;
      return;
    }

    final loaded = <String, String>{};
    for (final record in records) {
      final date = record.attendanceDate;
      if (date == null) continue;
      if (record.status == 'CHECKED_IN' || record.status == 'CHECKED_OUT') {
        loaded[dateKey(date)] = 'present';
      }
    }

    // Today's endpoint is authoritative for an open or completed session
    // that may not yet appear in the history range.
    final today = _attendance.today.value;
    if (today?.attendanceDate != null &&
        (today!.state == AttendanceState.checkedIn ||
            today.state == AttendanceState.checkedOut)) {
      loaded[dateKey(today.attendanceDate!)] = 'present';
    }
    attendanceStatus.assignAll(loaded);
    isLoading.value = false;
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
    return attendanceStatus[dateKey(date)] ?? 'noData';
  }

  void previousMonth() {
    final month = currentMonth.value;
    currentMonth.value = DateTime(month.year, month.month - 1);
    loadMonth();
  }

  void nextMonth() {
    final month = currentMonth.value;
    currentMonth.value = DateTime(month.year, month.month + 1);
    loadMonth();
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
      case 'noData':
        return 'No attendance data';
      default:
        return 'No attendance data';
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
