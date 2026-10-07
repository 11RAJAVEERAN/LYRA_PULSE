import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_input.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Keeps the content phone-sized on Flutter Web / tablets.
  static const double _maxContentWidth = 480;

  final controller = Get.find<AuthController>();
  Worker? _verifyWorker;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    controller.startCountdown();
    // A verification attempt that ends without a signed-in employee failed,
    // so flag the boxes. (The controller already shows the message.)
    _verifyWorker = ever<bool>(controller.isVerifying, (verifying) {
      if (!verifying && controller.employee.value == null && mounted) {
        setState(() => _hasError = true);
      }
    });
  }

  @override
  void dispose() {
    _verifyWorker?.dispose();
    controller.stopCountdown();
    super.dispose();
  }

  String get _maskedPhone {
    final digits = controller.phoneController.text.replaceAll(RegExp(r'\D'), '');
    final lastFour =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    return '+91 ••••••$lastFour';
  }

  String _formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _verify() {
    if (!RegExp(r'^\d{6}$').hasMatch(controller.otpController.text)) {
      setState(() => _hasError = true);
    }
    controller.verifyOtp();
  }

  void _clearError(String _) {
    if (_hasError) setState(() => _hasError = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: _maxContentWidth,
                    minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppDimensions.pagePadding,
                          16,
                          AppDimensions.pagePadding,
                          0),
                      child: Column(children: [
                        _buildTopBar(),
                        const SizedBox(height: 22),
                        _buildShieldBadge(),
                        const SizedBox(height: 22),
                        Text('Verify Your Number',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headline),
                        const SizedBox(height: 8),
                        Text(
                            'If this number is registered and active, an OTP was sent.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall),
                        const SizedBox(height: 18),
                        _buildPhoneChip(),
                        const SizedBox(height: 28),
                        OtpInput(
                          controller: controller.otpController,
                          hasError: _hasError,
                          onChanged: _clearError,
                        ),
                        const SizedBox(height: 24),
                        Obx(() => AppButton(
                              label: controller.isVerifying.value
                                  ? 'Verifying…'
                                  : 'Verify OTP',
                              useGradient: true,
                              loading: controller.isVerifying.value,
                              icon: Icons.arrow_forward_rounded,
                              onPressed:
                                  controller.isVerifying.value ? null : _verify,
                            )),
                        const SizedBox(height: 20),
                        _buildResend(),
                        const SizedBox(height: 18),
                        _buildSecurityNote(),
                      ]),
                    ),
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

  Widget _buildTopBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: AppColors.primary.withAlpha(24),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: Get.back,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_rounded,
                    size: 22, color: AppColors.primary),
              ),
            ),
          ),
        ),
        Text('LYRA PULSE',
            style: AppTextStyles.title.copyWith(
                fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 3)),
      ],
    );
  }

  Widget _buildShieldBadge() {
    return Container(
      width: 84,
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: AppColors.primary.withAlpha(20)),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: AppColors.primary.withAlpha(30)),
        child: const Icon(Icons.verified_user_rounded,
            size: 28, color: AppColors.primary),
      ),
    );
  }

  Widget _buildPhoneChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryDark.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phone_android_rounded,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(_maskedPhone, style: AppTextStyles.label),
        ],
      ),
    );
  }

  Widget _buildResend() {
    return Obx(() {
      final seconds = controller.secondsRemaining.value;
      final resending = controller.isResendingOtp.value;
      final canResend = seconds == 0 && !resending;
      final actionStyle = AppTextStyles.bodySmall
          .copyWith(fontWeight: FontWeight.w700, color: AppColors.primary);
      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Didn\'t receive the code? ', style: AppTextStyles.bodySmall),
          if (seconds > 0)
            Text('Resend in ${_formatCountdown(seconds)}',
                style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary))
          else if (resending)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            GestureDetector(
              onTap: canResend ? controller.resendOtp : null,
              child: Text('Resend OTP', style: actionStyle),
            ),
        ],
      );
    });
  }

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline_rounded,
            size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Flexible(
          child: Text('Your verification helps keep your account secure.',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
        ),
      ],
    );
  }
}