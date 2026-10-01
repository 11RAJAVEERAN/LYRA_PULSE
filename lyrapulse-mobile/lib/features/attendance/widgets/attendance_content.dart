import 'package:flutter/material.dart';

class AttendanceContent extends StatelessWidget {
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int workingDays;

  const AttendanceContent({
    super.key,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.workingDays,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Attendance',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B1B1B),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Track your monthly attendance',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          // Summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    value: presentDays.toString(),
                    label: 'Present',
                    color: const Color(0xFF2E7D32),
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    value: absentDays.toString(),
                    label: 'Absent',
                    color: const Color(0xFFC62828),
                    icon: Icons.cancel_rounded,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    value: leaveDays.toString(),
                    label: 'Leave',
                    color: const Color(0xFFE65100),
                    icon: Icons.event_available_rounded,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    value: workingDays.toString(),
                    label: 'Working',
                    color: const Color(0xFF1565C0),
                    icon: Icons.work_history_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Attendance History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B1B1B),
            ),
          ),

          const SizedBox(height: 12),

          _AttendanceDay(
            date: '01 Oct 2026',
            day: 'Thursday',
            checkIn: '09:28 AM',
            checkOut: '06:32 PM',
            status: 'Present',
          ),

          _AttendanceDay(
            date: '30 Sep 2026',
            day: 'Wednesday',
            checkIn: '09:15 AM',
            checkOut: '06:20 PM',
            status: 'Present',
          ),

          _AttendanceDay(
            date: '29 Sep 2026',
            day: 'Tuesday',
            checkIn: '--',
            checkOut: '--',
            status: 'Leave',
          ),

          _AttendanceDay(
            date: '28 Sep 2026',
            day: 'Monday',
            checkIn: '--',
            checkOut: '--',
            status: 'Absent',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 25,
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AttendanceDay extends StatelessWidget {
  final String date;
  final String day;
  final String checkIn;
  final String checkOut;
  final String status;

  const _AttendanceDay({
    required this.date,
    required this.day,
    required this.checkIn,
    required this.checkOut,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPresent = status == 'Present';
    final bool isLeave = status == 'Leave';

    final Color statusColor = isPresent
        ? const Color(0xFF2E7D32)
        : isLeave
            ? const Color(0xFFE65100)
            : const Color(0xFFC62828);

    final Color statusBackground = isPresent
        ? const Color(0xFFE8F5E9)
        : isLeave
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPresent
                  ? Icons.check_rounded
                  : isLeave
                      ? Icons.event_available_rounded
                      : Icons.close_rounded,
              color: statusColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.login_rounded,
                      size: 14,
                      color: Color(0xFF777777),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      checkIn,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.logout_rounded,
                      size: 14,
                      color: Color(0xFF777777),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      checkOut,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}