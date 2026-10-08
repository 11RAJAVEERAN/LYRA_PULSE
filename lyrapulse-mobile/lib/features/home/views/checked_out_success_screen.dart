import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/home_controller.dart';

class CheckedOutSuccessScreen extends GetView<HomeController> {
  const CheckedOutSuccessScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSuccessIcon(),

                      const SizedBox(height: 24),

                      Text(
                        'Checked Out Successfully!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Your attendance has been recorded successfully.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      _buildAttendanceCard(),
                    ],
                  ),
                ),
              ),
            ),

            _buildDoneButton(),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // SUCCESS ICON
  // ----------------------------------------------------------

  Widget _buildSuccessIcon() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(
          alpha: 0.10,
        ),
        shape: BoxShape.circle,
      ),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 44,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // ATTENDANCE CARD
  // ----------------------------------------------------------

  Widget _buildAttendanceCard() {
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
          children: [
            _infoRow(
              icon: Icons.login_rounded,
              title: 'Check In',
              value: controller.checkInTime.value,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Divider(
                height: 1,
                color: AppColors.border,
              ),
            ),

            _infoRow(
              icon: Icons.logout_rounded,
              title: 'Check Out',
              value: controller.checkOutTime.value,
            ),

            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Divider(
                height: 1,
                color: AppColors.border,
              ),
            ),

            _infoRow(
              icon: Icons.access_time_rounded,
              title: 'Total Working Time',
              value: controller.workingHours.value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
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
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // DONE BUTTON
  // ----------------------------------------------------------

  Widget _buildDoneButton() {
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
        child: ElevatedButton(
          onPressed: () {
            // Return to Home and clear
            // the verification screens.
            Get.until(
              (route) => route.isFirst,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            'Back to Home',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}