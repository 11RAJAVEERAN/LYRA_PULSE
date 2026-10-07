import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_history_screen.dart';

class AttendanceOverviewScreen extends StatelessWidget {
  const AttendanceOverviewScreen({super.key});

  static const Color background = Color(0xFFF7FAFE);
  static const Color navy = Color(0xFF19356C);
  static const Color purple = Color(0xFF6C63E8);
  static const Color green = Color(0xFF18A66A);
  static const Color orange = Color(0xFFF59E0B);

  static const Color primaryText = Color(0xFF172B4D);
  static const Color secondaryText = Color(0xFF65758B);
  static const Color border = Color(0xFFE3EAF3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // TOP BAR
              // =====================================================

              Row(
                children: [
                  _backButton(),
                  const Spacer(),
                  _secureBadge(),
                ],
              ),

              const SizedBox(height: 28),

              // =====================================================
              // HEADER
              // =====================================================

              Text(
                'Attendance Overview',
                style: GoogleFonts.poppins(
                  color: primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'Your attendance summary at a glance',
                style: GoogleFonts.poppins(
                  color: secondaryText,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 24),

              // =====================================================
              // TODAY CARD
              // =====================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8F2),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today',
                                style: GoogleFonts.poppins(
                                  color: primaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Attendance Status',
                                style: GoogleFonts.poppins(
                                  color: secondaryText,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF8F2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Present',
                            style: GoogleFonts.poppins(
                              color: green,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _todayDetail(
                            Icons.login_rounded,
                            'Check In',
                            '09:30 AM',
                            navy,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _todayDetail(
                            Icons.logout_rounded,
                            'Check Out',
                            '--',
                            purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // =====================================================
              // MONTHLY SUMMARY
              // =====================================================

              Text(
                'MONTHLY SUMMARY',
                style: GoogleFonts.poppins(
                  color: secondaryText,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'Present',
                      value: '22',
                      color: green,
                      backgroundColor: const Color(0xFFEAF8F2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.cancel_outlined,
                      title: 'Absent',
                      value: '2',
                      color: const Color(0xFFE05260),
                      backgroundColor: const Color(0xFFFFEFF1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.schedule_rounded,
                      title: 'Late',
                      value: '3',
                      color: orange,
                      backgroundColor: const Color(0xFFFFF6E5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.timelapse_rounded,
                      title: 'Working',
                      value: '8h',
                      color: purple,
                      backgroundColor: const Color(0xFFF0EEFF),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =====================================================
              // ATTENDANCE RATE
              // =====================================================

              Text(
                'ATTENDANCE RATE',
                style: GoogleFonts.poppins(
                  color: secondaryText,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Monthly Attendance',
                            style: GoogleFonts.poppins(
                              color: primaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '88%',
                          style: GoogleFonts.poppins(
                            color: green,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 13),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: 0.88,
                        minHeight: 9,
                        backgroundColor: const Color(0xFFEAF0F5),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          green,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '22 present days out of 25 working days',
                        style: GoogleFonts.poppins(
                          color: secondaryText,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =====================================================
              // VIEW ATTENDANCE RECORDS
              // =====================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(
                      () => const AttendanceHistoryScreen(),
                      transition: Transition.rightToLeft,
                      duration:
                          const Duration(milliseconds: 350),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Attendance Records',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // =====================================================
              // FOOTER
              // =====================================================

              Center(
                child: Text(
                  'LYRA PULSE',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8A99AA),
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
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
  // TODAY DETAIL
  // ===============================================================

  Widget _todayDetail(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: secondaryText,
                    fontSize: 8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SUMMARY CARD
  // ===============================================================

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: primaryText,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: secondaryText,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // BACK BUTTON
  // ===============================================================

  Widget _backButton() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: navy,
          size: 20,
        ),
      ),
    );
  }

  // ===============================================================
  // SECURE BADGE
  // ===============================================================

  Widget _secureBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFCBEBD9),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: green,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SECURE',
            style: GoogleFonts.poppins(
              color: green,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}