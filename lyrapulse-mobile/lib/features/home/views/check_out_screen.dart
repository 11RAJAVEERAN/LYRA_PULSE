import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/home_controller.dart';
import 'location_verification_screen.dart';

class CheckOutScreen extends GetView<HomeController> {
  const CheckOutScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ---------------------------------------------------------------------
      // APP BAR
      // ---------------------------------------------------------------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),

        title: Text(
          'Check Out',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        centerTitle: true,
      ),

      // ---------------------------------------------------------------------
      // BODY
      // ---------------------------------------------------------------------
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  24,
                ),
                child: Column(
                  children: [
                    _buildHeaderCard(),

                    const SizedBox(height: 16),

                    _buildWorkingTimeCard(),

                    const SizedBox(height: 16),

                    _buildInfoCard(),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // BOTTOM BUTTON
            // -----------------------------------------------------------------
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HEADER CARD
  // =========================================================================

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Ready to Check Out?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Complete verification before checking out.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // WORKING TIME / ATTENDANCE CARD
  // =========================================================================

  Widget _buildWorkingTimeCard() {
    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Attendance",
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // CHECK IN + CHECK OUT
            // -----------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: _timeItem(
                    icon: Icons.login_rounded,
                    label: 'Check In',
                    value: controller.checkInTime.value,
                    iconColor: AppColors.success,
                  ),
                ),

                Container(
                  width: 1,
                  height: 48,
                  color: AppColors.border,
                ),

                Expanded(
                  child: _timeItem(
                    icon: Icons.logout_rounded,
                    label: 'Check Out',
                    // Current time live-a update aagum.
                    value: controller.currentTime.value,
                    iconColor: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // -----------------------------------------------------------------
            // WORKING TIME
            // -----------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      size: 21,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Working Time',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          controller.workingHours.value,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // LIVE INDICATOR
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 5),

                      Text(
                        'Live',
                        style: GoogleFonts.inter(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TIME ITEM
  // =========================================================================

  Widget _timeItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        const SizedBox(width: 4),

        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            size: 19,
            color: iconColor,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // VERIFICATION INFO CARD
  // =========================================================================

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          _verificationRow(
            icon: Icons.location_on_outlined,
            title: 'Location Verification',
            subtitle:
                'Your workplace location will be verified',
          ),

          const SizedBox(height: 16),

          _verificationRow(
            icon: Icons.face_retouching_natural,
            title: 'Face Verification',
            subtitle:
                'Take a photo to confirm your identity',
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VERIFICATION ROW
  // =========================================================================

  Widget _verificationRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.08,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),

        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.success,
          size: 21,
        ),
      ],
    );
  }

  // =========================================================================
  // BOTTOM BUTTON
  // =========================================================================

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: () {
            Get.to(
              () => const LocationVerificationScreen(
                isCheckOut: true,
              ),
            );
          },
          icon: const Icon(
            Icons.arrow_forward_rounded,
            size: 20,
          ),
          label: Text(
            'Continue to Verification',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }
}