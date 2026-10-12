
import 'dart:async';

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

  Timer? _countdownTimer;
  Timer? _verificationTimer;

  bool login() {
    final error = Validators.phone(phoneController.text.trim());

    if (error != null) {
      AppSnackbar.show(error);
      return false;
    }

    return sendOtp();
  }

  bool sendOtp() {
    final error = Validators.phone(phoneController.text.trim());

    if (error != null) {
      AppSnackbar.show(error);
      return false;
    }

    otpController.clear();
    startCountdown();

    Get.toNamed(AppRoutes.otp);

    return true;
  }

  void startCountdown() {
    _countdownTimer?.cancel();

    secondsRemaining.value = AppConstants.otpCountdownSeconds;

    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (isClosed) {
          timer.cancel();
          return;
        }

        if (secondsRemaining.value > 0) {
          secondsRemaining.value--;
        } else {
          timer.cancel();
        }
      },
    );
  }

  void resendOtp() {
    if (secondsRemaining.value > 0) return;

    otpController.clear();
    startCountdown();

    AppSnackbar.show('A new OTP has been sent');
  }

  void verifyOtp() {
    if (isVerifying.value) return;

    final otp = otpController.text.trim();

    if (otp.length != 6) {
      AppSnackbar.show('Enter the valid 6-digit OTP');
      return;
    }

    // Demo OTP verification only.
    // Replace this with backend verification when available.
    if (otp != AppConfig.mockOtp) {
      AppSnackbar.show('Enter the valid 6-digit OTP');
      return;
    }

    isVerifying.value = true;

    _verificationTimer?.cancel();

    _verificationTimer = Timer(
      const Duration(milliseconds: 450),
      () {
        if (isClosed) return;

        isVerifying.value = false;
        Get.offAllNamed(AppRoutes.home);
      },
    );
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _verificationTimer?.cancel();

    phoneController.dispose();
    otpController.dispose();

    super.onClose();
  }
}
