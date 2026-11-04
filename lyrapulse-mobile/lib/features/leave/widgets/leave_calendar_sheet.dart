import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../controllers/leave_controller.dart';

class LeaveCalendarSheet extends GetView<LeaveController> {
  const LeaveCalendarSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: Obx(() {
          final month = controller.calendarMonth.value;
          final firstWeekday =
              DateTime(month.year, month.month, 1).weekday % 7;
          final daysInMonth =
              DateUtils.getDaysInMonth(month.year, month.month);

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Leave Dates',
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => controller.changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${_monthName(month.month)} ${month.year}',
                    style:  GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => controller.changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style:  GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: firstWeekday + daysInMonth,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 5,
                  ),
                  itemBuilder: (context, index) {
                    if (index < firstWeekday) {
                      return const SizedBox();
                    }

                    final day = index - firstWeekday + 1;

                    final date = DateTime(
                      month.year,
                      month.month,
                      day,
                    );

                    final today = DateTime.now();
                    final isPast = DateUtils.dateOnly(date)
                        .isBefore(DateUtils.dateOnly(today));

                    final start = controller.startDate.value;
                    final end = controller.endDate.value;

                    final isStart = start != null &&
                        DateUtils.isSameDay(date, start);

                    final isEnd = end != null &&
                        DateUtils.isSameDay(date, end);

                    final isBetween = start != null &&
                        end != null &&
                        date.isAfter(start) &&
                        date.isBefore(end);

                    final selected = isStart || isEnd;

                    return GestureDetector(
                      onTap: isPast
                          ? null
                          : () => controller.selectDate(date),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryBlue
                              : isBetween
                                  ? AppColors.infoSurface
                                  : AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$day',
                          style: GoogleFonts.inter(
                            color: selected
                                ? AppColors.surface
                                : isPast
                                    ? AppColors.borderStrong
                                    : AppColors.primaryDark,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.hover,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Start: ${_formatDate(controller.startDate.value)}'
                  '   |   End: ${_formatDate(controller.endDate.value)}',
                  style:  GoogleFonts.inter(fontSize: 12),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.startDate.value != null &&
                              controller.endDate.value != null
                          ? () => Get.back()
                          : null,
                      child: const Text('Select Dates'),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '--';
    return '${date.day}/${date.month}/${date.year}';
  }
}