import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';

class PermissionReturnScreen extends StatelessWidget {
  const PermissionReturnScreen({super.key});

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
              top: -170,
              right: -140,
              child: _glow(
                390,
                AppColors.hexFF087BFF,
              ),
            ),

            Positioned(
              bottom: -210,
              left: -160,
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
                22,
                22,
                22,
                35,
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

                  const SizedBox(height: 55),

                  // =====================================================
                  // WELCOME ICON
                  // =====================================================

                  Center(
                    child: _welcomeIcon(),
                  ),

                  const SizedBox(height: 30),

                  // =====================================================
                  // WELCOME BACK
                  // =====================================================

                  Center(
                    child: Text(
                      'WELCOME BACK',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            AppColors.hexFF20DFFF,
                            AppColors.hexFF24E5C0,
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        'RETURN TO OFFICE',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  Center(
                    child: Text(
                      'Welcome back. Please verify your current location and face before continuing.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.hexFF7F96AB,
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // =====================================================
                  // VERIFICATION REQUIRED CARD
                  // =====================================================

                  _verificationRequiredCard(),

                  const SizedBox(height: 22),

                  // =====================================================
                  // VERIFICATION STEPS
                  // =====================================================

                  Text(
                    'VERIFICATION REQUIRED',
                    style: GoogleFonts.inter(
                      color: AppColors.hexFF718AA0,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 11),

                  _verificationStep(
                    number: '01',
                    icon: Icons.location_on_outlined,
                    title: 'Location Verification',
                    subtitle:
                        'Verify that you are back at the registered office location.',
                  ),

                  const SizedBox(height: 10),

                  _verificationStep(
                    number: '02',
                    icon: Icons.face_retouching_natural_rounded,
                    title: 'Face Verification',
                    subtitle:
                        'Verify your face before continuing with attendance.',
                  ),

                  const SizedBox(height: 10),

                  _verificationStep(
                    number: '03',
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Attendance Continue',
                    subtitle:
                        'Continue your attendance after successful verification.',
                  ),

                  const SizedBox(height: 28),

                  // =====================================================
                  // RETURN TO OFFICE BUTTON
                  // =====================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.hexFF176DFF,
                            AppColors.hexFF18D5EF,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.hexFF00CFFF
                                .withOpacity(0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _startReturnVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.transparent,
                          foregroundColor: AppColors.white,
                          shadowColor: AppColors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 21,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Return to Office',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =====================================================
                  // SECURITY
                  // =====================================================

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.hexFF536D83,
                          size: 14,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Secure attendance verification',
                          style: GoogleFonts.inter(
                            color: AppColors.hexFF536D83,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =====================================================
                  // POWERED BY
                  // =====================================================

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 25,
                          height: 1.5,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.hexFF176DFF,
                                AppColors.hexFF00D9FF,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'LYRA PULSE',
                          style: GoogleFonts.inter(
                            color: AppColors.hexFF38566D,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.4,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          width: 25,
                          height: 1.5,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.hexFF00D9FF,
                                AppColors.hexFF176DFF,
                              ],
                            ),
                          ),
                        ),
                      ],
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
  // START RETURN VERIFICATION
  // ===============================================================

  void _startReturnVerification() {
    Get.toNamed(
      AppRoutes.locationVerification,
    );
  }

  // ===============================================================
  // WELCOME ICON
  // ===============================================================

  Widget _welcomeIcon() {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.hexFF08253A,
        border: Border.all(
          color: AppColors.hexFF20DFFF,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.hexFF20DFFF.withOpacity(0.18),
            blurRadius: 35,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.hexFF0B3049,
          border: Border.all(
            color: AppColors.hexFF20DFFF.withOpacity(0.35),
          ),
        ),
        child: const Icon(
          Icons.waving_hand_rounded,
          color: AppColors.hexFF20DFFF,
          size: 45,
        ),
      ),
    );
  }

  // ===============================================================
  // VERIFICATION REQUIRED CARD
  // ===============================================================

  Widget _verificationRequiredCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.hexCC071A2D,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.hexFF16435F,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.hexFF0A2941,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColors.hexFF1A5575,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.hexFF28DDF7,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verification Required',
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.hexFF0A2941,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.hexFF1B526F,
                  ),
                ),
                child: Text(
                  'REQUIRED',
                  style: GoogleFonts.inter(
                    color: AppColors.hexFF20DFFF,
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Text(
            'Before you continue your attendance, LYRA Pulse needs to verify that you have returned to the office.',
            style: GoogleFonts.inter(
              color: AppColors.hexFF8EA5B7,
              fontSize: 10,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // VERIFICATION STEP
  // ===============================================================

  Widget _verificationStep({
    required String number,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.hexFF071C2E,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.hexFF16435F,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.hexFF0A2941,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              number,
              style: GoogleFonts.inter(
                color: AppColors.hexFF20DFFF,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 11),

          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.hexFF09263B,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: AppColors.hexFF25DDF7,
              size: 19,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppColors.hexFF718CA1,
                    fontSize: 9,
                    height: 1.4,
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
  // BACK BUTTON
  // ===============================================================

  Widget _backButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.hexFF0A2136,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.hexFF1D4564,
        ),
      ),
      child: IconButton(
        onPressed: Get.back,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.white,
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
        color: AppColors.hexFF0A2136,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.hexFF1D4564,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.hexFF24E5C0,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SECURE',
            style: GoogleFonts.inter(
              color: AppColors.hexFF91AABD,
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
            AppColors.transparent,
          ],
        ),
      ),
    );
  }
}