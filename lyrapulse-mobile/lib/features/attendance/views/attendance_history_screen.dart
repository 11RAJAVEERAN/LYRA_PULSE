import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:lyrapulse_mobile/features/attendance/controllers/attendance_controller.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends State<AttendanceHistoryScreen> {
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

    controller.loadHistory();
  }

  static String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }

  static String _shortMonthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }

  static String _weekdayName(int weekday) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return names[weekday - 1];
  }

  List<_AttendanceData> get selectedRecords {
    final result = <_AttendanceData>[];

    for (final record in controller.attendanceHistory) {
      final date = DateTime.tryParse(
        record['date']?.toString() ?? '',
      );

      if (date == null) continue;

      final recordMonth = '${_monthName(date.month)} ${date.year}';

      if (recordMonth != selectedMonth) continue;

      final checkInString = record['checkIn']?.toString();
      final checkOutString = record['checkOut']?.toString();

      final checkIn = checkInString == null
          ? null
          : DateTime.tryParse(checkInString);

      final checkOut = checkOutString == null
          ? null
          : DateTime.tryParse(checkOutString);

      result.add(
        _AttendanceData(
          date: date.day.toString().padLeft(2, '0'),
          day: _weekdayName(date.weekday),
          month: _shortMonthName(date.month),
          checkIn: controller.formatTime(checkIn),
          checkOut: controller.formatTime(checkOut),
          status: 'Present',
        ),
      );
    }

    result.sort((a, b) {
      return int.parse(b.date).compareTo(int.parse(a.date));
    });

    return result;
  }

  static Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return const Color(0xFF22A06B);
      case 'Absent':
        return const Color(0xFFE05252);
      case 'Leave':
        return const Color(0xFFE39A18);
      default:
        return const Color(0xFF718096);
    }
  }

  static Color _getStatusBackground(String status) {
    switch (status) {
      case 'Present':
        return const Color(0xFFEAF8F1);
      case 'Absent':
        return const Color(0xFFFFEEEE);
      case 'Leave':
        return const Color(0xFFFFF4E3);
      default:
        return const Color(0xFFF1F6FA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFE),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF172B4D),
            size: 20,
          ),
        ),
        title: const Text(
          'Attendance History',
          style: TextStyle(
            color: Color(0xFF172B4D),
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
                color: Colors.white,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (month) {
                  setState(() {
                    selectedMonth = month;
                  });
                },
                itemBuilder: (context) {
                  return months.map((month) {
                    final isSelected = month == selectedMonth;

                    return PopupMenuItem<String>(
                      value: month,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              month,
                              style: TextStyle(
                                color: const Color(0xFF172B4D),
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
                              color: Color(0xFF1687D9),
                              size: 20,
                            ),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE5EBF2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
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
                          color: const Color(0xFFE8F5FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF1687D9),
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
                              style: const TextStyle(
                                color: Color(0xFF172B4D),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Your attendance summary',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF7B8798),
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
                        color: Color(0xFF718096),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'This Month',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              Obx(() {
                final records = selectedRecords;
                final present = records.length;

                return Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Present',
                        value: present.toString(),
                        icon: Icons.check_circle_rounded,
                        background: const Color(0xFFEAF8F1),
                        iconColor: const Color(0xFF22A06B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _SummaryCard(
                        title: 'Absent',
                        value: '0',
                        icon: Icons.cancel_rounded,
                        background: Color(0xFFFFEEEE),
                        iconColor: Color(0xFFE05252),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _SummaryCard(
                        title: 'Leave',
                        value: '0',
                        icon: Icons.event_busy_rounded,
                        background: Color(0xFFFFF4E3),
                        iconColor: Color(0xFFE39A18),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 25),

              const Text(
                'Attendance Records',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              Obx(() {
                final records = selectedRecords;

                if (records.isEmpty) {
                  return _EmptyAttendanceState(
                    month: selectedMonth,
                  );
                }

                return Column(
                  children: records.map((record) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AttendanceCard(
                        date: record.date,
                        day: record.day,
                        month: record.month,
                        checkIn: record.checkIn,
                        checkOut: record.checkOut,
                        status: record.status,
                        statusColor: _getStatusColor(record.status),
                        statusBackground:
                            _getStatusBackground(record.status),
                      ),
                    );
                  }).toList(),
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

  const _AttendanceData({
    required this.date,
    required this.day,
    required this.month,
    required this.checkIn,
    required this.checkOut,
    required this.status,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5EBF2),
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
            style: const TextStyle(
              color: Color(0xFF172B4D),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7B8798),
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
  final Color statusColor;
  final Color statusBackground;

  const _AttendanceCard({
    required this.date,
    required this.day,
    required this.month,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE5EBF2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  month,
                  style: const TextStyle(
                    color: Color(0xFF7B8798),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: const TextStyle(
                    color: Color(0xFF172B4D),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          color: Color(0xFF22A06B),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          checkIn,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFF1687D9),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          checkOut,
                          style: const TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE5EBF2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF1687D9),
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No attendance records',
            style: TextStyle(
              color: Color(0xFF172B4D),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No attendance data available for $month.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7B8798),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}