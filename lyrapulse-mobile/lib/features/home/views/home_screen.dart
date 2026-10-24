
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../widgets/welcome_header.dart';
import '../widgets/home_drawer.dart';
import '../widgets/bottom_nav_bar.dart';

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

  int _selectedIndex = 2;

  late final AttendanceController attendanceController;

  @override
  void initState() {
    super.initState();

    attendanceController =
        Get.isRegistered<AttendanceController>()
            ? Get.find<AttendanceController>()
            : Get.put(AttendanceController(), permanent: true);
  }

  // Fingerprint action flow:
  // 1. Not checked in -> Office Check In.
  // 2. Checked in, before 6:30 PM -> Start Break.
  // 3. Break active -> End Break and resume working time.
  // 4. At/after 6:30 PM, with no active break -> Office Check Out.
  Future<void> _handleFingerprintAction() async {
    if (attendanceController.isCompleted) {
      Get.snackbar(
        'Attendance Completed',
        'Today attendance is already completed.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // First action: Office Check In.
    if (!attendanceController.isCheckedIn) {
      Get.to(
        () => const LocationVerificationScreen(isCheckOut: false),
      );
      return;
    }

    // If a break is active, this action ends the break.
    // Working time resumes after the break is successfully ended.
    if (attendanceController.activeBreak != null) {
      Get.snackbar(
        'Break Check In',
        'Processing your return from break...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      final error = await attendanceController.endBreak();

      if (error != null) {
        Get.snackbar(
          'Break Check In Failed',
          error,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Welcome Back',
          'Your break has ended. Working time resumed.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return;
    }

    final now = DateTime.now();

    final officeClosingTime = DateTime(
      now.year,
      now.month,
      now.day,
      18,
      30,
    );

    // Before 6:30 PM, start a break.
    if (now.isBefore(officeClosingTime)) {
      final error = await attendanceController.startBreak('Break');

      if (error != null) {
        Get.snackbar(
          'Unable to Start Break',
          error,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Break Started',
          'Working time paused. Break timer started.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      return;
    }

    // At or after 6:30 PM, perform Office Check Out.
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

  void _onBottomNavChanged(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        _openAttendanceRecords();
        break;
      case 1:
        _openLeave();
        break;
      case 2:
        break;
      case 3:
        _openNotification();
        break;
      case 4:
        _openProfile();
        break;
    }
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

    return '${weekdays[now.weekday - 1]}, '
        '${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
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
        onLogoutTap: () {
          Get.back();
          Get.offAllNamed('/login');
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
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
                    _buildAttendanceOverview(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => BottomNavBar(
          selectedIndex: _selectedIndex,
          onChanged: _onBottomNavChanged,
          onFingerprintAction: () {
            _handleFingerprintAction();
          },
          isCheckedIn: attendanceController.isCheckedIn,
          isOnBreak: attendanceController.activeBreak != null,
          isCompleted: attendanceController.isCompleted,
        ),
      ),
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
                color: AppColors.white.withValues(alpha: 0.06),
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
                color: AppColors.white.withValues(alpha: 0.05),
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
                      color: AppColors.white.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(() {
                          final color =
                              attendanceController.isCompleted
                                  ? Colors.redAccent
                                  : attendanceController.activeBreak != null
                                      ? Colors.redAccent
                                      : attendanceController.isCheckedIn
                                          ? AppColors.hexFF65F4A4
                                          : AppColors.white;

                          return Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                        const SizedBox(width: 7),
                        Text(
                          'ATTENDANCE',
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      _getToday(),
                      textAlign: TextAlign.end,
                      style: GoogleFonts.inter(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Working Time',
                style: GoogleFonts.inter(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Obx(
                () => Text(
                  attendanceController.formattedWorkingDuration,
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 26,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Office Timing',
                            style: GoogleFonts.inter(
                              color: AppColors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '9:30 AM – 6:30 PM',
                            style: GoogleFonts.inter(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Obx(() {
                if (attendanceController.activeBreak == null) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 13),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.coffee_rounded,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Break in progress',
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        attendanceController.formatElapsedDuration(
                          attendanceController.activeBreakDuration,
                        ),
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceOverview() {
    return GestureDetector(
      onTap: _openAttendanceOverview,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Overview',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Today's attendance details",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 28,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _overviewItem(
                            icon: Icons.login_rounded,
                            title: 'Check In',
                            value: attendanceController.formatTime(
                              attendanceController.checkInTime.value,
                            ),
                            subtitle:
                                attendanceController.checkInTime.value == null
                                    ? 'Not checked in'
                                    : 'Office entry',
                            color: AppColors.success,
                          ),
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: Obx(
                          () => _overviewItem(
                            icon: Icons.logout_rounded,
                            title: 'Check Out',
                            value: attendanceController.formatTime(
                              attendanceController.checkOutTime.value,
                            ),
                            subtitle:
                                attendanceController.checkOutTime.value == null
                                    ? 'Not yet checked out'
                                    : 'Office exit',
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border.withValues(alpha: 0.7),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => _overviewItem(
                            icon: Icons.access_time_rounded,
                            title: 'Work Time',
                            value:
                                attendanceController.formattedWorkingDuration,
                            subtitle: 'Today',
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      _verticalDivider(),
                      Expanded(
                        child: Obx(
                          () => _overviewItem(
                            icon: Icons.coffee_rounded,
                            title: 'Break Time',
                            value: attendanceController.formatElapsedDuration(
                              attendanceController.totalBreakDuration,
                            ),
                            subtitle:
                                attendanceController.activeBreak != null
                                    ? 'Break running'
                                    : 'Today',
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View Attendance Details',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 108,
      color: AppColors.border.withValues(alpha: 0.65),
    );
  }

  Widget _overviewItem({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 19,
              color: color,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w500,
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
