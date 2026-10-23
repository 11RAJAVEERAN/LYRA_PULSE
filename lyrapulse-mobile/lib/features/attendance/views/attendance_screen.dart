import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_details_screen.dart';
import '../../../app/theme/app_colors.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.hexFF04111F,
      body: SafeArea(
        child: Stack(
          children: [
            // =========================================================
            // BACKGROUND GLOW
            // =========================================================

            Positioned(
              top: -180,
              right: -150,
              child: _glow(
                390,
                AppColors.hexFF087BFF,
              ),
            ),

            Positioned(
              bottom: -220,
              left: -170,
              child: _glow(
                420,
                AppColors.hexFF00D9FF,
              ),
            ),

            // =========================================================
            // CONTENT
            // =========================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =====================================================
                  // HEADER
                  // =====================================================

                  Row(
                    children: [
                      _backButton(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Attendance',
                          style: GoogleFonts.inter(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.hexFF0A2136,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.hexFF194663,
                          ),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.hexFF25DDF7,
                          size: 21,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =====================================================
                  // TODAY TITLE
                  // =====================================================

                  Text(
                    "TODAY'S ATTENDANCE",
                    style: GoogleFonts.inter(
                      color: AppColors.hexFF718AA0,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =====================================================
                  // TODAY CARD
                  // =====================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.hexCC071A2D,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.hexFF16435F,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.hexFF0A2941,
                                border: Border.all(
                                  color: AppColors.hexFF20DDF7,
                                ),
                              ),
                              child: const Icon(
                                Icons.check_circle_outline_rounded,
                                color: AppColors.hexFF25DDF7,
                                size: 27,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '28 September 2026',
                                    style: GoogleFonts.inter(
                                      color: AppColors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Today',
                                    style: GoogleFonts.inter(
                                      color: AppColors.hexFF7892A7,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _statusBadge(
                              'Present',
                              AppColors.hexFF25DDF7,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Divider(
                          color: AppColors.hexFF16384F,
                          height: 1,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _timeItem(
                                icon: Icons.login_rounded,
                                title: 'Check In',
                                value: '09:12 AM',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 45,
                              color: AppColors.hexFF19425A,
                            ),
                            Expanded(
                              child: _timeItem(
                                icon: Icons.logout_rounded,
                                title: 'Check Out',
                                value: '06:18 PM',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =====================================================
                  // SUMMARY
                  // =====================================================

                  Text(
                    'ATTENDANCE SUMMARY',
                    style: GoogleFonts.inter(
                      color: AppColors.hexFF718AA0,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.event_available_rounded,
                          title: 'Present',
                          value: '22',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.event_busy_rounded,
                          title: 'Absent',
                          value: '02',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _summaryCard(
                          icon: Icons.pending_actions_rounded,
                          title: 'Leave',
                          value: '02',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =====================================================
                  // HISTORY TITLE
                  // =====================================================

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'ATTENDANCE HISTORY',
                          style: GoogleFonts.inter(
                            color: AppColors.hexFF718AA0,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Text(
                        'September',
                        style: GoogleFonts.inter(
                          color: AppColors.hexFF25DDF7,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // =====================================================
                  // HISTORY ITEM 28
                  // =====================================================

                  _historyCard(
                    date: '28',
                    day: 'MON',
                    checkIn: '09:12 AM',
                    checkOut: '06:18 PM',
                    status: 'Present',
                    statusColor: AppColors.hexFF25DDF7,
                  ),

                  const SizedBox(height: 10),

                  // =====================================================
                  // HISTORY ITEM 27
                  // =====================================================

                  _historyCard(
                    date: '27',
                    day: 'SUN',
                    checkIn: '09:08 AM',
                    checkOut: '06:05 PM',
                    status: 'Present',
                    statusColor: AppColors.hexFF25DDF7,
                  ),

                  const SizedBox(height: 10),

                  // =====================================================
                  // HISTORY ITEM 26
                  // =====================================================

                  _historyCard(
                    date: '26',
                    day: 'SAT',
                    checkIn: '--:--',
                    checkOut: '--:--',
                    status: 'Absent',
                    statusColor: AppColors.hexFFFF6B7A,
                  ),

                  const SizedBox(height: 10),

                  // =====================================================
                  // HISTORY ITEM 25
                  // =====================================================

                  _historyCard(
                    date: '25',
                    day: 'FRI',
                    checkIn: '09:15 AM',
                    checkOut: '06:10 PM',
                    status: 'Present',
                    statusColor: AppColors.hexFF25DDF7,
                  ),

                  const SizedBox(height: 10),

                  // =====================================================
                  // HISTORY ITEM 24
                  // =====================================================

                  _historyCard(
                    date: '24',
                    day: 'THU',
                    checkIn: '09:20 AM',
                    checkOut: '06:22 PM',
                    status: 'Present',
                    statusColor: AppColors.hexFF25DDF7,
                  ),

                  const SizedBox(height: 30),

                  // =====================================================
                  // FOOTER
                  // =====================================================

                  Center(
                    child: Text(
                      'LYRA PULSE',
                      style: GoogleFonts.inter(
                        color: AppColors.hexFF38566D,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // BACK BUTTON
  // ===============================================================

  Widget _backButton() {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: Get.back,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.hexFF0A2136,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.hexFF194663,
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // STATUS BADGE
  // ===============================================================

  Widget _statusBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ===============================================================
  // TIME ITEM
  // ===============================================================

  Widget _timeItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.hexFF25DDF7,
          size: 20,
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.hexFF728CA1,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // SUMMARY CARD
  // ===============================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      height: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.hexFF071C2E,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.hexFF16435F,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.hexFF25DDF7,
            size: 22,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.hexFF718AA0,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // HISTORY CARD
  // ===============================================================

  Widget _historyCard({
    required String date,
    required String day,
    required String checkIn,
    required String checkOut,
    required String status,
    required Color statusColor,
  }) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: () {
          Get.to(
            () => AttendanceDetailsScreen(
              date: date,
              day: day,
              checkIn: checkIn,
              checkOut: checkOut,
              status: status,
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.hexCC071A2D,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.hexFF16435F,
            ),
          ),
          child: Row(
            children: [
              // DATE
              Container(
                width: 48,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.hexFF0A2941,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      day,
                      style: GoogleFonts.inter(
                        color: AppColors.hexFF6F8BA0,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 13),

              // CHECK IN / CHECK OUT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.login_rounded,
                          color: AppColors.hexFF25DDF7,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          checkIn,
                          style: GoogleFonts.inter(
                            color: AppColors.hexFFC4D1DC,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.hexFF7892A7,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          checkOut,
                          style: GoogleFonts.inter(
                            color: AppColors.hexFF879EAF,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // STATUS
              _statusBadge(
                status,
                statusColor,
              ),

              const SizedBox(width: 5),

              // CLICK INDICATOR
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.hexFF58758A,
                size: 20,
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
            color.withValues(alpha: 0.11),
            color.withValues(alpha: 0.025),
            AppColors.transparent,
          ],
        ),
      ),
    );
  }
}
