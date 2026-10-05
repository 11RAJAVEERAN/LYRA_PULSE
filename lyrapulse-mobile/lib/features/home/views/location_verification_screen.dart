import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/home_controller.dart';
import 'face_verification_screen.dart';

class LocationVerificationScreen extends GetView<HomeController> {
  const LocationVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Location Verification',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),

      body: Obx(() {
        final isVerified = controller.isLocationVerified.value;
        final isLoading = controller.isLocationLoading.value;

        return SafeArea(
          child: Column(
            children: [
              // =====================================================
              // SCROLLABLE CONTENT
              // =====================================================

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // =================================================
                      // MAP / LOCATION AREA
                      // =================================================

                      Container(
                        height: 245,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEF7),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Simple map background
                            CustomPaint(
                              size: const Size(
                                double.infinity,
                                245,
                              ),
                              painter: _MapPainter(),
                            ),

                            // 50 meter boundary
                            Container(
                              width: 155,
                              height: 155,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.30,
                                  ),
                                  width: 1.5,
                                ),
                              ),
                            ),

                            // Current location
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.30,
                                    ),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                            ),

                            // 50m label
                            Positioned(
                              top: 22,
                              right: 18,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '50m Boundary',
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),

                            // Loading
                            if (isLoading)
                              const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // =================================================
                      // VERIFICATION STATUS
                      // =================================================

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? AppColors.success.withValues(
                                  alpha: 0.08,
                                )
                              : AppColors.error.withValues(
                                  alpha: 0.07,
                                ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isVerified
                                ? AppColors.success.withValues(
                                    alpha: 0.25,
                                  )
                                : AppColors.error.withValues(
                                    alpha: 0.20,
                                  ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? AppColors.success.withValues(
                                        alpha: 0.12,
                                      )
                                    : AppColors.error.withValues(
                                        alpha: 0.10,
                                      ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isVerified
                                    ? Icons.location_on_rounded
                                    : Icons.location_off_rounded,
                                color: isVerified
                                    ? AppColors.success
                                    : AppColors.error,
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
                                    isVerified
                                        ? 'You are within office location'
                                        : 'You are outside office location',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    isLoading
                                        ? 'Getting your current location...'
                                        : controller.locationDistance.value,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // =================================================
                      // OFFICE CARD
                      // =================================================

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: 0.04,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.business_rounded,
                                color: AppColors.primary,
                                size: 23,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OFFICE LOCATION',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    controller.locationName.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),

                                  const SizedBox(height: 3),

                                  Text(
                                    'Allowed radius: 50 meters',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 10,
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
              ),

              // =========================================================
              // BOTTOM ACTION AREA
              // =========================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ===================================================
                    // CONTINUE BUTTON
                    // ===================================================

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: isVerified
                            ? () {
                                Get.snackbar(
                                  'Location Verified',
                                  'Location verified successfully.',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: AppColors.success,
                                  colorText: Colors.white,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 12,
                                );

                                Get.to(
                                  () => const FaceVerificationScreen(),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.border,
                          disabledForegroundColor:
                              AppColors.textSecondary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isVerified
                                  ? Icons.check_circle_outline
                                  : Icons.lock_outline_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isVerified
                                  ? 'Continue'
                                  : 'Outside 50m Boundary',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ===================================================
                    // REFRESH LOCATION
                    // ===================================================

                    SizedBox(
                      height: 38,
                      child: TextButton.icon(
                        onPressed: isLoading
                            ? null
                            : () {
                                controller.startLiveLocation();
                              },
                        icon: const Icon(
                          Icons.refresh_rounded,
                          size: 17,
                        ),
                        label: Text(
                          isLoading
                              ? 'Checking Location...'
                              : 'Refresh Location',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        },
      ),
    );
  }
}

// ================================================================
// SIMPLE MAP BACKGROUND
// ================================================================

class _MapPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0xFFD5DEE9)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Horizontal roads
    for (double y = 30; y < size.height; y += 48) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 15),
        paint,
      );
    }

    // Vertical roads
    for (double x = 20; x < size.width; x += 55) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + 35, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}