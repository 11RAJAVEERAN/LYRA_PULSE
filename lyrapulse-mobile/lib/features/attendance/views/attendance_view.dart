import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/attendance_controller.dart';
import '../widgets/attendance_content.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8F7),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B1B1B),
          ),
        ),
      ),
      body: Obx(
        () => AttendanceContent(
          presentDays: controller.presentDays.value,
          absentDays: controller.absentDays.value,
          leaveDays: controller.leaveDays.value,
          workingDays: controller.workingDays.value,
        ),
      ),
    );
  }
}