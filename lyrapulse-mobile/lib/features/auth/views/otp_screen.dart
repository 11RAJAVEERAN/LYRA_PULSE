
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_input.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final controller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    controller.startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: Get.back, icon: const Icon(Icons.arrow_back_rounded))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePadding, 16, AppDimensions.pagePadding, 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const AppLogo(compact: true),
            const SizedBox(height: 62),
            Text('Verify Your Number', style: AppTextStyles.headline),
            const SizedBox(height: 10),
            Text('If this number is registered and active, an OTP was sent.',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: 10),
            Text('+91 ${controller.phoneController.text}',
                style: AppTextStyles.label),
            const SizedBox(height: 28),
            OtpInput(controller: controller.otpController),
            const SizedBox(height: 24),
            Obx(() => AppButton(
                label: 'Verify & Continue',
                onPressed:
                    controller.isVerifying.value ? null : controller.verifyOtp,
                icon: Icons.check_rounded)),
            const SizedBox(height: 28),
            Center(
                child: Text('Didn\'t receive the OTP?',
                    style: AppTextStyles.bodySmall)),
            const SizedBox(height: 8),
            Center(child: Obx(() {
              final seconds = controller.secondsRemaining.value;
              return TextButton(
                  onPressed: seconds == 0 ? controller.resendOtp : null,
                  child: Text(seconds == 0
                      ? 'Resend OTP'
                      : 'Resend OTP in ${seconds}s'));
            })),
          ]),
        ),
      ),
    );
  }
}