import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lyrapulse_mobile/features/attendance/views/location_verification_screen.dart';
import 'package:lyrapulse_mobile/features/attendance/views/attendance_history_screen.dart';
import 'package:lyrapulse_mobile/features/attendance/views/attendance_overview_screen.dart';
import 'package:lyrapulse_mobile/features/attendance/views/attendance_records_screen.dart';
import 'package:lyrapulse_mobile/features/permission/permission_screen.dart';
import 'package:lyrapulse_mobile/features/profile/views/profile_screen.dart';
import 'package:lyrapulse_mobile/features/leave/views/leave_screen.dart';
import 'package:lyrapulse_mobile/features/notifications/views/notifications_view.dart';
import 'package:lyrapulse_mobile/features/calendar/views/calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _openCheckIn() {
    Get.to(() => const LocationVerificationScreen());
  }

  void _openCheckOut() {
    Get.to(() => const LocationVerificationScreen());
  }

  void _openPermission() {
    Get.to(() => const PermissionScreen());
  }

  void _openNotification() {
    Get.to(() => const NotificationScreen());
  }

  void _openAttendanceHistory() {
    Get.to(() => const AttendanceHistoryScreen());
  }

  void _openAttendanceOverview() {
    Get.to(() => const AttendanceOverviewScreen());
  }

  void _openAttendanceRecords() {
    Get.to(() => const AttendanceRecordsScreen());
  }

  void _openLeave() {
    Get.to(() => const LeaveScreen());
  }

  void _openProfile() {
    Get.to(() => const ProfileScreen());
  }

  void _openCalendar() {
    Get.to(() => const CalendarScreen());
  }

  String _getToday() {
    final now = DateTime.now();

    const months = [
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

    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildHeroSection(),
              const SizedBox(height: 24),
              _buildAttendanceTimeline(),
              const SizedBox(height: 28),
              _buildQuickActions(),
              const SizedBox(height: 28),
              _buildStatsSection(),
              const SizedBox(height: 28),
              _buildOverviewSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning 👋',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF778399),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Angel',
                style: GoogleFonts.inter(
                  fontSize: 25,
                  color: const Color(0xFF172B4D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _getToday(),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF8793A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: _openNotification,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8EDF4),
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF23395B),
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: _openProfile,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EEFA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF1769AA),
              size: 25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF173F78),
            Color(0xFF1769AA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1769AA).withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Attendance',
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF61E7B1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Today',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Stay consistent. Make every workday count.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.78),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: _heroInfo(
                  icon: Icons.login_rounded,
                  label: 'CHECK IN',
                  value: '--:--',
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withOpacity(0.22),
              ),
              Expanded(
                child: _heroInfo(
                  icon: Icons.logout_rounded,
                  label: 'CHECK OUT',
                  value: '--:--',
                ),
              ),
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withOpacity(0.22),
              ),
              Expanded(
                child: _heroInfo(
                  icon: Icons.schedule_rounded,
                  label: 'TOTAL HOURS',
                  value: '00h 00m',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _openCheckIn,
                    icon: const Icon(
                      Icons.login_rounded,
                      size: 18,
                    ),
                    label: Text(
                      'Check In',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1769AA),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _openCheckOut,
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                    ),
                    label: Text(
                      'Check Out',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.55),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.82),
            size: 19,
          ),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 8,
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTimeline() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE9EEF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today\'s Timeline',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF172B4D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: _openAttendanceHistory,
                child: Text(
                  'History',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF1769AA),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _timelineRow(
            icon: Icons.login_rounded,
            title: 'Check In',
            subtitle: 'Start your workday',
            time: '--:--',
            color: const Color(0xFF22A879),
            isLast: false,
          ),
          _timelineRow(
            icon: Icons.logout_rounded,
            title: 'Check Out',
            subtitle: 'Complete your workday',
            time: '--:--',
            color: const Color(0xFF1769AA),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineDot(Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.circle,
        size: 9,
        color: color,
      ),
    );
  }

  Widget _timelineRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required bool isLast,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _timelineDot(color),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 28,
                  color: const Color(0xFFE4EAF2),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF243752),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF8A96A8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF718096),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Quick Actions',
          'Everything you need',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _actionItem(
                icon: Icons.calendar_month_rounded,
                title: 'Attendance',
                subtitle: 'View records',
                color: const Color(0xFF1769AA),
                onTap: _openAttendanceRecords,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionItem(
                icon: Icons.event_available_rounded,
                title: 'Apply Leave',
                subtitle: 'Request time off',
                color: const Color(0xFF7657C8),
                onTap: _openLeave,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionItem(
                icon: Icons.fact_check_rounded,
                title: 'Permission',
                subtitle: 'Request permission',
                color: const Color(0xFFDB8A2B),
                onTap: _openPermission,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _actionItem(
                icon: Icons.insights_rounded,
                title: 'Overview',
                subtitle: 'Attendance insights',
                color: const Color(0xFF22A879),
                onTap: _openAttendanceOverview,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE9EEF5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF203550),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF8793A6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'Attendance Stats',
          'Your performance',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Present Days',
                value: '22',
                subtitle: 'This month',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF22A879),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                title: 'Leave Days',
                value: '02',
                subtitle: 'This month',
                icon: Icons.event_busy_rounded,
                color: const Color(0xFFDB8A2B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE9EEF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF7D899B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 19,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              color: const Color(0xFF203550),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF8A96A8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE9EEF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            'Monthly Overview',
            'October 2026',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _overviewItem(
                  label: 'Working Days',
                  value: '23',
                ),
              ),
              Expanded(
                child: _overviewItem(
                  label: 'Present',
                  value: '22',
                ),
              ),
              Expanded(
                child: _overviewItem(
                  label: 'Absent',
                  value: '01',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.85,
              minHeight: 8,
              backgroundColor: Color(0xFFEAF0F7),
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(0xFF1769AA),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '85% attendance completion',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF7D899B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openAttendanceOverview,
              child: Text(
                'View Details',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1769AA),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewItem({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            color: const Color(0xFF203550),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF8793A6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  color: const Color(0xFF172B4D),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF8793A6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE8EDF4),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _bottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                onTap: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
            ),
            Expanded(
              child: _bottomNavItem(
                icon: Icons.fact_check_rounded,
                label: 'Attendance',
                index: 1,
                onTap: _openAttendanceRecords,
              ),
            ),
            Expanded(
              child: _bottomNavItem(
                icon: Icons.calendar_month_rounded,
                label: 'IPO Calendar',
                index: 2,
                onTap: _openCalendar,
              ),
            ),
            Expanded(
              child: _bottomNavItem(
                icon: Icons.event_available_rounded,
                label: 'Leave',
                index: 3,
                onTap: _openLeave,
              ),
            ),
            Expanded(
              child: _bottomNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 4,
                onTap: _openProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });

        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 5,
          horizontal: 1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: isSelected
                  ? const Color(0xFF1769AA)
                  : const Color(0xFF9AA5B5),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: isSelected
                    ? const Color(0xFF1769AA)
                    : const Color(0xFF9AA5B5),
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 16 : 4,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1769AA)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}