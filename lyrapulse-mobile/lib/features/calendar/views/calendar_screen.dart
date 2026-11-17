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
    backgroundColor: AppColors.secondarySoft,
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
      _buildRegularizationInfo(),
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
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }




Widget _buildHeader() {
  final now = DateTime.now();
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(
        bottom: BorderSide(
          color: AppColors.secondarySoft.withOpacity(0.6),
          width: 1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.secondarySoft.withOpacity(0.5),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        // Icon badge
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.calendar_month_rounded,
            size: 22,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),

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
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${months[now.month - 1]} ${now.year}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary.withOpacity(0.55),
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
          title: 'Attendance Data',
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
              color: AppColors.infoSurface,
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
        color: AppColors.infoSurface,
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
                  'Attendance status from Project A',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Only dates returned by the attendance API are marked. '
                  'Other day types are not provided by the current backend.',
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
