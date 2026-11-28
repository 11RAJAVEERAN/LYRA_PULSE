import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';
import '../../../app/widgets/fixed_header_page.dart';
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
    return FixedHeaderPage(
      backgroundColor: AppColors.surface,
      header: _buildHeader(),
      pinned: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: CalendarMonthHeader(controller: controller),
      ),
      children: [
        Obx(() {
          if (controller.isLoading.value) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.errorMessage.value != null) return _buildLoadError();
          return controller.isCalendarView.value
              ? _buildCalendarContent()
              : _buildListContent();
        }),
        const SizedBox(height: 22),
        // _buildRegularizationInfo(),
      ],
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              controller.errorMessage.value!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: controller.loadMonth,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('Try again', style: GoogleFonts.inter()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // final now = DateTime.now();
    // const months = [
    //   'January',
    //   'February',
    //   'March',
    //   'April',
    //   'May',
    //   'June',
    //   'July',
    //   'August',
    //   'September',
    //   'October',
    //   'November',
    //   'December'
    // ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.secondarySoft.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondarySoft.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Calendar',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
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
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.borderStrong,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: AttendanceCalendarGrid(controller: controller),
        ),
        const SizedBox(height: 18),
        const AttendanceLegend(),
        const SizedBox(height: 28),
        // _buildSectionTitle(
        //   icon: Icons.event_note_rounded,
        //   title: 'Attendance Data',
        // ),
        const SizedBox(height: 12),
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
                  child: Text(filter, style: GoogleFonts.inter()),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
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

}
