
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/calendar_controller.dart';
import '../widgets/attendance_calendar_grid.dart';
import '../widgets/attendance_day_list.dart';
import '../widgets/attendance_legend.dart';
import '../widgets/calendar_month_header.dart';
import '../widgets/calendar_view_toggle.dart';

class CalendarScreen extends StatelessWidget {
  CalendarScreen({super.key});

  final CalendarController controller =
      Get.isRegistered<CalendarController>()
          ? Get.find<CalendarController>()
          : Get.put(CalendarController());

  static const Color backgroundColor = Color(0xFFF7F9FC);
  static const Color primaryColor = Color(0xFF1677B8);
  static const Color textColor = Color(0xFF182638);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Obx(
          () => Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CalendarMonthHeader(controller: controller),
                      const SizedBox(height: 20),
                      const AttendanceDayList(),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Calendar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textColor,
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
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEDF0F4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080E2540),
                blurRadius: 18,
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
            const Expanded(
              child: Text(
                'Attendance Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
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
                  color: const Color(0xFFE8F4FB),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Filters',
                      style: TextStyle(
                        color: primaryColor,
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
        const AttendanceDayList(),
      ],
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 23),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
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
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7ECF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${date.day} ${controller.monthTitle}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  controller.statusLabel(status),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF758292),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF8C98A5),
          ),
        ],
      ),
    );
  }

  Widget _buildRegularizationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F3FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 25,
            color: primaryColor,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need to correct attendance?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Select a date to view its attendance status. '
                  'Regularization can be connected to your existing '
                  'regularization screen.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: Color(0xFF60758F),
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
