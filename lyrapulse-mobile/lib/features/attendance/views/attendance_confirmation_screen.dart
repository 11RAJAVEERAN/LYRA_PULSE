import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'check_in_success_screen.dart';

class AttendanceConfirmationScreen extends StatelessWidget {
  const AttendanceConfirmationScreen({super.key});

  // ===============================================================
  // EMPLOYEE DETAILS
  // Later API-la irundhu dynamic-a pass pannalam
  // ===============================================================

  final String employeeName = 'Employee';
  final String employeeId = 'LYRA001';
  final String checkInTime = '09:30 AM';
  final String distance = '125 m';

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
              top: -170,
              right: -150,
              child: _glow(
                360,
                const Color(0xFF087BFF),
              ),
            ),

            Positioned(
              bottom: -180,
              left: -150,
              child: _glow(
                380,
                const Color(0xFF00D9FF),
              ),
            ),

            // =======================================================
            // CONTENT
            // =======================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                22,
                18,
                22,
                35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===================================================
                  // TOP BAR
                  // ===================================================

                  Row(
                    children: [
                      _backButton(),
                      const Spacer(),
                      _secureBadge(),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // ===================================================
                  // HEADER ICON
                  // ===================================================

                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF08263D),
                        border: Border.all(
                          color: const Color(0xFF24E5C0),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF24E5C0)
                                .withOpacity(0.16),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fact_check_rounded,
                        color: Color(0xFF24E5C0),
                        size: 37,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ===================================================
                  // TITLE
                  // ===================================================

                  Center(
                    child: Text(
                      'ATTENDANCE',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        height: 1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFF20E4FF),
                            Color(0xFF287EFF),
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        'CONFIRMATION',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      'Review your attendance details before confirming',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF7F96AB),
                        fontSize: 10,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ===================================================
                  // EMPLOYEE CARD
                  // ===================================================

                  _sectionTitle('EMPLOYEE DETAILS'),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xCC071A2D),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF16435F),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0A2941),
                            border: Border.all(
                              color: const Color(0xFF20DDF7),
                            ),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Color(0xFF25DDF7),
                            size: 26,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                employeeName,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                'Employee ID: $employeeId',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF718CA1),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF24E5C0),
                          size: 21,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===================================================
                  // ATTENDANCE DETAILS
                  // ===================================================

                  _sectionTitle('ATTENDANCE DETAILS'),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xCC071A2D),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF16435F),
                      ),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          icon: Icons.login_rounded,
                          title: 'Check-in Time',
                          value: checkInTime,
                          color: const Color(0xFF25DDF7),
                        ),

                        _divider(),

                        _detailRow(
                          icon: Icons.location_on_outlined,
                          title: 'Location',
                          value: 'Verified',
                          color: const Color(0xFF24E5C0),
                          showCheck: true,
                        ),

                        _divider(),

                        _detailRow(
                          icon: Icons.face_outlined,
                          title: 'Face Verification',
                          value: 'Verified',
                          color: const Color(0xFF24E5C0),
                          showCheck: true,
                        ),

                        _divider(),

                        _detailRow(
                          icon: Icons.social_distance_outlined,
                          title: 'Distance',
                          value: distance,
                          color: const Color(0xFF25DDF7),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===================================================
                  // VERIFICATION STATUS
                  // ===================================================

                  _sectionTitle('VERIFICATION STATUS'),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _verificationCard(
                          icon: Icons.location_on_outlined,
                          title: 'LOCATION',
                          subtitle: 'Verified',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _verificationCard(
                          icon: Icons.face_outlined,
                          title: 'FACE',
                          subtitle: 'Verified',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ===================================================
                  // CONFIRM BUTTON
                  // ===================================================

                  SizedBox(
                    width: double.infinity,
                    height: 57,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0FAF91),
                            Color(0xFF24E5C0),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF24E5C0)
                                .withOpacity(0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Get.to(
                            () => const CheckInSuccessScreen(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 21,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Confirm Attendance',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ===================================================
                  // SECURITY MESSAGE
                  // ===================================================

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF536D83),
                        size: 14,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Attendance details are securely verified',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF536D83),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ===================================================
                  // POWERED BY
                  // ===================================================

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
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // SECTION TITLE
  // ===============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF718AA0),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  // ===============================================================
  // DETAIL ROW
  // ===============================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool showCheck = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0A2941),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 19,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF9CB0C0),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: showCheck
                    ? const Color(0xFF24E5C0)
                    : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (showCheck) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF24E5C0),
                size: 17,
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ===============================================================
  // DIVIDER
  // ===============================================================

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        color: Color(0xFF16384F),
        height: 1,
      ),
    );
  }

  // ===============================================================
  // VERIFICATION CARD
  // ===============================================================

  Widget _verificationCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF071C2E),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF1A665A),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0B3B36),
              border: Border.all(
                color: const Color(0xFF24E5C0)
                    .withOpacity(0.35),
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF24E5C0),
              size: 19,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF718CA1),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 2),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF24E5C0),
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF24E5C0),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0A2136),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1D4564),
        ),
      ),
      child: IconButton(
        onPressed: Get.back,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 21,
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
        color: const Color(0xFF0A2136),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1D4564),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF24E5C0),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SECURE',
            style: GoogleFonts.poppins(
              color: const Color(0xFF91AABD),
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
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
            color.withOpacity(0.12),
            color.withOpacity(0.03),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
} 