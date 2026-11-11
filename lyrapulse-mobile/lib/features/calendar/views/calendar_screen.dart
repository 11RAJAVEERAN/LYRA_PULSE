import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../controllers/calendar_controller.dart';
import '../widgets/attendance_calendar_grid.dart';
import '../widgets/attendance_day_list.dart';
import '../widgets/attendance_legend.dart';
import '../widgets/calendar_month_header.dart';
import '../widgets/calendar_view_toggle.dart';

class CalendarScreen extends StatelessWidget {
  CalendarScreen({super.key});

  final CalendarController controller = Get.isRegistered<CalendarController>()
      ? Get.find<CalendarController>()
      : Get.put(CalendarController());


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondarySoft,
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CalendarMonthHeader(controller: controller),
                      const SizedBox(height: 20),
                      if (controller.isCalendarView.value)
                        _buildCalendarContent()
                      else
                        _buildListContent(),
                      const SizedBox(height: 22),
                      _buildRegularizationInfo(),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      decoration: const BoxDecoration(
        // color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.secondarySoft,
            blurRadius: 5,
            // offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Calendar',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          CalendarViewToggle(controller: controller),
        ],
      ),
    );
  }

  Widget _buildCalendarContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.borderStrong,
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: AttendanceCalendarGrid(controller: controller),
        ),
        const SizedBox(height: 18),
        const AttendanceLegend(),
        const SizedBox(height: 28),
        _buildSectionTitle(
          icon: Icons.event_note_rounded,
          title: 'Pending Regularization',
        ),
        const SizedBox(height: 12),
        _buildSelectedDateCard(),
      ],
    );
  }

  Widget _buildListContent() {
    const filters = [
      'All Days',
      'Present',
      'Absent',
      'On Leave',
      'Half Day',
      'Week Off',
      'Holiday',
      'Late',
      'Punch Error',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Attendance Records',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Filter attendance',
              initialValue: controller.selectedFilter.value,
              onSelected: controller.changeFilter,
              itemBuilder: (context) => filters.map((filter) {
                return PopupMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoBackground,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Filters',
                      style: GoogleFonts.inter(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AttendanceDayList(controller: controller),
      ],
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 23),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style:  GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateCard() {
    final date = controller.selectedDate.value;
    final status = controller.statusForDay(date.day);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day} ${controller.monthTitle}',
                  style:  GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  controller.statusLabel(status),
                  style:  GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildRegularizationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 25,
            color: AppColors.primaryBlue,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need to correct attendance?',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Select a date to view its attendance status. '
                  'Regularization can be connected to your existing '
                  'regularization screen.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
