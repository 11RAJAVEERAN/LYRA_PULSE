
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

import '../widgets/welcome_header.dart';
import '../widgets/home_drawer.dart';




import 'package:lyrapulse_mobile/features/attendance/controllers/attendance_controller.dart';
import 'package:lyrapulse_mobile/features/attendance/views/location_verification_screen.dart';
import 'package:lyrapulse_mobile/features/attendance/views/attendance_history_screen.dart';
import 'package:lyrapulse_mobile/features/attendance/views/attendance_overview_screen.dart';
import 'package:lyrapulse_mobile/features/attendance/views/attendance_records_screen.dart';
import 'package:lyrapulse_mobile/features/permission/permission_screen.dart';
import 'package:lyrapulse_mobile/features/profile/views/profile_screen.dart';
import 'package:lyrapulse_mobile/features/leave/views/leave_screen.dart';
import 'package:lyrapulse_mobile/features/notification/views/notification_screen.dart';
import 'package:lyrapulse_mobile/features/calendar/views/calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;

  late final AttendanceController attendanceController;

  @override
  void initState() {
    super.initState();

    attendanceController =
        Get.isRegistered<AttendanceController>()
            ? Get.find<AttendanceController>()
            : Get.put(AttendanceController(), permanent: true);
  }

  void _openCheckIn() {
    if (attendanceController.isCheckedIn) {
      Get.snackbar(
        'Already Checked In',
        'You have already checked in.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (attendanceController.isCompleted) {
      Get.snackbar(
        'Attendance Completed',
        'Today attendance is already completed.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.to(
      () => const LocationVerificationScreen(isCheckOut: false),
    );
  }

  void _openCheckOut() {
    if (attendanceController.checkInTime.value == null) {
      Get.snackbar(
        'Check In Required',
        'Please check in before checking out.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (attendanceController.checkOutTime.value != null) {
      Get.snackbar(
        'Already Checked Out',
        'Your check out is already recorded.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.to(
      () => const LocationVerificationScreen(isCheckOut: true),
    );
  }

  void _openPermission() => Get.to(() => const PermissionScreen());

  void _openNotification() => Get.to(() => const NotificationScreen());

  void _openAttendanceHistory() =>
      Get.to(() => const AttendanceHistoryScreen());

  void _openAttendanceOverview() =>
      Get.to(() => const AttendanceOverviewScreen());

  void _openAttendanceRecords() =>
      Get.to(() => const AttendanceRecordsScreen());

  void _openLeave() => Get.to(() => const LeaveScreen());

  void _openProfile() => Get.to(() => const ProfileScreen());

  void _openCalendar() => Get.to(() => CalendarScreen());

  String _getToday() {
    final now = DateTime.now();

    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];

    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${weekdays[now.weekday - 1]}, '
        '${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: HomeDrawer(
        onHomeTap: () => Get.back(),
        onProfileTap: () {
          Get.back();
          _openProfile();
        },
        onNotificationTap: () {
          Get.back();
          _openNotification();
        },
        onAttendanceHistoryTap: () {
          Get.back();
          _openAttendanceHistory();
        },
        onCalendarTap: () {
          Get.back();
          _openCalendar();
        },
        onPermissionTap: () {
          Get.back();
          _openPermission();
        },
        onLeaveTap: () {
          Get.back();
          _openLeave();
        },
      ),
      backgroundColor: AppColors.background,
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
                  WelcomeHeader(
  onProfileTap: () {
    _scaffoldKey.currentState?.openDrawer();
  },
  onNotificationTap: _openNotification,
),
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


  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
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
                color: Colors.white.withValues(alpha: 0.06),
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
                color: Colors.white.withValues(alpha: 0.05),
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
                      color: Colors.white.withValues(alpha: 0.13),
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
                          style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Make today count.',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your attendance journey starts here.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.72),
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
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Check In',
                              style: GoogleFonts.inter(
                                color: AppColors.primary,
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
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
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
                              style: GoogleFonts.inter(
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
    return Obx(() {
      final checkIn = attendanceController.checkInTime.value;
      final checkOut = attendanceController.checkOutTime.value;

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
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    _timelineDot(
                      color: checkIn != null
                          ? AppColors.success
                          : AppColors.border,
                      icon: Icons.login_rounded,
                    ),
                    Container(
                      width: 2,
                      height: 38,
                      color: AppColors.border,
                    ),
                    _timelineDot(
                      color: checkOut != null
                          ? AppColors.success
                          : AppColors.border,
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
                        time: attendanceController.formatTime(checkIn),
                        active: checkIn != null,
                      ),
                      const SizedBox(height: 29),
                      _timelineRow(
                        title: 'Check Out',
                        subtitle: 'Office exit',
                        time: attendanceController.formatTime(checkOut),
                        active: checkOut != null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _timelineDot({
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 17),
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
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active
                ? AppColors.success
                : AppColors.textSecondary,
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
                iconColor: AppColors.secondary,
                onTap: _openPermission,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionItem(
                icon: Icons.history_rounded,
                title: 'History',
                subtitle: 'Attendance',
                iconColor: AppColors.primary,
                onTap: _openAttendanceHistory,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionItem(
                icon: Icons.beach_access_rounded,
                title: 'Leave',
                subtitle: 'Apply',
                iconColor: AppColors.warning,
                onTap: _openLeave,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionItem(
                icon: Icons.calendar_month_rounded,
                title: 'Calendar',
                subtitle: 'View',
                iconColor: AppColors.primary,
                onTap: _openCalendar,
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
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Obx(() {
      final checkIn = attendanceController.checkInTime.value;
      final checkOut = attendanceController.checkOutTime.value;
      final duration = attendanceController.workingDuration.value;

      final checkInParts =
          attendanceController.formatTime(checkIn).split(' ');
      final checkOutParts =
          attendanceController.formatTime(checkOut).split(' ');

      final hours = duration.inHours.toString().padLeft(2, '0');
      final minutes = duration.inMinutes.remainder(60)
          .toString().padLeft(2, '0');

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
                  value: checkIn == null ? '--:--' : checkInParts[0],
                  suffix: checkIn == null ? '' : checkInParts[1],
                  icon: Icons.login_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  title: 'Check Out',
                  value: checkOut == null ? '--:--' : checkOutParts[0],
                  suffix: checkOut == null ? '' : checkOutParts[1],
                  icon: Icons.logout_rounded,
                  color: AppColors.textSecondary,
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
                  value: checkIn == null ? '--:--' : '$hours:$minutes',
                  suffix: 'hrs',
                  icon: Icons.timer_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  title: 'Status',
                  value: attendanceController.attendanceStatus,
                  suffix: '',
                  icon: Icons.pending_actions_rounded,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      );
    });
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
        border: Border.all(color: AppColors.border),
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
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              const Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: AppColors.border,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textSecondary,
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
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    suffix,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
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
          border: Border.all(color: AppColors.border),
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
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '72%',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'month',
                        style: GoogleFonts.inter(
                          fontSize: 7,
                          color: AppColors.textSecondary,
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'View your attendance records and monthly progress.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Text(
                        'View Details',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: AppColors.primary,
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
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textSecondary,
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
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _bottomNavItem(
                index: 1,
                icon: Icons.calendar_month_rounded,
                label: 'Attendance',
                onTap: _openAttendanceRecords,
              ),
            ),
            Expanded(
              child: _bottomNavItem(
                index: 2,
                icon: Icons.beach_access_rounded,
                label: 'Leave',
                onTap: _openLeave,
              ),
            ),
            Expanded(
              child: _bottomNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
                onTap: () {},
              ),
            ),
            Expanded(
              child: _bottomNavItem(
                index: 3,
                icon: Icons.person_rounded,
                label: 'Profile',
                onTap: _openProfile,
              ),
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
        setState(() => _selectedIndex = index);
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: selected ? 8 : 4,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 21,
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              if (selected) ...[
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
