import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../attendance/views/attendance_screen.dart';
import '../../leave/views/leave_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;

  String? checkInTime;
  String? checkOutTime;

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  // ===============================================================
  // CHECK IN
  // ===============================================================

  void _checkIn() {
    final now = TimeOfDay.now();

    final formattedTime = now.format(context);

    setState(() {
      checkInTime = formattedTime;
    });

    Get.toNamed(
      AppRoutes.locationVerification,
    );
  }

  // ===============================================================
  // CHECK OUT
  // ===============================================================

  void _checkOut() {
    if (checkInTime == null) {
      Get.snackbar(
        'Check In Required',
        'Please complete your check in before checking out.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF102A40),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(
          Icons.info_outline_rounded,
          color: Color(0xFF20DDF7),
        ),
      );
      return;
    }

    final now = TimeOfDay.now();

    setState(() {
      checkOutTime = now.format(context);
    });

    Get.snackbar(
      'Check Out',
      'Check out recorded at $checkOutTime',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF102A40),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: Color(0xFF20DDF7),
      ),
    );
  }

  // ===============================================================
  // PERMISSION
  // ===============================================================

  void _openPermission() {
    Get.toNamed(
      AppRoutes.permissionStart,
    );
  }

  // ===============================================================
  // PERMISSION RETURN
  // ===============================================================

  void _openPermissionReturn() {
    Get.toNamed(
      AppRoutes.permissionReturn,
    );
  }

  // ===============================================================
  // ATTENDANCE
  // ===============================================================

  void _openAttendance() {
    setState(() {
      selectedIndex = 1;
    });

    Get.to(
      () => const AttendanceScreen(),
    );
  }

  // ===============================================================
  // LEAVE
  // ===============================================================

  void _openLeave() {
    setState(() {
      selectedIndex = 2;
    });

    Get.to(
      () => const _FeaturePage(
        title: 'Leave',
        subtitle: 'Manage your leave requests',
        icon: Icons.event_available_rounded,
      ),
    );
  }

  // ===============================================================
  // PROFILE
  // ===============================================================

  void _openProfile() {
    setState(() {
      selectedIndex = 3;
    });

    Get.to(
      () => const _FeaturePage(
        title: 'Profile',
        subtitle: 'View your employee profile',
        icon: Icons.person_outline_rounded,
      ),
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),
      body: SafeArea(
        child: Stack(
          children: [
            // =======================================================
            // BACKGROUND GLOW
            // =======================================================

            Positioned(
              top: -180,
              right: -150,
              child: _glow(
                390,
                const Color(0xFF087BFF),
              ),
            ),

            Positioned(
              bottom: -220,
              left: -170,
              child: _glow(
                420,
                const Color(0xFF00D9FF),
              ),
            ),

            // =======================================================
            // MAIN CONTENT
            // =======================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =================================================
                  // HEADER
                  // =================================================

                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _ringController,
                        builder: (context, child) {
                          return Container(
                            width: 58,
                            height: 58,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                transform: GradientRotation(
                                  _ringController.value * 6.283,
                                ),
                                colors: const [
                                  Color(0xFF0A5DFF),
                                  Color(0xFF18E5FF),
                                  Color(0xFF087BFF),
                                  Color(0xFF0A5DFF),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF12DFFF)
                                      .withOpacity(0.30),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF071B2E),
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF35DFFF),
                                size: 27,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning 👋',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF8198AC),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Employee',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2136),
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF194663),
                          ),
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF8CA8BC),
                          size: 21,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // =================================================
                  // TODAY STATUS
                  // =================================================

                  Text(
                    "TODAY'S STATUS",
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF718AA0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      17,
                      18,
                      17,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC071A2D),
                      borderRadius:
                          BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF16435F),
                      ),
                    ),
                    child: Column(
                      children: [
                        _statusRow(
                          icon: Icons.login_rounded,
                          title: 'Check In',
                          value: checkInTime ?? '--:--',
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          child: Divider(
                            color: Color(0xFF16384F),
                            height: 1,
                          ),
                        ),

                        _statusRow(
                          icon: Icons.logout_rounded,
                          title: 'Check Out',
                          value: checkOutTime ?? '--:--',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // CHECK IN BUTTON
                  // =================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF176DFF),
                            Color(0xFF18D5EF),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00CFFF)
                                .withOpacity(0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _checkIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor:
                              Colors.transparent,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.login_rounded,
                              size: 21,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              checkInTime == null
                                  ? 'Check In'
                                  : 'Checked In',
                              style:
                                  GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =================================================
                  // PERMISSION + PERMISSION RETURN
                  // =================================================

                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon:
                              Icons.verified_user_outlined,
                          title: 'Permission',
                          onTap: _openPermission,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _actionCard(
                          icon:
                              Icons.assignment_return_outlined,
                          title: 'Permission Return',
                          onTap:
                              _openPermissionReturn,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // TODAY SUMMARY
                  // =================================================

                  Text(
                    'TODAY SUMMARY',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF718AA0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 17,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xCC071A2D),
                      borderRadius:
                          BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF16435F),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _summaryItem(
                            icon: Icons.login_rounded,
                            title: 'Check In',
                            value:
                                checkInTime ?? '--:--',
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 42,
                          color:
                              const Color(0xFF19425A),
                        ),

                        Expanded(
                          child: _summaryItem(
                            icon:
                                Icons.timer_outlined,
                            title: 'Working',
                            value:
                                checkInTime == null
                                    ? '--h --m'
                                    : 'Active',
                          ),
                        ),

                        Container(
                          width: 1,
                          height: 42,
                          color:
                              const Color(0xFF19425A),
                        ),

                        Expanded(
                          child: _summaryItem(
                            icon: Icons
                                .event_available_outlined,
                            title: 'Status',
                            value:
                                checkInTime == null
                                    ? 'Pending'
                                    : 'Present',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // POWERED BY
                  // =================================================

                  Center(
                    child: Text(
                      'LYRA PULSE',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF38566D),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =======================================================
            // BOTTOM NAVIGATION
            // =======================================================

            Positioned(
              left: 14,
              right: 14,
              bottom: 10,
              child: Container(
                height: 72,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF071C2E),
                  borderRadius:
                      BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF16435F),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.35),
                      blurRadius: 25,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _navItem(
                        icon: Icons.home_rounded,
                        title: 'Home',
                        index: 0,
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                        },
                      ),
                    ),

                    Expanded(
                      child: _navItem(
                        icon:
                            Icons.access_time_rounded,
                        title: 'Attendance',
                        index: 1,
                        onTap: _openAttendance,
                      ),
                    ),

                    Expanded(
                      child: _navItem(
                        icon:
                            Icons.event_available_rounded,
                        title: 'Leave',
                        index: 2,
                        onTap: _openLeave,
                      ),
                    ),

                    Expanded(
                      child: _navItem(
                        icon:
                            Icons.person_outline_rounded,
                        title: 'Profile',
                        index: 3,
                        onTap: _openProfile,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // STATUS ROW
  // ===============================================================

  Widget _statusRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF0A2941),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF28DDF7),
            size: 20,
          ),
        ),

        const SizedBox(width: 13),

        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF9CB0C0),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // ACTION CARD
  // ===============================================================

  Widget _actionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(17),
        child: Container(
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFF071C2E),
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: const Color(0xFF17455F),
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFF27DDF7),
                size: 23,
              ),

              const SizedBox(height: 7),

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 6,
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color:
                        const Color(0xFFC1D0DC),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // SUMMARY ITEM
  // ===============================================================

  Widget _summaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF25DDF7),
          size: 21,
        ),

        const SizedBox(height: 5),

        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF728CA1),
            fontSize: 8,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // BOTTOM NAV ITEM
  // ===============================================================

  Widget _navItem({
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
  }) {
    final isSelected =
        selectedIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0C3855)
                : Colors.transparent,
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF25DDF7)
                    : const Color(0xFF718CA1),
                size: 20,
              ),

              const SizedBox(height: 4),

              Text(
                title,
                style: GoogleFonts.poppins(
                  color: isSelected
                      ? const Color(0xFF25DDF7)
                      : const Color(0xFF718CA1),
                  fontSize: 8,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // GLOW
  // ===============================================================

  Widget _glow(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.11),
            color.withOpacity(0.025),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// SIMPLE FEATURE PAGE
// Used for Leave and Profile temporarily.
// Attendance now uses the real AttendanceScreen.
// ===================================================================

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFF04111F),
        elevation: 0,

        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),

        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding:
              const EdgeInsets.all(30),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Container(
                width: 78,
                height: 78,

                decoration:
                    BoxDecoration(
                  shape:
                      BoxShape.circle,
                  color:
                      const Color(0xFF0A2941),
                  border:
                      Border.all(
                    color:
                        const Color(0xFF20DDF7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color(
                        0xFF20DDF7,
                      ).withOpacity(0.18),
                      blurRadius: 25,
                    ),
                  ],
                ),

                child: Icon(
                  icon,
                  color:
                      const Color(0xFF25DDF7),
                  size: 34,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                title,
                style:
                    GoogleFonts.poppins(
                  color:
                      Colors.white,
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                subtitle,
                textAlign:
                    TextAlign.center,
                style:
                    GoogleFonts.poppins(
                  color:
                      const Color(
                    0xFF7F96AB,
                  ),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 25),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFF0A2136,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(12),
                  border:
                      Border.all(
                    color:
                        const Color(
                      0xFF16435F,
                    ),
                  ),
                ),

                child: Text(
                  'Screen ready',
                  style:
                      GoogleFonts.poppins(
                    color:
                        const Color(
                      0xFF25DDF7,
                    ),
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}