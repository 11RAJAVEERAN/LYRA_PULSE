import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/asset_paths.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/phone_input.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  // Keeps the content phone-sized on Flutter Web / tablets.
  static const double _maxContentWidth = 480;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: LayoutBuilder(builder: (context, constraints) {
          // Scale the illustration with the available height so the form is
          // never pushed off-screen on small phones or with the keyboard.
          final illustrationHeight =
              (constraints.maxHeight * 0.36).clamp(180.0, 320.0).toDouble();
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: _maxContentWidth,
                    minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(children: [
                      _LoginIllustration(height: illustrationHeight),
                      const SizedBox(height: 28),
                      Text('Employee Login',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headline),
                      const SizedBox(height: 8),
                      Text('Sign in to continue to your account',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.pagePadding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Phone Number', style: AppTextStyles.label),
                            const SizedBox(height: 10),
                            PhoneInput(controller: controller.phoneController),
                            const SizedBox(height: 22),
                            Obx(() => AppButton(
                                  label: 'Login',
                                  useGradient: true,
                                  loading: controller.isSendingOtp.value,
                                  onPressed: controller.isSendingOtp.value
                                      ? null
                                      : controller.sendOtp,
                                )),
                          ],
                        ),
                      ),
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text('POWERED BY LYRATECH',
                          style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                              color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LoginIllustration extends StatelessWidget {
  const _LoginIllustration({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppDimensions.cardRadius)),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.asset(
          AssetPaths.loginIllustration,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          cacheWidth: 1000,
          semanticLabel: 'Employee checking in on a laptop',
          // A missing/corrupt asset must never crash the login screen.
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}