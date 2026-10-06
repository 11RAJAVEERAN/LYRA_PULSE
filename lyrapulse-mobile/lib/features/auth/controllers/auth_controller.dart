import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

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
  final isVerifying = false.obs;
  final isLoggingOut = false.obs;
  final employee = Rxn<EmployeeModel>();

  Worker? _countdownWorker;

  Future<void> sendOtp() async {
    final error = Validators.phone(phoneController.text);
    if (error != null) {
      AppSnackbar.show(error);
      return;
    }
    isSendingOtp.value = true;
    try {
      final devOtp = await _authRepository.sendOtp(_normalizedPhone);
      otpController.clear();
      secondsRemaining.value = AppConstants.otpCountdownSeconds;
      Get.toNamed(AppRoutes.otp);
      if (devOtp != null) AppSnackbar.show('Development OTP: $devOtp');
    } catch (error) {
      AppSnackbar.show(_errorMessage(error));
    } finally {
      isSendingOtp.value = false;
    }
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

  Future<void> resendOtp() async {
    if (secondsRemaining.value > 0) return;
    try {
      final devOtp = await _authRepository.resendOtp(_normalizedPhone);
      otpController.clear();
      secondsRemaining.value = AppConstants.otpCountdownSeconds;
      AppSnackbar.show(devOtp == null ? 'A new OTP has been sent' : 'Development OTP: $devOtp');
    } catch (error) {
      AppSnackbar.show(_errorMessage(error));
    }
  }

  Future<void> verifyOtp() async {
    if (!RegExp(r'^\d{6}$').hasMatch(otpController.text)) {
      AppSnackbar.show('Enter the 6-digit OTP');
      return;
    }
    isVerifying.value = true;
    try {
      employee.value = await _authRepository.verifyOtp(_normalizedPhone, otpController.text);
      Get.offAllNamed(AppRoutes.home);
    } catch (error) {
      AppSnackbar.show(_errorMessage(error));
    } finally {
      isVerifying.value = false;
    }
  }

  Future<bool> restoreSession() async {
    final token = await _secureStorage.readAccessToken();
    if (token == null || token.isEmpty) return false;
    try {
      employee.value = await _authRepository.loadEmployeeProfile();
      return true;
    } catch (_) {
      await _authRepository.clearSession();
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
      isLoggingOut.value = false;
      Get.offAllNamed(AppRoutes.login);
    }
    if (logoutError != null) {
      AppSnackbar.show('Signed out on this device. Server logout could not be confirmed.');
    }
  }

  String get _normalizedPhone => phoneController.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^91(?=\d{10}$)'), '');

  String _errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data['detail'] != null) return data['detail'].toString();
        if (data['message'] != null && data['message'] != 'Request failed') return data['message'].toString();
        final errors = data['errors'];
        if (errors is Map) return errors.values.expand((value) => value is List ? value : [value]).join(' ');
      }
      return error.message ?? 'Unable to connect to Lyra Pulse.';
    }
    return error.toString();
  }

  @override
  void onClose() {
    _countdownWorker?.dispose();
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }
}