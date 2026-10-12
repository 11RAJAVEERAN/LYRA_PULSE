import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final AuthController controller;
  late final List<TextEditingController> otpFields;
  late final List<FocusNode> focusNodes;
  late final List<GlobalKey> otpBoxKeys;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    controller = Get.find<AuthController>();

    otpFields = List.generate(
      6,
      (_) => TextEditingController(),
    );

    focusNodes = List.generate(
      6,
      (_) => FocusNode(),
    );

    otpBoxKeys = List.generate(
      6,
      (_) => GlobalKey(),
    );

    controller.startCountdown();

    // Keyboard open aana udane OTP box visible-a irukka help pannum.
    for (int i = 0; i < focusNodes.length; i++) {
      focusNodes[i].addListener(() {
        if (focusNodes[i].hasFocus) {
          _scrollToOtpBox(i);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final field in otpFields) {
      field.dispose();
    }

    for (final node in focusNodes) {
      node.dispose();
    }

    _scrollController.dispose();

    super.dispose();
  }

  void _scrollToOtpBox(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final boxContext = otpBoxKeys[index].currentContext;

      if (boxContext != null) {
        Scrollable.ensureVisible(
          boxContext,
          alignment: 0.35,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    controller.otpController.text =
        otpFields.map((field) => field.text).join();

    setState(() {});
  }

  void _verifyOtp() {
    FocusScope.of(context).unfocus();

    controller.otpController.text =
        otpFields.map((field) => field.text).join();

    controller.verifyOtp();
  }

  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 4) {
      return '+91 $digits';
    }

    return '+91 ${digits.substring(0, 2)}******${digits.substring(digits.length - 2)}';
  }

  @override
  Widget build(BuildContext context) {
    final phone = controller.phoneController.text.trim();

    return Scaffold(
    backgroundColor: AppColors.background,
      // Keyboard open aagumbodhu body height automatically adjust aagum.
      resizeToAvoidBottomInset:false,

      body: Stack(
        children: [
          // Background wave 1.
          Positioned(
            bottom: -55,
            left: -70,
            right: -70,
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFF).withValues(alpha: 0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(260, 110),
                  topRight: Radius.elliptical(260, 110),
                ),
              ),
            ),
          ),

          // Background wave 2.
          Positioned(
            bottom: -100,
            left: -30,
            right: -30,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFFDDE5FF).withValues(alpha: 0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(250, 100),
                  topRight: Radius.elliptical(250, 100),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {

return SingleChildScrollView(
  controller: _scrollController,
  keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior.onDrag,

  padding: EdgeInsets.only(
    left: 24,
    right: 24,
    top: 12,
    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
  ),



                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                       

                        // OTP illustration.
                        Container(
                          width: 200,
                          height: 190,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFE8EDFF),
                                Color(0xFFE4F6FF),
                              ],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 140,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 5,
                                  ),
                                  borderRadius: BorderRadius.circular(23),
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
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Positioned(
                                top: 63,
                                left: 36,
                                child: Container(
                                  width: 120,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primary,
                                        AppColors.secondary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child:  Center(
                                    child: Text(
                                      '✱ ✱ ✱ ✱ ✱ ✱',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 10  ,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Positioned(
                                bottom: 28,
                                right: 32,
                                child: Container(
                                  width: 45,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size:35,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 23),

                        Text(
  'OTP Verification',
  style: GoogleFonts.inter(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  ),
),

                        const SizedBox(height: 12),

                         Text(
                          "We've sent a 6-digit OTP to your registered\nmobile number",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            height: 1.55,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.call_rounded,
                              color: AppColors.secondary,
                              size: 23,
                            ),
                             SizedBox(width: 12),
                            Text(
                              _maskPhone(phone),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF152044),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Six OTP boxes.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              key: otpBoxKeys[index],
                              width: (constraints.maxWidth - 48 - 35) / 6,
                              height: 58,
                              child: ValueListenableBuilder<TextEditingValue>(
                                valueListenable: otpFields[index],
                                builder: (context, value, child) {
                                  return TextField(
                                    controller: otpFields[index],
                                    focusNode: focusNodes[index],
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.number,
                                    textInputAction: index == 5
                                        ? TextInputAction.done
                                        : TextInputAction.next,
                                    maxLength: 1,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                 style: GoogleFonts.inter(   
                                           fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF101A39),
                                    ),
                                    decoration: InputDecoration(
                                      counterText: '',
                                      contentPadding: EdgeInsets.zero,
                                      filled: true,
                                      fillColor:
                                          Colors.white.withValues(alpha: 0.75),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFD4D9E5),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: const BorderSide(
                                          color: AppColors.secondary,
                                          width: 2.2,
                                        ),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      _onOtpChanged(value, index);

                                      if (index == 5 && value.isNotEmpty) {
                                        FocusScope.of(context).unfocus();
                                      }
                                    },
                                  );
                                },
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 26),

                        // Resend OTP countdown.
                        Obx(() {
                          final seconds =
                              controller.secondsRemaining.value;

                          final time =
                              '00:${seconds.toString().padLeft(2, '0')}';

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.refresh_rounded,
                                color: AppColors.secondary,
                                size: 26,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                seconds > 0
                                    ? 'Resend OTP in '
                                    : 'Didn’t receive OTP? ',

                                        style: GoogleFonts.inter(         
                                               fontSize: 14,
                                  color: Color(0xFF697694),
                                ),
                              ),
                              if (seconds > 0)
                                Text(
                                  time,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.secondary,
                                  ),
                                )
                              else
                                GestureDetector(
                                  onTap: controller.resendOtp,
                                  child:  Text(
                                    'Resend',
                                   style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }),

                        const SizedBox(height: 30),

                        // Verify button.
                        SizedBox(
                          width: double.infinity,
                          height: 66,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                  
                                ],
                              ),
                              borderRadius: BorderRadius.circular(23),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.22),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _verifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(23),
                                ),
                              ),
                              child: Obx(
                                () => controller.isVerifying.value
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    :  Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Verify OTP',
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 18),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 29,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Security message remains part of the scrollable page.
                        //  Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     // Icon(
                        //     //   Icons.verified_user_outlined,
                        //     //   color: AppColors.textSecondary,
                        //     //   size: 22,
                        //     // ),
                        //     // SizedBox(width: 9),
                        //     // Flexible(
                        //     //   child: Text(
                        //     //     'Your security is our priority',
                        //     //     textAlign: TextAlign.center,
                        //     //     style: GoogleFonts.inter(
                        //     //       fontSize: 13,
                        //     //       color: AppColors.textSecondary,
                        //     //     ),
                        //     //   ),
                        //     // ),
                        //   ],
                        // ),

                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}