import 'package:get/get.dart';

class LeaveController extends GetxController {
  // Leave balance
  final totalLeave = 12.obs;
  final usedLeave = 4.obs;
  final remainingLeave = 8.obs;

  // Leave request fields
  final selectedLeaveType = 'Casual Leave'.obs;
  final fromDate = ''.obs;
  final toDate = ''.obs;
  final reason = ''.obs;

  // Leave types
  final leaveTypes = <String>[
    'Casual Leave',
    'Sick Leave',
    'Annual Leave',
  ];

  void selectLeaveType(String type) {
    selectedLeaveType.value = type;
  }

  void selectFromDate(String date) {
    fromDate.value = date;
  }

  void selectToDate(String date) {
    toDate.value = date;
  }

  void updateReason(String value) {
    reason.value = value;
  }

  void submitLeaveRequest() {
    // Leave API will be connected later.
  }
}