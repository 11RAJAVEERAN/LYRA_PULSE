import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const Color purple = Color(0xFF5B46F5);
  static const Color dark = Color(0xFF171D38);
  static const Color muted = Color(0xFF7887AD);
  static const Color background = Color(0xFFFCFCFF);

  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
      List.generate(6, (_) => FocusNode());

  final ValueNotifier<int> secondsNotifier = ValueNotifier<int>(15);

  Timer? _timer;
  bool _isVerifying = false;

  String get otp => otpControllers.map((e) => e.text).join();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    secondsNotifier.value = 15;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsNotifier.value > 0) {
        secondsNotifier.value--;
      } else {
        timer.cancel();
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    if (otp.length == 6) {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _verifyOtp() async {
    if (otp.length != 6) {
      _showMessage('Please enter the 6-digit OTP');
      return;
    }

    setState(() => _isVerifying = true);

    // Demo verification only. Replace with backend OTP verification.
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    setState(() => _isVerifying = false);

    Get.offAllNamed(AppRoutes.home);
  }

  void _resendOtp() {
    if (secondsNotifier.value != 0) return;

    for (final controller in otpControllers) {
      controller.clear();
    }

    _startTimer();
    focusNodes.first.requestFocus();
    _showMessage('OTP sent again');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    secondsNotifier.dispose();

    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final node in focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final compact = screenHeight < 700;

            return Stack(
              children: [
                // Full viewport background.
                const Positioned.fill(
                  child: ColoredBox(color: background),
                ),

                // Waves always stay at the bottom of the viewport.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: compact ? 100 : 125,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: BottomWavesPainter(),
                    ),
                  ),
                ),

                // Scrollable content prevents overflow on smaller screens.
                Positioned.fill(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        compact ? 8 : 16,
                        24,
                        compact ? 115 : 145,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 420,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: InkWell(
                                  onTap: () => Get.back(),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF0EEFF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: purple,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: compact ? 12 : 20),

                              const Text(
                                'LYRA PULSE',
                                style: TextStyle(
                                  color: dark,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3,
                                ),
                              ),

                              SizedBox(height: compact ? 18 : 28),

                              Container(
                                width: 82,
                                height: 82,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0EEFF),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 62,
                                    height: 62,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE5E0FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_rounded,
                                      color: purple,
                                      size: 34,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: compact ? 16 : 22),

                              const Text(
                                'Verify Your Number',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: dark,
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                'Enter the 6-digit OTP to continue.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 22),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFE7E5FA),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: purple.withValues(alpha: 0.05),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.phone_iphone_rounded,
                                      color: purple,
                                      size: 18,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      '+91 ••••••3210',
                                      style: TextStyle(
                                        color: dark,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 26),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE7E5FA),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: purple.withValues(alpha: 0.04),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: List.generate(6, (index) {
                                    return Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          left: index == 0 ? 0 : 4,
                                          right: index == 5 ? 0 : 4,
                                        ),
                                        child: AspectRatio(
                                          aspectRatio: 0.82,
                                          child: TextField(
                                            controller: otpControllers[index],
                                            focusNode: focusNodes[index],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            maxLength: 1,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                1,
                                              ),
                                            ],
                                            style: const TextStyle(
                                              color: dark,
                                              fontSize: 21,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            decoration: InputDecoration(
                                              counterText: '',
                                              filled: true,
                                              fillColor:
                                                  const Color(0xFFFCFCFF),
                                              contentPadding: EdgeInsets.zero,
                                              enabledBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE2E0F5),
                                                ),
                                              ),
                                              focusedBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: purple,
                                                  width: 1.8,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) =>
                                                _onOtpChanged(value, index),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF7965FF),
                                        Color(0xFF5139E8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            purple.withValues(alpha: 0.22),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed:
                                        _isVerifying ? null : _verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor:
                                          Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isVerifying
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Verify OTP',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Didn't receive the code? ",
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  ValueListenableBuilder<int>(
                                    valueListenable: secondsNotifier,
                                    builder: (context, seconds, child) {
                                      return InkWell(
                                        onTap: seconds == 0
                                            ? _resendOtp
                                            : null,
                                        child: Text(
                                          seconds == 0
                                              ? 'Resend OTP'
                                              : 'Resend in 00:${seconds.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            color: seconds == 0
                                                ? purple
                                                : muted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),

                              SizedBox(height: compact ? 18 : 24),

                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    color: muted,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Your verification helps keep your account secure.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Footer remains visible above the bottom waves.
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: compact ? 32 : 38,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 1,
                          color: const Color(0xFFC8C4E8),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'POWERED BY LYRA TECH',
                          style: TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 24,
                          height: 1,
                          color: const Color(0xFFC8C4E8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class BottomWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final firstWave = Path()
      ..moveTo(0, size.height * 0.20)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.38,
        size.width * 0.55,
        size.height * 0.90,
        size.width,
        size.height * 0.08,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      firstWave,
      Paint()..color = const Color(0xFFF0EFFF),
    );

    final secondWave = Path()
      ..moveTo(0, size.height * 0.52)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.78,
        size.width * 0.68,
        size.height * 0.98,
        size.width,
        size.height * 0.40,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      secondWave,
      Paint()..color = const Color(0xFFE7E6FF),
    );
  }

  @override
  bool shouldRepaint(covariant BottomWavesPainter oldDelegate) => false;
}