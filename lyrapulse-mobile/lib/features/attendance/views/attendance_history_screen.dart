import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import 'package:lyrapulse_mobile/features/attendance/controllers/attendance_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/attendance_model.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  static const _customMonth = '__custom_month__';

  late final AttendanceController controller;
  late String selectedMonth;

  final List<String> months = List.generate(12, (index) {
    final date = DateTime(
      DateTime.now().year,
      DateTime.now().month - index,
    );
    return '${_monthName(date.month)} ${date.year}';
  });

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    selectedMonth = '${_monthName(now.month)} ${now.year}';

    controller = Get.isRegistered<AttendanceController>()
        ? Get.find<AttendanceController>()
        : Get.put(AttendanceController());

    _loadSelectedMonth();
  }

  static String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  static String _shortMonthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }

  static int _monthNumber(String monthName) {
    for (var month = 1; month <= 12; month++) {
      if (_monthName(month) == monthName) return month;
    }
    return 0;
  }

  static String _weekdayName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }

  void _loadSelectedMonth() {
    final parts = selectedMonth.split(' ');
    if (parts.length != 2) return;
    final month = _monthNumber(parts[0]);
    if (month == 0) return;
    final year = int.tryParse(parts[1]);
    if (year == null) return;
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1, 0);
    controller.loadHistory(startDate: start, endDate: end);
  }

  Future<void> _chooseAnotherMonth() async {
    final parts = selectedMonth.split(' ');
    final month = parts.length == 2 ? _monthNumber(parts[0]) : 0;
    final year = parts.length == 2 ? int.tryParse(parts[1]) : null;
    final initialDate =
        month > 0 && year != null ? DateTime(year, month) : DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate:
          initialDate.isAfter(DateTime.now()) ? DateTime.now() : initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Choose a date in the month',
    );
    if (selectedDate == null || !mounted) return;
    setState(() {
      selectedMonth = '${_monthName(selectedDate.month)} ${selectedDate.year}';
    });
    _loadSelectedMonth();
  }

  List<_AttendanceData> get selectedRecords {
    final result = <_AttendanceData>[];

    for (final record in controller.attendanceHistory) {
      final date = record.attendanceDate;
      if (date == null) continue;

      final recordMonth = '${_monthName(date.month)} ${date.year}';

      if (recordMonth != selectedMonth) continue;

      result.add(
        _AttendanceData(
          date: date.day.toString().padLeft(2, '0'),
          day: _weekdayName(date.weekday),
          month: _shortMonthName(date.month),
          checkIn: Formatters.time12(record.checkInAt),
          checkOut: Formatters.time12(record.checkOutAt),
          status: record.checkOutAt == null ? 'In progress' : 'Present',
          details: _recordDetails(record),
          duration: record.workingSeconds == null
              ? ''
              : Formatters.durationShort(
                  Duration(seconds: record.workingSeconds!)),
        ),
      );
    }

    return result;
  }

  static String _recordDetails(AttendanceHistoryRecord record) {
    final source = record.source.replaceAll('_', ' ').toLowerCase();
    final gps = record.checkInLocationVerified == null
        ? 'GPS not recorded'
        : record.checkInLocationVerified!
            ? 'GPS verified'
            : 'GPS unverified';
    final selfie =
        record.checkInPhotoAvailable ? 'Selfie on file' : 'No selfie';
    return '${source.isEmpty ? 'Attendance' : source} | $gps | $selfie';
  }

  static Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return AppColors.success;
      case 'In progress':
        return AppColors.warning;
      case 'Absent':
        return AppColors.error;
      case 'Leave':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  static Color _getStatusBackground(String status) {
    switch (status) {
      case 'Present':
        return AppColors.successBackground;
      case 'In progress':
        return AppColors.warningBackground;
      case 'Absent':
        return AppColors.errorBackground;
      case 'Leave':
        return AppColors.warningBackground;
      default:
        return AppColors.hover;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceMuted,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          'Attendance History',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: const Offset(0, 8),
                color: AppColors.surface,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (month) {
                  if (month == _customMonth) {
                    _chooseAnotherMonth();
                    return;
                  }
                  setState(() {
                    selectedMonth = month;
                  });
                  _loadSelectedMonth();
                },
                itemBuilder: (context) {
                  final options = months.contains(selectedMonth)
                      ? months
                      : [selectedMonth, ...months];
                  return [
                    ...options.map((month) {
                      final isSelected = month == selectedMonth;

                      return PopupMenuItem<String>(
                        value: month,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                month,
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                color: AppColors.primaryBlue,
                                size: 20,
                              ),
                          ],
                        ),
                      );
                    }),
                    const PopupMenuItem<String>(
                      value: _customMonth,
                      child: Text('Choose another month…'),
                    ),
                  ];
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.infoBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primaryBlue,
                          size: 25,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedMonth,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Your attendance summary',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'This Month',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final records = selectedRecords;
                final completed = records
                    .where((record) => record.status == 'Present')
                    .length;
                final open = records.length - completed;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final width = textScale > 1.25
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 20) / 3;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SizedBox(
                          width: width,
                          child: _SummaryCard(
                            title: 'Sessions',
                            value: records.length.toString(),
                            icon: Icons.check_circle_rounded,
                            background: AppColors.successBackground,
                            iconColor: AppColors.success,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _SummaryCard(
                            title: 'Completed',
                            value: completed.toString(),
                            icon: Icons.task_alt_rounded,
                            background: AppColors.successBackground,
                            iconColor: AppColors.success,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _SummaryCard(
                            title: 'Open',
                            value: open.toString(),
                            icon: Icons.event_busy_rounded,
                            background: AppColors.warningBackground,
                            iconColor: AppColors.warning,
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),
              const SizedBox(height: 25),
              Text(
                'Attendance Records',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                final records = selectedRecords;

                if (records.isEmpty) {
                  if (controller.isLoadingHistory.value) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (controller.historyError.value != null) {
                    return _HistoryError(
                      message: controller.historyError.value!,
                      onRetry: _loadSelectedMonth,
                    );
                  }
                  return _EmptyAttendanceState(
                    month: selectedMonth,
                  );
                }

                return Column(
                  children: [
                    ...records.map((record) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AttendanceCard(
                          date: record.date,
                          day: record.day,
                          month: record.month,
                          checkIn: record.checkIn,
                          checkOut: record.checkOut,
                          status: record.status,
                          details: record.details,
                          duration: record.duration,
                          statusColor: _getStatusColor(record.status),
                          statusBackground: _getStatusBackground(record.status),
                        ),
                      );
                    }),
                    if (controller.historyError.value != null)
                      _HistoryError(
                        message: controller.historyError.value!,
                        onRetry: _loadSelectedMonth,
                      ),
                    if (controller.isLoadingHistory.value)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    if (controller.historyHasNext.value)
                      TextButton(
                        onPressed: controller.isLoadingHistory.value
                            ? null
                            : () => controller.loadHistory(append: true),
                        child: const Text('Load more'),
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceData {
  final String date;
  final String day;
  final String month;
  final String checkIn;
  final String checkOut;
  final String status;
  final String details;
  final String duration;

  const _AttendanceData({
    required this.date,
    required this.day,
    required this.month,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.details,
    required this.duration,
  });
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color background;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 19,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final String date;
  final String day;
  final String month;
  final String checkIn;
  final String checkOut;
  final String status;
  final String details;
  final String duration;
  final Color statusColor;
  final Color statusBackground;

  const _AttendanceCard({
    required this.date,
    required this.day,
    required this.month,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.details,
    required this.duration,
    required this.statusColor,
    required this.statusBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.hover,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      month,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  day,
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _PunchTime(
                icon: Icons.login_rounded,
                label: 'In',
                value: checkIn,
                color: AppColors.success,
              ),
              _PunchTime(
                icon: Icons.logout_rounded,
                label: 'Out',
                value: checkOut,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            duration.isEmpty ? details : '$details · $duration',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PunchTime extends StatelessWidget {
  const _PunchTime({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 5),
          Text(
            '$label  $value',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        decoration: BoxDecoration(
          color: AppColors.errorBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: AppColors.errorDark,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

class _EmptyAttendanceState extends StatelessWidget {
  final String month;

  const _EmptyAttendanceState({
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primaryBlue,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No attendance records',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No attendance data available for $month.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
