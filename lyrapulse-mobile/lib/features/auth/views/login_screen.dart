
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding,
                40,
                AppDimensions.pagePadding,
                20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 60,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    

                         

                    Text(
                      'Welcome Back',
                      style: AppTextStyles.headline,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Login to continue to your employee account',
                      style: AppTextStyles.bodySmall,
                    ),

                    const SizedBox(height: 36),

                    Text(
                      'Phone number',
                      style: AppTextStyles.label,
                    ),

                    const SizedBox(height: 10),

                    PhoneInput(
                      controller: controller.phoneController,
                    ),

                    const SizedBox(height: 24),

                    AppButton(
                      label: 'Send OTP',
                      onPressed: controller.sendOtp,
                      icon: Icons.arrow_forward_rounded,
                    ),

                    const SizedBox(height: 48),

                    Center(
                      child: Text(
                        'Powered by LyraTech',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

