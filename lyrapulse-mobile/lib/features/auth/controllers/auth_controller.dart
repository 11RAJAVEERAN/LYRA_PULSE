import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/config/app_config.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';

class AuthController extends GetxController {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final secondsRemaining = AppConstants.otpCountdownSeconds.obs;
  final isVerifying = false.obs;

  Worker? _countdownWorker;

  bool sendOtp() {
    final error = Validators.phone(phoneController.text);
    if (error != null) {
      AppSnackbar.show(error);
      return false;
    }
    otpController.clear();
    secondsRemaining.value = AppConstants.otpCountdownSeconds;
    Get.toNamed(AppRoutes.otp);
    return true;
  }

  void startCountdown() {
    _countdownWorker?.dispose();
    _countdownWorker = ever(secondsRemaining, (seconds) {
      if (seconds > 0) {
        Future<void>.delayed(
            const Duration(seconds: 1), () => secondsRemaining.value--);
      }
    });
  }

  void resendOtp() {
    if (secondsRemaining.value > 0) return;
    otpController.clear();
    secondsRemaining.value = AppConstants.otpCountdownSeconds;
    AppSnackbar.show('A new OTP has been sent');
  }

  void verifyOtp() {
    if (otpController.text != AppConfig.mockOtp) {
      AppSnackbar.show('Enter the valid 6-digit OTP');
      return;
    }
    isVerifying.value = true;
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      isVerifying.value = false;
      Get.offAllNamed(AppRoutes.home);
    });
  }

  @override
  void onClose() {
    _countdownWorker?.dispose();
    phoneController.dispose();
    otpController.dispose();
    
    super.onClose();
  }
}
