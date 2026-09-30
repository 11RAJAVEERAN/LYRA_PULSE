import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';
import '../controllers/auth_controller.dart';
import '../widgets/phone_input.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ------------------------------------------------
              // TOP PREMIUM HEADER
              // ------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePadding,
                  36,
                  AppDimensions.pagePadding,
                  42,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryDark,
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    // Logo
                    const AppLogo(
                      onDark: true,
                      compact: true,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Lyra Pulse',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Employee Attendance',
                      style: TextStyle(
                        color: Color(0xFFD9DEFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------
              // LOGIN CARD
              // ------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.pagePadding,
                  28,
                  AppDimensions.pagePadding,
                  20,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Login title
                      Text(
                        'Welcome Back 👋',
                        style: AppTextStyles.headline,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to continue to your employee account',
                        style: AppTextStyles.bodySmall,
                      ),

                      const SizedBox(height: 28),

                      // Phone label
                      Text(
                        'Mobile Number',
                        style: AppTextStyles.label,
                      ),

                      const SizedBox(height: 10),

                      // Phone input
                      PhoneInput(
                        controller: controller.phoneController,
                      ),

                      const SizedBox(height: 24),

                      // Send OTP
                      AppButton(
                        label: 'Send OTP',
                        onPressed: controller.sendOtp,
                        icon: Icons.arrow_forward_rounded,
                      ),

                      const SizedBox(height: 20),

                      // Secure login text
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Secure employee login',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ------------------------------------------------
              // FOOTER
              // ------------------------------------------------
              Padding(
                padding: const EdgeInsets.only(
                  top: 8,
                  bottom: 24,
                ),
                child: Text(
                  'Powered by LyraTech',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}