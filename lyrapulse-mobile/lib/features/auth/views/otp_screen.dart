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

class _OtpScreenState extends State<OtpScreen>
    with WidgetsBindingObserver {
  // Keeps the content phone-sized on Flutter Web / tablets.
  static const double _maxContentWidth = 480;

  final controller = Get.find<AuthController>();
  final _verifyButtonKey = GlobalKey();

  Worker? _verifyWorker;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    controller.startCountdown();

    // A verification attempt that ends without a signed-in employee failed,
    // so flag the boxes. The controller already shows the message.
    _verifyWorker = ever<bool>(
      controller.isVerifying,
      (verifying) {
        if (!verifying &&
            controller.employee.value == null &&
            mounted) {
          setState(() => _hasError = true);
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _verifyWorker?.dispose();

    controller.stopCountdown();

    super.dispose();
  }

  /// When the keyboard opens, keep the Verify button visible above it.
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final view = View.maybeOf(context);

      if (view == null || view.viewInsets.bottom <= 0) {
        return;
      }

      final buttonContext = _verifyButtonKey.currentContext;

      if (buttonContext == null) return;

      Scrollable.ensureVisible(
        buttonContext,
        alignment: 1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignmentPolicy:
            ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  String get _maskedPhone {
    final digits = controller.phoneController.text
        .replaceAll(RegExp(r'\D'), '');

    if (digits.length < 4) {
      return '+91 $digits';
    }

    return '+91 ${digits.substring(0, 2)}******'
        '${digits.substring(digits.length - 2)}';
  }

  String _formatCountdown(int seconds) {
    final minutes =
        (seconds ~/ 60).toString().padLeft(2, '0');

    final secs =
        (seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$secs';
  }

  void _verify() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!RegExp(r'^\d{6}$')
        .hasMatch(controller.otpController.text)) {
      setState(() => _hasError = true);
    }

    controller.verifyOtp();
  }

  void _clearError(String _) {
    if (_hasError) {
      setState(() => _hasError = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,

        // Match bottom system area with the page decoration.
        systemNavigationBarColor: AppColors.selected,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Bottom decorative wave - front.
            _buildWave(
              bottom: -55,
              side: -70,
              height: 170,
              radius: 260,
              vRadius: 110,
              color: AppColors.selected,
            ),

            // Bottom decorative wave - back.
            _buildWave(
              bottom: -100,
              side: -30,
              height: 150,
              radius: 250,
              vRadius: 100,
              color: AppColors.infoBackground,
            ),

            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom +
                          20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: _maxContentWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIllustration(),

                        const SizedBox(height: 23),

                        Semantics(
                          header: true,
                          child: Text(
                            'OTP Verification',
                            textAlign: TextAlign.center,

                            // Same heading style as Login screen.
                            style:
                                AppTextStyles.display.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          "We've sent a 6-digit OTP to your registered\n"
                          'mobile number',
                          textAlign: TextAlign.center,

                          // Same body style as Login screen.
                          style:
                              AppTextStyles.bodySmall.copyWith(
                            fontSize: 14,
                          ),
                        ),

                        const SizedBox(height: 18),

                        _buildPhone(),

                        const SizedBox(height: 28),

                        AutofillGroup(
                          child: OtpInput(
                            controller:
                                controller.otpController,
                            hasError: _hasError,
                            onChanged: _clearError,
                          ),
                        ),

                        const SizedBox(height: 26),

                        _buildResend(),

                        const SizedBox(height: 30),

                        Obx(
                          () => _VerifyButton(
                            key: _verifyButtonKey,
                            loading:
                                controller.isVerifying.value,
                            onPressed: _verify,
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWave({
    required double bottom,
    required double side,
    required double height,
    required double radius,
    required double vRadius,
    required Color color,
  }) {
    return Positioned(
      bottom: bottom,
      left: side,
      right: side,
      child: IgnorePointer(
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.elliptical(
                radius,
                vRadius,
              ),
              topRight: Radius.elliptical(
                radius,
                vRadius,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Circle with a phone outline,
  /// password-star bar and check badge.
  Widget _buildIllustration() {
    return Container(
      width: 200,
      height: 190,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,

        // Existing Login theme color.
        color: AppColors.infoBackground,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Phone outline.
          Container(
            width: 100,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary,
                width: 5,
              ),
              borderRadius:
                  BorderRadius.circular(23),
            ),
            child: const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 5),
                child: SizedBox(
                  width: 33,
                  height: 7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius:
                          BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // OTP password strip.
          Positioned(
            top: 63,
            left: 36,
            child: Container(
              width: 120,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  '✱ ✱ ✱ ✱ ✱ ✱',
                  style:
                      AppTextStyles.bodySmall.copyWith(
                    color: AppColors.surface,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Check badge.
          Positioned(
            bottom: 28,
            right: 32,
            child: Container(
              width: 45,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 35,
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhone() {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.call_rounded,
          color: AppColors.primaryBlue,
          size: 23,
        ),

        const SizedBox(width: 12),

        Text(
          _maskedPhone,
          style: AppTextStyles.title.copyWith(
            fontSize: 17,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildResend() {
    return Obx(() {
      final seconds =
          controller.secondsRemaining.value;

      final resending =
          controller.isResendingOtp.value;

      final canResend =
          seconds == 0 && !resending;

      return Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.refresh_rounded,
            color: AppColors.primaryBlue,
            size: 26,
          ),

          const SizedBox(width: 9),

          Flexible(
            child: Wrap(
              crossAxisAlignment:
                  WrapCrossAlignment.center,
              children: [
                Text(
                  seconds > 0
                      ? 'Resend OTP in '
                      : 'Didn’t receive OTP? ',
                  style:
                      AppTextStyles.bodySmall.copyWith(
                    fontSize: 14,
                  ),
                ),

                if (seconds > 0)
                  Text(
                    _formatCountdown(seconds),
                    style: AppTextStyles.bodySmall
                        .copyWith(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppColors.primaryBlue,
                    ),
                  )
                else if (resending)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                          AppColors.primaryBlue,
                    ),
                  )
                else
                  GestureDetector(
                    behavior:
                        HitTestBehavior.opaque,
                    onTap: canResend
                        ? controller.resendOtp
                        : null,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 8,
                      ),
                      child: Text(
                        'Resend',
                        style: AppTextStyles
                            .bodySmall
                            .copyWith(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color: AppColors
                              .primaryBlue,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// Verify OTP button.
/// Uses the same primary -> secondary gradient
/// used by the Login button.
class _VerifyButton extends StatelessWidget {
  const _VerifyButton({
    required this.loading,
    required this.onPressed,
    super.key,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius =
        BorderRadius.circular(23);

    return SizedBox(
      width: double.infinity,
      height: 66,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
          borderRadius: radius,

          // Same shadow token used by Login screen.
          boxShadow: const [
            BoxShadow(
              color: AppColors.selection,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap:
                loading ? null : onPressed,
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color:
                            AppColors.surface,
                      ),
                    )
                  : Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          'Verify OTP',
                          style: AppTextStyles
                              .button
                              .copyWith(
                            fontSize: 17,
                          ),
                        ),

                        const SizedBox(
                            width: 18),

                        const Icon(
                          Icons
                              .arrow_forward_rounded,
                          size: 29,
                          color:
                              AppColors.surface,
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