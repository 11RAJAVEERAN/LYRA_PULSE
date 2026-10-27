
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:geolocator/geolocator.dart';
import '../../attendance/views/face_verification_screen.dart';

import '../../attendance/views/location_verification_screen.dart';
import '../../../app/theme/app_colors.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../calendar/views/calendar_screen.dart';
import '../../leave/views/leave_screen.dart';
import '../../notification/views/notification_screen.dart';
import '../../permission/permission_screen.dart';
import '../../profile/views/profile_screen.dart';

import '../widgets/hold_to_confirm_button.dart';

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
  backgroundColor: AppColors.transparent,
  builder: (sheetContext) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 19),
      decoration: const BoxDecoration(
        color: AppColors.white,
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
                  foregroundColor: AppColors.white,
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

    return months[month - 1];
  }

  String get _dateLabel {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
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

  String get _workingTime {
    try {
      return attendanceController.formattedWorkingDuration;
    } catch (_) {
      return '00:00:00';
    }
  }

  String get _breakTime {
    try {
      return attendanceController.formattedBreakDuration;
    } catch (_) {
      return '00h 00m';
    }
  }

  bool get _isCheckedIn => attendanceController.isCheckedIn;

  DateTime? get _checkInTime => attendanceController.checkInTime.value;


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



// Future<void> _attendanceAction() async {
//   final checkingOut = _isCheckedIn;

//   if (checkingOut && _checkInTime == null) {
//     Get.snackbar(
//       'Attendance',
//       'Please check in before checking out.',
//       snackPosition: SnackPosition.BOTTOM,
//     );
//     return;
//   }




//   try {
//     // Check whether location service is enabled.
//     final serviceEnabled =
//         await Geolocator.isLocationServiceEnabled();

//     if (!serviceEnabled) {
//       Get.snackbar(
//         'Location Required',
//         'Please turn on your phone location.',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     // Check and request location permission.
//     var permission = await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       Get.snackbar(
//         'Permission Required',
//         'Allow location permission to continue.',
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     // Verify that the current GPS location can be obtained.
//     await Geolocator.getCurrentPosition(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//       ),
//     );

//     if (!mounted) return;

//     // Skip the Location Verification page.
//     // Continue directly to face verification.
//     await Get.to(
//       () => FaceVerificationScreen(
//         isCheckOut: checkingOut,
//       ),
//       transition: Transition.rightToLeft,
//       duration: const Duration(milliseconds: 350),
//     );

//     if (mounted) {
//       setState(() {});
//     }
//   } catch (_) {
//     Get.snackbar(
//       'Location Error',
//       'Unable to verify your location. Please try again.',
//       snackPosition: SnackPosition.BOTTOM,
//     );
//   }
// }





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
      drawer: _buildDrawer(),

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
  backgroundColor: AppColors.white,
  strokeWidth: 3,
  displacement: 45,
  edgeOffset: 0,
onRefresh: () async {
  await Future.delayed(
    const Duration(milliseconds: 800),
  );

  if (mounted) {
    setState(() {});
  }
},
  child: CustomScrollView(
    physics: const ClampingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    slivers: [
      SliverToBoxAdapter(child: _buildHeader()),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _buildDateSelector(),
            const SizedBox(height: 14),
            _buildWorkingCard(),
            const SizedBox(height: 17),
            _buildSectionTitle(),
            const SizedBox(height: 10),
            _buildActivityCard(),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    ],
  ),
)





















        ],
      ),
    ),

    CalendarScreen(),
    LeaveScreen(),
    const PermissionScreen(),
  ],
),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildAttendanceButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: .08),
            AppColors.secondary.withValues(alpha: .02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => Material(
              color: AppColors.white.withValues(alpha: .78),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Scaffold.of(context).openDrawer(),
                child: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Icon(
                    Icons.menu_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.sidebarMuted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'USER NAME',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _openPage(5),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(
                  Icons.notifications,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tap the date to expand/collapse the inline monthly calendar.
  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                setState(() {
                  _showMonthlyCalendar = !_showMonthlyCalendar;
                  _displayedMonth = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                  );
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.secondary,
                      size: 21,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _dateLabel,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      _showMonthlyCalendar
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_showMonthlyCalendar) ...[
          const SizedBox(height: 12),
          _buildMonthlyCalendar(),
        ],
      ],
    );
  }

  Widget _buildMonthlyCalendar() {
    final firstDay = DateTime(
      _displayedMonth.year,
      _displayedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    ).day;

    final startingOffset = firstDay.weekday - 1;
    final today = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () {
                  setState(() {
                    _displayedMonth = DateTime(
                      _displayedMonth.year,
                      _displayedMonth.month - 1,
                    );
                  });
                },
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: Text(
                  '${_monthName(_displayedMonth.month)} ${_displayedMonth.year}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () {
                  setState(() {
                    _displayedMonth = DateTime(
                      _displayedMonth.year,
                      _displayedMonth.month + 1,
                    );
                  });
                },
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final weekday in [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ])
                Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startingOffset + daysInMonth,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < startingOffset) {
                return const SizedBox.shrink();
              }

              final day = index - startingOffset + 1;
              final date = DateTime(
                _displayedMonth.year,
                _displayedMonth.month,
                day,
              );

              final isSelected =
                  date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              final isToday =
                  date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;

              return Material(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      _showMonthlyCalendar = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primary)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            AppColors.secondaryDark,
            AppColors.secondaryDark,
            AppColors.secondaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -85,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: .09),
                  width: 2,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORKING HOURS',
                style: GoogleFonts.inter(
                  color: AppColors.white.withValues(alpha: .84),
                  fontSize: 12,
                
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _workingTime,
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.white.withValues(alpha: .9),
                    size: 17,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Hours worked today',
                    style: GoogleFonts.inter(
                      color: AppColors.white.withValues(alpha: .85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Obx(
                () => _infoRow(
                  Icons.coffee_rounded,
                  
                  'Total Break Time',
               
                  _breakTime,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: AppColors.white.withValues(alpha: .25),
                  height: 1,
                ),
              ),
              _infoRow(
                Icons.access_time_rounded,
                'Shift Timing',
                '08:00 am - 06:00 pm',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 37,
          height: 37,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.white, size: 25),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle() {
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
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard() {
    final checkIn = _checkInTime;
    final entries = <Widget>[];

    final sessions = attendanceController.breakSessions
        .where(
          (session) =>
              session.startTime.year == _now.year &&
              session.startTime.month == _now.month &&
              session.startTime.day == _now.day,
        )
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (checkIn != null &&
        checkIn.year == _now.year &&
        checkIn.month == _now.month &&
        checkIn.day == _now.day) {
      entries.add(
        _activityRow(
          _ActivityEntry(
            'Punch In',
            _time(checkIn),
            true,
          ),
        ),
      );
    }

    for (final session in sessions) {
      entries.add(
        _activityRow(
          _ActivityEntry(
            'Punch Out',
            _time(session.startTime),
            false,
          ),
        ),
      );

      entries.add(
        _buildBreakCard(
          session.durationAt(_now),
          session.isActive,
        ),
      );

      if (session.endTime != null) {
        entries.add(
          _activityRow(
            _ActivityEntry(
              'Punch In',
              _time(session.endTime),
              true,
            ),
          ),
        );
      }
    }

    if (entries.isEmpty) {
      entries.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 35,
                color: AppColors.textSecondary.withValues(alpha: .6),
              ),
              const SizedBox(height: 10),
              Text(
                'No attendance yet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check in to start your day',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AppColors.border.withValues(alpha: .75),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 17),
            entries[i],
          ],
        ],
      ),
    );
  }

  Widget _buildBreakCard(Duration duration, bool isActive) {
    final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    final label = minutes > 0
        ? '$minutes ${minutes == 1 ? 'Min' : 'Mins'} Break'
        : '$remainingSeconds ${remainingSeconds == 1 ? 'Sec' : 'Secs'} Break';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: AppColors.breakDivider,
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.breakBackground,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.breakBorder,
                width: 1.3,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.coffee_rounded,
                  size: 15,
                  color: AppColors.breakAccent,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    isActive ? '$label · Ongoing' : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.breakAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 1.3,
              color: AppColors.breakDivider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(_ActivityEntry entry) {
    final isIn = entry.isPunchIn;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isIn
                ? AppColors.attendanceInBackground
                : AppColors.attendanceOutBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIn ? Icons.login_rounded : Icons.logout_rounded,
            color: isIn
                ? AppColors.attendanceIn
                : AppColors.attendanceOut,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            entry.title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.black
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          entry.subtitle,
          textAlign: TextAlign.right,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Widget _buildLocationCard() {
    // return Container(
    //   padding: const EdgeInsets.all(13),
    //   decoration: BoxDecoration(
    //     color: Colors.white,
    //     borderRadius: BorderRadius.circular(20),
    //     border: Border.all(color: AppColors.border),
    //   ),
      // child: Row(
      //   children: [
      //     const Icon(
      //       Icons.location_on_outlined,
      //       color: AppColors.black,
      //       size: 20,
      //     ),
      //     const SizedBox(width: 12),
      //     Expanded(
      //       child: Column(
      //         crossAxisAlignment: CrossAxisAlignment.start,
              // children: [
              //   Text(
              //     'Location verification',
              //     style: GoogleFonts.inter(
              //       fontWeight: FontWeight.w500,
              //       color: AppColors.black,
              //     ),
              //   ),
                // const SizedBox(height: 4),
                // Text(
                //   'Your location is checked during attendance',
                //   style: GoogleFonts.inter(
                //     fontSize: 10,
                //     color: AppColors.textSecondary,
                //   ),
                // ),
          //     ],
          //   ),
          // ),
  //         const Icon(
  //           Icons.verified_user_outlined,
  //           color: Color(0xFF16A36A),
  //         ),
  //       ],
  //     ),
  //   );
  // }

Widget _buildAttendanceButton() {
  return HoldToConfirmButton(
    isCheckOut: _isCheckedIn,
    onConfirm: _attendanceAction,
  );
}

Widget _buildBottomNavigation() {
  return BottomAppBar(
    color: AppColors.white,
    elevation: 16,
    notchMargin: 7,
    shape: const CircularNotchedRectangle(),
    child: SizedBox(
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            Icons.home_rounded, 
          'Home', 0),

          _navItem(
            Icons.calendar_month_outlined,
            'Calendar',
            1,
          ),
          const SizedBox(width: 72),
          _navItem(Icons.beach_access_outlined, 'Leave', 2),
          _navItem(
            Icons.access_time_outlined,
            'Permission',
            3,
          ),
        ],
      ),
    ),
  );
}

Widget _navItem(
  IconData icon,
  String label,
  int index,
) {
  final bool isSelected = _selectedIndex == index;

  return InkWell(
    onTap: () => _selectTab(index),
    borderRadius: BorderRadius.circular(15),
    child: SizedBox(
      width: 66,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? AppColors.primaryBlue
                : AppColors.sidebarMuted,
            size: 23,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: isSelected
                  ? AppColors.secondary
                  : AppColors.sidebarMuted,
              fontWeight: isSelected
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}







  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 31,
                    backgroundColor: AppColors.white24,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppColors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    'Madhavan',
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Employee',
                    style: GoogleFonts.inter(
                      color: AppColors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _drawerItem(
              Icons.home_outlined,
              'Home',
              () => Get.back(),
            ),

            
            _drawerItem(
              Icons.calendar_month_outlined,
              'Attendance Calendar',
              () {
                Get.back();
                _openPage(0);
              },
            ),
            _drawerItem(
              Icons.beach_access_outlined,
              'Leave',
              () {
                Get.back();
                _openPage(1);
              },
            ),
            _drawerItem(
              Icons.request_quote_outlined,
              'Permission',
              () {
                Get.back();
                _openPage(2);
              },
            ),
            _drawerItem(
              Icons.notifications_none_rounded,
              'Notifications',
              () {
                Get.back();
                _openPage(3);
              },
            ),
            _drawerItem(
              Icons.person_outline_rounded,
              'Profile',
              () {
                Get.back();
                _openPage(4);
              },
            ),
            const Spacer(),
            _drawerItem(
              Icons.logout_rounded,
              'Logout',
              () {
                Get.back();
                Get.offAllNamed('/login');
              },
              color: AppColors.attendanceOut,
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color color = AppColors.textPrimary,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 22),
      dense: true,
    );
  }
}

class _ActivityEntry {
  const _ActivityEntry(
    this.title,
    this.subtitle,
    this.isPunchIn,
  );

  final String title;
  final String subtitle;
  final bool isPunchIn;
}
