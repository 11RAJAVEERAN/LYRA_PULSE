import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/home_controller.dart';
import '../widgets/attendance_status_card.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/check_in_out_card.dart';
import '../widgets/home_bottom_navigation.dart';
import '../widgets/home_content.dart';
import '../widgets/location_status_card.dart';
import '../widgets/today_progress_card.dart';
import '../widgets/weekly_attendance.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Obx(
          () => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: HomeHeader(
                  employeeName: controller.employeeName.value,
                  designation: controller.designation.value,
                  employeeId: controller.employeeId.value,
                ),
              ),

              SliverToBoxAdapter(
                child: AttendanceStatusCard(
                  status: controller.attendanceStatus.value,
                  currentTime: controller.currentTime.value,
                  currentDate: controller.currentDate.value,
                  checkInTime: controller.checkInTime.value,
                  checkOutTime: controller.checkOutTime.value,
                  workingHours: controller.workingHours.value,
                  isCheckedIn: controller.isCheckedIn.value,
                ),
              ),

              const SliverToBoxAdapter(
                child: WeeklyAttendance(),
              ),

              SliverToBoxAdapter(
                child: LocationStatusCard(
                  isVerified:
                      controller.isLocationVerified.value,
                  locationName:
                      controller.locationName.value,
                  distance:
                      controller.locationDistance.value,
                ),
              ),

              SliverToBoxAdapter(
                child: CheckInOutCard(
                  isCheckedIn:
                      controller.isCheckedIn.value,
                  onCheckIn: controller.checkIn,
                  onCheckOut: controller.checkOut,
                ),
              ),

              SliverToBoxAdapter(
                child: TodayProgressCard(
                  progress: controller.progress.value,
                  workingHours:
                      controller.workingHours.value,
                  checkInTime:
                      controller.checkInTime.value,
                  totalShiftHours:
                      '${controller.totalShiftMinutes.value ~/ 60}h',
                ),
              ),

              SliverToBoxAdapter(
                child: AttendanceSummary(
                  present:
                      controller.presentDays.value,
                  absent:
                      controller.absentDays.value,
                  late:
                      controller.lateDays.value,
                  leave:
                      controller.leaveDays.value,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 30),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          const HomeBottomNavigation(),
    );
  }
}