import 'package:get/get.dart';

class AttendanceController extends GetxController {
  // Selected month
  final selectedMonth = 'October 2026'.obs;

  // Attendance summary
  final presentDays = 22.obs;
  final absentDays = 2.obs;
  final leaveDays = 1.obs;
  final workingDays = 25.obs;

  // Selected attendance date
  final selectedDate = ''.obs;

  void selectDate(String date) {
    selectedDate.value = date;
  }

  void previousMonth() {
    // Month navigation will be connected later.
  }

  void nextMonth() {
    // Month navigation will be connected later.
  }
}