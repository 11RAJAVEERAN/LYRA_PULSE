import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/leave_controller.dart';
import '../widgets/leave_content.dart';

class LeaveView extends GetView<LeaveController> {
  const LeaveView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      body: SafeArea(
        child: Obx(
          () => LeaveContent(
            totalLeave: controller.totalLeave.value,
            usedLeave: controller.usedLeave.value,
            remainingLeave: controller.remainingLeave.value,
            selectedLeaveType: controller.selectedLeaveType.value,
            leaveTypes: controller.leaveTypes,
            onLeaveTypeChanged: controller.selectLeaveType,
          ),
        ),
      ),
    );
  }
}