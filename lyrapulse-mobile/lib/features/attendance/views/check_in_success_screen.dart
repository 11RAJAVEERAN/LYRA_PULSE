import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class CheckInSuccessScreen extends StatelessWidget {
  const CheckInSuccessScreen({super.key});

  // ===============================================================
  // COLORS
  // ===============================================================



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
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
                  color: AppColors.successBackground,
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.10),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
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
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your attendance has been recorded successfully.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
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
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
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
                        color: AppColors.successBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Attendance Verified',
                              style: GoogleFonts.inter(
                                color: AppColors.success,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
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
                      valueColor: AppColors.success,
                      showCheck: true,
                    ),

                    _divider(),

                    // Face
                    _detailRow(
                      icon: Icons.face_outlined,
                      title: 'Face Verification',
                      value: 'Verified',
                      valueColor: AppColors.success,
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
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
                        style: GoogleFonts.inter(
                          color: AppColors.surface,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.surface,
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
                    color: AppColors.success,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Attendance details are securely verified',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
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
                style: GoogleFonts.inter(
                  color: AppColors.borderStrong,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                'SECURE ATTENDANCE',
                style: GoogleFonts.inter(
                  color: AppColors.borderStrong,
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
    Color valueColor = AppColors.primary,
    bool showCheck = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.hover,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
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
              style: GoogleFonts.inter(
                color: valueColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showCheck) ...[
              const SizedBox(width: 5),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
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
        color: AppColors.border,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.035),
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
              color: AppColors.successBackground,
            ),
            child: Icon(
              icon,
              color: AppColors.success,
              size: 19,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
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
                color: AppColors.success,
                size: 13,
              ),
              const SizedBox(width: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: AppColors.success,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.primary,
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
        color: AppColors.successBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SECURE',
            style: GoogleFonts.inter(
              color: AppColors.success,
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
