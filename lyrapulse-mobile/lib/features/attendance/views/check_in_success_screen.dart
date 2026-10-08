import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckInSuccessScreen extends StatelessWidget {
  const CheckInSuccessScreen({super.key});

  // ===============================================================
  // COLORS
  // ===============================================================

  static const Color background = Color(0xFFF7FAFE);
  static const Color navy = Color(0xFF19356C);
  static const Color green = Color(0xFF18A66A);
  static const Color lightGreen = Color(0xFFEAF8F2);
  static const Color greenBorder = Color(0xFFCBEBD9);

  static const Color primaryText = Color(0xFF172B4D);
  static const Color secondaryText = Color(0xFF65758B);
  static const Color lightText = Color(0xFF8A99AA);
  static const Color border = Color(0xFFE3EAF3);

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
            28,
          ),
          child: Column(
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

              const SizedBox(height: 42),

              // =====================================================
              // SUCCESS ICON
              // =====================================================

              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightGreen,
                  border: Border.all(
                    color: greenBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: green.withOpacity(0.10),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: green,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 52,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // =====================================================
              // SUCCESS TITLE
              // =====================================================

              Text(
                'CHECK IN SUCCESSFUL',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your attendance has been recorded successfully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 30),

              // =====================================================
              // SUCCESS STATUS CARD
              // =====================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Status
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: greenBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: green,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Attendance Verified',
                              style: GoogleFonts.poppins(
                                color: green,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: green,
                            size: 18,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Employee
                    _detailRow(
                      icon: Icons.person_outline_rounded,
                      title: 'Employee',
                      value: 'Employee',
                    ),

                    _divider(),

                    // Employee ID
                    _detailRow(
                      icon: Icons.badge_outlined,
                      title: 'Employee ID',
                      value: 'LYRA001',
                    ),

                    _divider(),

                    // Check-in time
                    _detailRow(
                      icon: Icons.access_time_rounded,
                      title: 'Check-in Time',
                      value: '09:30 AM',
                    ),

                    _divider(),

                    // Location
                    _detailRow(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      value: 'Verified',
                      valueColor: green,
                      showCheck: true,
                    ),

                    _divider(),

                    // Face
                    _detailRow(
                      icon: Icons.face_outlined,
                      title: 'Face Verification',
                      value: 'Verified',
                      valueColor: green,
                      showCheck: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =====================================================
              // LOCATION / FACE STATUS
              // =====================================================

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

              const SizedBox(height: 26),

              // =====================================================
              // DONE BUTTON
              // =====================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Get.until((route) => route.isFirst);
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
                        'Done',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // =====================================================
              // SECURITY MESSAGE
              // =====================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: green,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Attendance details are securely verified',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: secondaryText,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // =====================================================
              // LYRA PULSE
              // =====================================================

              Text(
                'LYRA PULSE',
                style: GoogleFonts.poppins(
                  color: lightText,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'SECURE ATTENDANCE',
                style: GoogleFonts.poppins(
                  color: lightText,
                  fontSize: 7,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
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
    Color valueColor = primaryText,
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
            color: navy,
            size: 19,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: secondaryText,
              fontSize: 10.5,
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
                color: valueColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (showCheck) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.check_circle_rounded,
                color: green,
                size: 15,
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
      padding: EdgeInsets.symmetric(vertical: 11),
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
        horizontal: 10,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: greenBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.035),
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
              color: lightGreen,
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
            color: navy.withOpacity(0.04),
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
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: greenBorder,
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