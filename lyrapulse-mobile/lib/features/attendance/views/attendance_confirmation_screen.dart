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

  // ===============================================================
  // COLORS
  // ===============================================================

  static const Color navy = Color(0xFF19356C);
  static const Color blue = Color(0xFF3978E8);
  static const Color green = Color(0xFF18A66A);

  static const Color background = Color(0xFFF7FAFE);
  static const Color cardBackground = Colors.white;
  static const Color border = Color(0xFFE3EAF3);

  static const Color primaryText = Color(0xFF172B4D);
  static const Color secondaryText = Color(0xFF65758B);
  static const Color lightText = Color(0xFF8A99AA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            30,
          ),
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

              const SizedBox(height: 26),

              // =====================================================
              // HEADER ICON
              // =====================================================

              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEAF8F2),
                    border: Border.all(
                      color: const Color(0xFFBFE8D3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: green,
                    size: 37,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =====================================================
              // TITLE
              // =====================================================

              Center(
                child: Text(
                  'CHECK IN READY',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: primaryText,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 7),

              Center(
                child: Text(
                  'Your attendance verification is complete',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: secondaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // =====================================================
              // EMPLOYEE DETAILS TITLE
              // =====================================================

              _sectionTitle('EMPLOYEE DETAILS'),

              const SizedBox(height: 10),

              // =====================================================
              // EMPLOYEE CARD
              // =====================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF19356C)
                          .withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // PROFILE ICON
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFEAF0FC),
                        border: Border.all(
                          color: const Color(0xFFD5E0F5),
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: navy,
                        size: 27,
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
                              color: primaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Employee ID: $employeeId',
                            style: GoogleFonts.poppins(
                              color: secondaryText,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // VERIFIED
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE8F8EF),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: green,
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =====================================================
              // ATTENDANCE DETAILS
              // =====================================================

              _sectionTitle('ATTENDANCE DETAILS'),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF19356C)
                          .withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _detailRow(
                      icon: Icons.login_rounded,
                      title: 'Check-in Time',
                      value: checkInTime,
                      color: blue,
                    ),

                    _divider(),

                    _detailRow(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      value: 'Verified',
                      color: green,
                      showCheck: true,
                    ),

                    _divider(),

                    _detailRow(
                      icon: Icons.face_outlined,
                      title: 'Face Verification',
                      value: 'Verified',
                      color: green,
                      showCheck: true,
                    ),

                    _divider(),

                    _detailRow(
                      icon: Icons.social_distance_outlined,
                      title: 'Distance',
                      value: distance,
                      color: blue,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =====================================================
              // VERIFICATION STATUS
              // =====================================================

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

              // =====================================================
              // CONFIRM CHECK IN BUTTON
              // =====================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(
                      () => const CheckInSuccessScreen(),
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
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 21,
                        color: Colors.white,
                      ),

                      const SizedBox(width: 9),

                      Text(
                        'Confirm Check In',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // =====================================================
              // CANCEL BUTTON
              // =====================================================

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: navy,
                    side: const BorderSide(
                      color: border,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      color: navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =====================================================
              // SECURITY MESSAGE
              // =====================================================

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: green,
                    size: 15,
                  ),

                  const SizedBox(width: 7),

                  Text(
                    'Attendance details are securely verified',
                    style: GoogleFonts.poppins(
                      color: secondaryText,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // =====================================================
              // LYRA PULSE
              // =====================================================

              Center(
                child: Text(
                  'LYRA PULSE',
                  style: GoogleFonts.poppins(
                    color: lightText,
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
  // SECTION TITLE
  // ===============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: secondaryText,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
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
            color: const Color(0xFFF1F5FA),
            borderRadius: BorderRadius.circular(11),
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
              color: secondaryText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                color: showCheck ? green : primaryText,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (showCheck) ...[
              const SizedBox(width: 5),

              const Icon(
                Icons.check_circle_rounded,
                color: green,
                size: 16,
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
        color: border,
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
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDDE7E1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF19356C)
                .withOpacity(0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEAF8F2),
            ),
            child: Icon(
              icon,
              color: green,
              size: 19,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: GoogleFonts.poppins(
              color: secondaryText,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 3),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: green,
                size: 13,
              ),

              const SizedBox(width: 4),

              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: green,
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
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF19356C)
                .withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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