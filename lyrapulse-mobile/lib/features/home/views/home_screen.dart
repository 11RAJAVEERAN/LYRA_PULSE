import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/home_controller.dart';
import '../widgets/attendance_summary.dart';
import '../widgets/check_in_out_card.dart';
import '../widgets/home_bottom_navigation.dart';
import '../widgets/home_top_section.dart';
import '../widgets/today_progress_card.dart';
import '../widgets/weekly_attendance.dart';
import 'check_out_screen.dart';
import 'location_verification_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // =====================================================
      // BODY
      // =====================================================

      body: SafeArea(
        bottom: false,
        child: Obx(
          () => RefreshIndicator(
            onRefresh: () async {
              await controller.startLiveLocation();
            },
            color: AppColors.primary,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // =================================================
                // HOME TOP SECTION
                // =================================================

                SliverToBoxAdapter(
                  child: HomeTopSection(
                    employeeName:
                        controller.employeeName.value,

                    designation:
                        controller.designation.value,

                    employeeId:
                        controller.employeeId.value,

                    status:
                        controller.attendanceStatus.value,

                    // LIVE CURRENT TIME
                    currentTime:
                        controller.currentTime.value,

                    // LIVE CURRENT DATE
                    currentDate:
                        controller.currentDate.value,

                    // ACTUAL CHECK-IN TIME
                    checkInTime:
                        controller.checkInTime.value,

                    // ACTUAL CHECK-OUT TIME
                    checkOutTime:
                        controller.checkOutTime.value,

                    // LIVE WORKING HOURS
                    workingHours:
                        controller.workingHours.value,
                  ),
                ),

                // =================================================
                // WEEKLY ATTENDANCE
                // =================================================

                const SliverToBoxAdapter(
                  child: WeeklyAttendance(),
                ),

                // =================================================
                // CHECK IN / CHECK OUT
                // =================================================

                SliverToBoxAdapter(
                  child: CheckInOutCard(
                    isCheckedIn:
                        controller.isCheckedIn.value,

                    // ACTUAL CHECK-IN TIME
                    checkInTime:
                        controller.checkInTime.value,

                    // ACTUAL CHECK-OUT TIME
                    checkOutTime:
                        controller.checkOutTime.value,

                    // -------------------------------------------------
                    // CHECK IN
                    // -------------------------------------------------

                    onCheckIn: () {
                      Get.to(
                        () => const LocationVerificationScreen(
                          isCheckOut: false,
                        ),
                      );
                    },

                    // -------------------------------------------------
                    // CHECK OUT
                    // -------------------------------------------------

                    onCheckOut: () {
                      Get.to(
                        () => const CheckOutScreen(),
                      );
                    },
                  ),
                ),

                // =================================================
                // TODAY PROGRESS
                // =================================================

                SliverToBoxAdapter(
                  child: TodayProgressCard(
                    progress:
                        controller.progress.value,

                    workingHours:
                        controller.workingHours.value,

                    checkInTime:
                        controller.checkInTime.value,

                    totalShiftHours:
                        '${HomeController.totalShiftMinutes ~/ 60}h',
                  ),
                ),

                // =================================================
                // ATTENDANCE SUMMARY
                // =================================================

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

                // =================================================
                // BOTTOM SPACE
                // =================================================

                const SliverToBoxAdapter(
                  child: SizedBox(height: 30),
                ),
              ],
            ),
          ),
        ),
      ),

      // =====================================================
      // BOTTOM NAVIGATION
      // =====================================================

      bottomNavigationBar:
          const HomeBottomNavigation(),
    );
  }
}