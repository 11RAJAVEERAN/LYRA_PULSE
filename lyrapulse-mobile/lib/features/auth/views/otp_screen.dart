import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
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
    // so flag the boxes. The controller already shows the message.
    _verifyWorker = ever<bool>(
      controller.isVerifying,
      (verifying) {
        if (!verifying && controller.employee.value == null && mounted) {
          setState(() => _hasError = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _verifyWorker?.dispose();
    controller.stopCountdown();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _maskedPhone {
    final digits =
        controller.phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 4) {
      return '+91 $digits';
    }

    return '+91 ${digits.substring(0, 2)}******'
        '${digits.substring(digits.length - 2)}';
  }

  String _formatCountdown(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _verify() {
    FocusManager.instance.primaryFocus?.unfocus();
    HapticFeedback.selectionClick();

    if (!RegExp(r'^\d{6}$').hasMatch(controller.otpController.text)) {
      setState(() => _hasError = true);
    }

    controller.verifyOtp();
  }

  void _clearError(String _) {
    if (_hasError) {
      setState(() => _hasError = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        // Scaffold lifts the pinned button above the keyboard by itself.
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: _maxContentWidth),
                      child: Column(
                        children: [
                          _buildIntro(),
                          const SizedBox(height: 32),
                          _buildOtpSection(),
                          const SizedBox(height: 28),
                          _buildResend(),
                          const SizedBox(height: 24),
                          _buildSecurityNote(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  /// Back button row (only shown when there is a previous screen).
  Widget _buildTopBar(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return SizedBox(
      height: 56,
      child: Align(
        alignment: Alignment.centerLeft,
        child: canPop
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Get.back(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  /// Lock badge, title, subtitle and masked phone number.
  Widget _buildIntro() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.selection,
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 38,
              color: AppColors.surface,
            ),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              'OTP Verification',
              textAlign: TextAlign.center,
              style: AppTextStyles.display.copyWith(
                 fontSize: 25,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "We've sent a 6-digit OTP to your\nregistered mobile number",
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _buildPhoneChip(),
        ],
      ),
    );
  }

  Widget _buildPhoneChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.call_rounded,
            color: AppColors.primaryBlue,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            _maskedPhone,
            style: AppTextStyles.title.copyWith(
              fontSize: 16,
              letterSpacing: 0.4,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// OTP boxes and the inline error message.
  Widget _buildOtpSection() {
    return Column(
      children: [
        AutofillGroup(
          child: OtpInput(
            controller: controller.otpController,
            hasError: _hasError,
            onChanged: _clearError,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: _hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'We couldn’t verify that code. Check it and try again.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _buildResend() {
    return Obx(() {
      final seconds = controller.secondsRemaining.value;
      final resending = controller.isResendingOtp.value;
      final canResend = seconds == 0 && !resending;

      return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            seconds > 0 ? 'Resend OTP in ' : 'Didn’t receive OTP? ',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 14),
          ),
          if (seconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.infoBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatCountdown(seconds),
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryBlue,
                ),
              ),
            )
          else if (resending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue,
                ),
              ),
            )
          else
            TextButton(
              onPressed: canResend ? controller.resendOtp : null,
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 40),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                foregroundColor: AppColors.primaryBlue,
                textStyle: AppTextStyles.bodySmall.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Resend'),
            ),
        ],
      );
    });
  }

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon(
        //   Icons.shield_outlined,
        //   size: 16,
        //   color: AppColors.primary.withOpacity(0.55),
        // ),
        // const SizedBox(width: 6),
        // Flexible(
        //   child: Text(
        //     'Never share your OTP with anyone.',
        //     textAlign: TextAlign.center,
        //     style: AppTextStyles.bodySmall.copyWith(
        //       fontSize: 12.5,
        //       color: AppColors.primary.withOpacity(0.55),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  /// Verify button pinned at the bottom.
  Widget _buildBottomButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: Obx(
              () => _VerifyButton(
                loading: controller.isVerifying.value,
                onPressed: _verify,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Verify OTP button (primary -> secondary gradient, same as Login).
class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: AppColors.selection,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: loading ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.surface,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Submit',
                          style: AppTextStyles.button.copyWith(fontSize: 18),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 24,
                          color: AppColors.surface,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}