import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState
    extends State<AttendanceHistoryScreen> {
  // ==========================================================
  // SELECTED MONTH
  // ==========================================================

  String selectedMonth = 'October 2026';

  // ==========================================================
  // MONTH LIST
  // ==========================================================

  final List<String> months = [
    'October 2026',
    'September 2026',
    'August 2026',
    'July 2026',
    'June 2026',
    'May 2026',
  ];

  // ==========================================================
  // ATTENDANCE RECORDS
  // ==========================================================

  final List<_AttendanceData> records = const [
    _AttendanceData(
      date: '06',
      day: 'Monday',
      month: 'Oct',
      yearMonth: 'October 2026',
      checkIn: '09:12 AM',
      checkOut: '06:04 PM',
      status: 'Present',
    ),
    _AttendanceData(
      date: '05',
      day: 'Sunday',
      month: 'Oct',
      yearMonth: 'October 2026',
      checkIn: '09:18 AM',
      checkOut: '06:10 PM',
      status: 'Present',
    ),
    _AttendanceData(
      date: '04',
      day: 'Saturday',
      month: 'Oct',
      yearMonth: 'October 2026',
      checkIn: '09:05 AM',
      checkOut: '05:52 PM',
      status: 'Present',
    ),
    _AttendanceData(
      date: '03',
      day: 'Friday',
      month: 'Oct',
      yearMonth: 'October 2026',
      checkIn: '—',
      checkOut: '—',
      status: 'Absent',
    ),
    _AttendanceData(
      date: '02',
      day: 'Thursday',
      month: 'Oct',
      yearMonth: 'October 2026',
      checkIn: '09:10 AM',
      checkOut: '06:02 PM',
      status: 'Present',
    ),
    _AttendanceData(
      date: '01',
      day: 'Wednesday',
      month: 'Oct',
      yearMonth: 'October 2026',
      checkIn: '—',
      checkOut: '—',
      status: 'Leave',
    ),
  ];

  // ==========================================================
  // GET SELECTED MONTH RECORDS
  // ==========================================================

  List<_AttendanceData> get selectedRecords {
    return records
        .where(
          (record) => record.yearMonth == selectedMonth,
        )
        .toList();
  }

  // ==========================================================
  // SUMMARY COUNT
  // ==========================================================

  int get presentCount {
    return selectedRecords
        .where((record) => record.status == 'Present')
        .length;
  }

  int get absentCount {
    return selectedRecords
        .where((record) => record.status == 'Absent')
        .length;
  }

  int get leaveCount {
    return selectedRecords
        .where((record) => record.status == 'Leave')
        .length;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),

      // ========================================================
      // APP BAR
      // ========================================================

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

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // MONTH DROPDOWN
              // ==================================================

              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                offset: const Offset(0, 8),

                color: Colors.white,

                elevation: 8,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                onSelected: (String month) {
                  setState(() {
                    selectedMonth = month;
                  });
                },

                itemBuilder: (context) {
                  return months.map(
                    (month) {
                      final bool isSelected =
                          month == selectedMonth;

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
                    },
                  ).toList();
                },

                // ==================================================
                // MONTH HEADER CARD
                // ==================================================

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(
                      color: const Color(0xFFE5EBF2),
                      width: 1,
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
                    crossAxisAlignment:
                        CrossAxisAlignment.center,
                    children: [
                      // ------------------------------------------
                      // CALENDAR ICON
                      // ------------------------------------------

                      Container(
                        width: 48,
                        height: 48,

                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5FF),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),

                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF1687D9),
                          size: 25,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // ------------------------------------------
                      // MONTH + SUBTITLE
                      // ------------------------------------------

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedMonth,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
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
                              overflow:
                                  TextOverflow.ellipsis,
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

                      // ------------------------------------------
                      // DROPDOWN ICON
                      // ------------------------------------------

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

              // ==================================================
              // THIS MONTH
              // ==================================================

              const Text(
                'This Month',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // SUMMARY CARDS
              // ==================================================

              Row(
                children: [
                  // PRESENT
                  Expanded(
                    child: _SummaryCard(
                      title: 'Present',
                      value: presentCount.toString(),
                      icon: Icons.check_circle_rounded,
                      background:
                          const Color(0xFFEAF8F1),
                      iconColor:
                          const Color(0xFF22A06B),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ABSENT
                  Expanded(
                    child: _SummaryCard(
                      title: 'Absent',
                      value: absentCount.toString(),
                      icon: Icons.cancel_rounded,
                      background:
                          const Color(0xFFFFEEEE),
                      iconColor:
                          const Color(0xFFE05252),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // LEAVE
                  Expanded(
                    child: _SummaryCard(
                      title: 'Leave',
                      value: leaveCount.toString(),
                      icon: Icons.event_busy_rounded,
                      background:
                          const Color(0xFFFFF4E3),
                      iconColor:
                          const Color(0xFFE39A18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ==================================================
              // ATTENDANCE RECORDS TITLE
              // ==================================================

              const Text(
                'Attendance Records',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // RECORDS / EMPTY STATE
              // ==================================================

              if (selectedRecords.isEmpty)
                _EmptyAttendanceState(
                  month: selectedMonth,
                )
              else
                ...selectedRecords.map(
                  (record) {
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: 12),
                      child: _AttendanceCard(
                        date: record.date,
                        day: record.day,
                        month: record.month,
                        checkIn: record.checkIn,
                        checkOut: record.checkOut,
                        status: record.status,
                        statusColor:
                            _getStatusColor(
                          record.status,
                        ),
                        statusBackground:
                            _getStatusBackground(
                          record.status,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

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

  // ============================================================
  // STATUS BACKGROUND
  // ============================================================

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
}

// ================================================================
// ATTENDANCE DATA
// ================================================================

class _AttendanceData {
  final String date;
  final String day;
  final String month;
  final String yearMonth;
  final String checkIn;
  final String checkOut;
  final String status;

  const _AttendanceData({
    required this.date,
    required this.day,
    required this.month,
    required this.yearMonth,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });
}

// ================================================================
// SUMMARY CARD
// ================================================================

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
          // ICON
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

          // VALUE
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF172B4D),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 2),

          // TITLE
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

// ================================================================
// ATTENDANCE CARD
// ================================================================

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
          // ======================================================
          // DATE BOX
          // ======================================================

          Container(
            width: 55,
            height: 62,

            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FA),
              borderRadius: BorderRadius.circular(14),
            ),

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
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

          // ======================================================
          // ATTENDANCE DETAILS
          // ======================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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

                Row(
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      color: Color(0xFF22A06B),
                      size: 15,
                    ),

                    const SizedBox(width: 5),

                    Flexible(
                      child: Text(
                        checkIn,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF1687D9),
                      size: 15,
                    ),

                    const SizedBox(width: 5),

                    Flexible(
                      child: Text(
                        checkOut,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ======================================================
          // STATUS
          // ======================================================

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

// ================================================================
// EMPTY ATTENDANCE STATE
// ================================================================

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

          Text(
            'No attendance records',
            style: const TextStyle(
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