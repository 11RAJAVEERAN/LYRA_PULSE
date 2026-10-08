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
import 'package:lyrapulse_mobile/features/notification/views/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _openCheckIn() {
    Get.to(
      () => const LocationVerificationScreen(
        isCheckOut: false,
      ),
    );
  }

  void _openCheckOut() {
    Get.to(
      () => const LocationVerificationScreen(
        isCheckOut: true,
      ),
    );
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

  String _getToday() {
    final now = DateTime.now();

    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

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

    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFD),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildHeroSection(),
                    const SizedBox(height: 24),
                    _buildAttendanceTimeline(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildStatsSection(),
                    const SizedBox(height: 24),
                    _buildOverviewSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _openProfile,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFD7E7FA),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF1769D2),
              size: 27,
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning 👋',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7A899B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Angel',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF172B4D),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _openNotification,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF263B5A),
                    size: 25,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF5C5C),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1268D5),
            Color(0xFF084A9B),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1268D5).withOpacity(0.22),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -35,
            top: -40,
            child: Container(
              width: 145,
              height: 145,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -65,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF65F4A4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'ATTENDANCE',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _getToday(),
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Make today count.',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your attendance journey starts here.',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _openCheckIn,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.login_rounded,
                              color: Color(0xFF1268D5),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Check In',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1268D5),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _openCheckOut,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Check Out',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Today',
          subtitle: 'Attendance timeline',
          action: 'View',
          onTap: _openAttendanceHistory,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: const Color(0xFFE8EEF5),
            ),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  _timelineDot(
                    color: const Color(0xFF21B573),
                    icon: Icons.login_rounded,
                  ),
                  Container(
                    width: 2,
                    height: 38,
                    color: const Color(0xFFE4EAF1),
                  ),
                  _timelineDot(
                    color: const Color(0xFFB8C3D0),
                    icon: Icons.logout_rounded,
                  ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  children: [
                    _timelineRow(
                      title: 'Check In',
                      subtitle: 'Office entry',
                      time: '09:28 AM',
                      active: true,
                    ),
                    const SizedBox(height: 29),
                    _timelineRow(
                      title: 'Check Out',
                      subtitle: 'Office exit',
                      time: '-- : --',
                      active: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timelineDot({
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 17,
      ),
    );
  }

  Widget _timelineRow({
    required String title,
    required String subtitle,
    required String time,
    required bool active,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF253858),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF98A5B5),
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active
                ? const Color(0xFF21A66F)
                : const Color(0xFFA3ADBA),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          title: 'Quick Actions',
          subtitle: 'Everything you need',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _actionItem(
                icon: Icons.event_available_rounded,
                title: 'Permission',
                subtitle: 'Request',
                iconColor: const Color(0xFF8A5CF6),
                onTap: _openPermission,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionItem(
                icon: Icons.history_rounded,
                title: 'History',
                subtitle: 'Attendance',
                iconColor: const Color(0xFF1685D8),
                onTap: _openAttendanceHistory,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionItem(
                icon: Icons.beach_access_rounded,
                title: 'Leave',
                subtitle: 'Apply',
                iconColor: const Color(0xFFF39A3D),
                onTap: _openLeave,
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
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE8EEF5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF253858),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: const Color(0xFF98A5B5),
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
          title: 'Today at a glance',
          subtitle: 'Your live status',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Check In',
                value: '09:28',
                suffix: 'AM',
                icon: Icons.login_rounded,
                color: const Color(0xFF20A66F),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                title: 'Check Out',
                value: '--:--',
                suffix: '',
                icon: Icons.logout_rounded,
                color: const Color(0xFF7A8797),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                title: 'Total Hours',
                value: '--:--',
                suffix: 'hrs',
                icon: Icons.timer_outlined,
                color: const Color(0xFF2878D4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                title: 'Status',
                value: 'Pending',
                suffix: '',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFF19A3E),
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
    required String suffix,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8EEF5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: Color(0xFFB7C0CB),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFF8C99A9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF253858),
                  ),
                ),
              ),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    suffix,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8C99A9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return GestureDetector(
      onTap: _openAttendanceOverview,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE8EEF5),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: CircularProgressIndicator(
                      value: 0.72,
                      strokeWidth: 7,
                      backgroundColor: const Color(0xFFEAF0F7),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1769D2),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '72%',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF253858),
                        ),
                      ),
                      Text(
                        'month',
                        style: GoogleFonts.poppins(
                          fontSize: 7,
                          color: const Color(0xFF9AA6B5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Overview',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF253858),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'View your attendance records and monthly progress.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      height: 1.45,
                      color: const Color(0xFF8D9AAA),
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Text(
                        'View Details',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1769D2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Color(0xFF1769D2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required String title,
    required String subtitle,
    String? action,
    VoidCallback? onTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF172B4D),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF98A5B5),
                ),
              ),
            ],
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              action,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1769D2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      color: const Color(0xFFF7FAFD),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE6ECF3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomNavItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () {},
            ),
            _bottomNavItem(
              index: 1,
              icon: Icons.calendar_month_rounded,
              label: 'Attendance',
              onTap: _openAttendanceRecords,
            ),
            _bottomNavItem(
              index: 2,
              icon: Icons.event_note_rounded,
              label: 'Leave',
              onTap: _openLeave,
            ),
            _bottomNavItem(
              index: 3,
              icon: Icons.person_rounded,
              label: 'Profile',
              onTap: _openProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final selected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF3FF)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 21,
              color: selected
                  ? const Color(0xFF1769D2)
                  : const Color(0xFF9AA6B5),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1769D2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}