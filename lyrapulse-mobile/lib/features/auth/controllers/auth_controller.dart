import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/models/employee_model.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final _authRepository = Get.find<AuthRepository>();
  final _secureStorage = Get.find<SecureStorageService>();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final secondsRemaining = AppConstants.otpCountdownSeconds.obs;
  final isSendingOtp = false.obs;
  final isResendingOtp = false.obs;
  final isVerifying = false.obs;
  final isLoggingOut = false.obs;
  final employee = Rxn<EmployeeModel>();

  Timer? _countdownTimer;

  Future<void> sendOtp() async {
    if (isSendingOtp.value) return;
    final error = Validators.phone(phoneController.text);
    if (error != null) {
      AppSnackbar.show(error);
      return;
    }
    isSendingOtp.value = true;
    try {
      final devOtp = await _authRepository.sendOtp(_normalizedPhone);
      otpController.clear();
      Get.toNamed(AppRoutes.otp);
      _showDevOtp(devOtp);
    } catch (error) {
      AppSnackbar.show(_errorMessage(error));
    } finally {
      isSendingOtp.value = false;
    }
  }

  /// Restarts the resend cooldown. Uses a periodic timer so the countdown
  /// runs every time the OTP screen opens (the previous listener-based
  /// approach never fired when the value was already at its initial value).
  void startCountdown() {
    _countdownTimer?.cancel();
    secondsRemaining.value = AppConstants.otpCountdownSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value <= 1) {
        secondsRemaining.value = 0;
        timer.cancel();
      } else {
        secondsRemaining.value--;
      }
    });
  }

  void stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  Future<void> resendOtp() async {
    if (secondsRemaining.value > 0 || isResendingOtp.value) return;
    isResendingOtp.value = true;
    try {
      final devOtp = await _authRepository.resendOtp(_normalizedPhone);
      otpController.clear();
      startCountdown();
      if (devOtp != null && kDebugMode) {
        _showDevOtp(devOtp);
      } else {
        AppSnackbar.show('A new OTP has been sent');
      }
    } catch (error) {
      AppSnackbar.show(_errorMessage(error));
    } finally {
      isResendingOtp.value = false;
    }
  }

  Future<void> verifyOtp() async {
    if (isVerifying.value) return;
    if (!RegExp(r'^\d{6}$').hasMatch(otpController.text)) {
      AppSnackbar.show('Enter the 6-digit OTP');
      return;
    }
    isVerifying.value = true;
    try {
      employee.value = await _authRepository.verifyOtp(_normalizedPhone, otpController.text);
      stopCountdown();
      // Removes Login/OTP from the back stack.
      Get.offAllNamed(AppRoutes.home);
    } catch (error) {
      AppSnackbar.show(_errorMessage(error));
    } finally {
      isVerifying.value = false;
    }
  }

  /// Checks the stored session against the backend (profile + /auth/me).
  /// The Dio client transparently refreshes an expired access token.
  ///
  /// Returns true only for a valid session. Tokens are cleared when the server
  /// rejects them; on network/server problems they are kept so the next app
  /// start can retry instead of silently logging the employee out.
  Future<bool> restoreSession() async {
    final token = await _secureStorage.readAccessToken();
    if (token == null || token.isEmpty) return false;
    try {
      employee.value = await _authRepository.loadEmployeeProfile();
      return true;
    } catch (error) {
      if (_isConnectivityProblem(error)) {
        AppSnackbar.show(_errorMessage(error));
      } else {
        await _authRepository.clearSession();
      }
      return false;
    }
  }

  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;
    Object? logoutError;
    try {
      await _authRepository.logout();
    } catch (error) {
      logoutError = error;
    } finally {
      employee.value = null;
      otpController.clear();
      stopCountdown();
      isLoggingOut.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
    if (logoutError != null) {
      AppSnackbar.show('Signed out on this device. Server logout could not be confirmed.');
    }
  }

  void _showDevOtp(String? devOtp) {
    // Development convenience only; production responses carry no dev_otp.
    if (devOtp != null && kDebugMode) {
      AppSnackbar.show('Development OTP: $devOtp');
    }
  }

  String get _normalizedPhone => phoneController.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^91(?=\d{10}$)'), '');

  bool _isConnectivityProblem(Object error) {
    if (error is! DioException) return false;
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      default:
        final status = error.response?.statusCode;
        return status != null && status >= 500;
    }
  }

  String _errorMessage(Object error) {
    if (error is DioException) {
      if (_isConnectivityProblem(error)) {
        final status = error.response?.statusCode;
        if (status != null) return 'The server is unavailable right now. Please try again shortly.';
        return 'Unable to reach Lyra Pulse. Check your internet connection and try again.';
      }
      final data = error.response?.data;
      if (data is Map) {
        if (data['detail'] != null) return data['detail'].toString();
        if (data['message'] != null && data['message'] != 'Request failed') return data['message'].toString();
        final errors = data['errors'];
        if (errors is Map) return errors.values.expand((value) => value is List ? value : [value]).join(' ');
      }
      if (error.response?.statusCode == 401) return 'Your session has expired. Please sign in again.';
      return error.message ?? 'Something went wrong. Please try again.';
    }
    if (error is FormatException) return 'Unexpected response from the server. Please try again.';
    return 'Something went wrong. Please try again.';
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }
}