import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';
import '../controllers/auth_controller.dart';

class OtpScreen extends GetView<AuthController> {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePadding,
            32,
            AppDimensions.pagePadding,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // =========================
              // LOGO
              // =========================

              const AppLogo(compact: true),

              const SizedBox(height: 32),

              // =========================
              // TITLE
              // =========================

              Text(
                'Verify OTP',
                style: AppTextStyles.headline.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Enter the 6-digit OTP sent to your phone',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 32),

              // =========================
              // OTP INPUT
              // =========================

              TextField(
                controller: controller.otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // RESEND OTP
              // =========================

              Obx(
                () {
                  final seconds =
                      controller.secondsRemaining.value;

                  return TextButton(
                    onPressed: seconds == 0
                        ? controller.resendOtp
                        : null,
                    child: Text(
                      seconds == 0
                          ? 'Resend OTP'
                          : 'Resend OTP in ${seconds}s',
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // =========================
              // VERIFY BUTTON
              // =========================

              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: controller.isVerifying.value
                        ? 'Verifying...'
                        : 'Verify OTP',
                    onPressed: controller.isVerifying.value
                        ? null
                        : controller.verifyOtp,
                    icon: Icons.arrow_forward_rounded,
                  ),
                ),
              ),

              const SizedBox(height: 120),

              // =========================
              // FOOTER
              // =========================

              Text(
                'Powered by LyraTech',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}