
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../attendance/views/location_verification_screen.dart';
import '../../calendar/views/calendar_screen.dart';
import '../../leave/views/leave_screen.dart';
import '../../notification/views/notification_screen.dart';
import '../../profile/views/profile_screen.dart';
import '../../menu/views/menu_screen.dart';

import '../../leave/bindings/leave_binding.dart';
import '../../leave/controllers/leave_controller.dart';

import '../widgets/hold_to_confirm_button.dart';
import '../widgets/home_header.dart';
import '../widgets/home_date_calendar.dart';
import '../widgets/home_working_card.dart';
import '../widgets/home_activity_card.dart';
import '../widgets/home_bottom_navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AttendanceController attendanceController;

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  bool _showMonthlyCalendar = false;
  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime.now();

  int _selectedIndex = 0;




@override
void initState() {
  super.initState();

  // Register Leave dependencies before IndexedStack builds.
  LeaveBinding().dependencies();

  if (Get.isRegistered<AttendanceController>()) {
    attendanceController = Get.find<AttendanceController>();
  } else {
    attendanceController = Get.put(AttendanceController());
  }

  _clockTimer = Timer.periodic(
    const Duration(seconds: 1),
    (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    },
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkLocationService();
  });
}






  Future<void> _checkLocationService() async {
    final isEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!mounted || isEnabled) return;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(17, 17, 17, 19),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    color: AppColors.primaryBlue,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Location is turned off',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please turn on your location to use '
                  'Lyra Pulse attendance features.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await Geolocator.openLocationSettings();
                    },
                    icon: const Icon(Icons.location_on_rounded),
                    label: const Text(
                      'Turn On Location',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return months[month - 1];
  }

  String get _dateLabel {
    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

    return '${weekdays[_selectedDate.weekday - 1]}, '
        '${_selectedDate.day} '
        '${_monthName(_selectedDate.month)} '
        '${_selectedDate.year}';
  }

  String _time(DateTime? value) {
    if (value == null) return '--:-- --';

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  bool get _isCheckedIn => attendanceController.isCheckedIn;

  DateTime? get _checkInTime =>
      attendanceController.checkInTime.value;

  Future<void> _attendanceAction() async {
    final checkingOut = _isCheckedIn;

    if (checkingOut && _checkInTime == null) {
      Get.snackbar(
        'Attendance',
        'Please check in before checking out.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await Get.to(
      () => LocationVerificationScreen(
        isCheckOut: checkingOut,
      ),
      transition: Transition.cupertino,
    );

    if (mounted) {
      setState(() {});
    }
  }

  void _selectTab(int index) {
    if (!mounted) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  void _openPage(int index) {
    switch (index) {
      case 0:
        _selectTab(0);
        break;
      case 1:
        _selectTab(1);
        break;
      case 2:
        _selectTab(2);
        break;
      case 3:
        _selectTab(3);
        break;
      case 4:
        Get.to(() => ProfileScreen());
        break;
      case 5:
        Get.to(() => NotificationScreen());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(
            bottom: false,
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -80,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: .03),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 3,
                  displacement: 45,
                  onRefresh: () async {
                    await Future.delayed(
                      const Duration(milliseconds: 800),
                    );

                    if (mounted) setState(() {});
                  },
                  child: CustomScrollView(
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: HomeHeader(
                          onNotificationTap: () => _openPage(5),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          16, 12, 16, 12,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            HomeDateCalendar(
                              dateLabel: _dateLabel,
                              selectedDate: _selectedDate,
                              displayedMonth: _displayedMonth,
                              showCalendar: _showMonthlyCalendar,
                              onToggle: () {
                                setState(() {
                                  _showMonthlyCalendar =
                                      !_showMonthlyCalendar;
                                  _displayedMonth = DateTime(
                                    _selectedDate.year,
                                    _selectedDate.month,
                                  );
                                });
                              },
                              onMonthChanged: (date) {
                                setState(() {
                                  _displayedMonth = date;
                                });
                              },
                              onDateSelected: (date) {
                                setState(() {
                                  _selectedDate = date;
                                  _showMonthlyCalendar = false;
                                });
                              },
                            ),
                            const SizedBox(height: 14),
                            HomeWorkingCard(
                              attendanceController: attendanceController,
                            ),
                            const SizedBox(height: 17),
                            const _ActivityTitle(),
                            const SizedBox(height: 10),
                            HomeActivityCard(
                              attendanceController: attendanceController,
                              now: _now,
                            ),
                            const SizedBox(height: 8),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          CalendarScreen(),
          LeaveScreen(),
        ],
      ),
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: _selectedIndex,
        onTabSelected: _selectTab,
        onMenuTap: () => Get.to(() => const MenuScreen()),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      floatingActionButton: HoldToConfirmButton(
        isCheckOut: _isCheckedIn,
        onConfirm: _attendanceAction,
      ),
    );
  }
}

class _ActivityTitle extends StatelessWidget {
  const _ActivityTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.show_chart_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          "Today's activity",
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
