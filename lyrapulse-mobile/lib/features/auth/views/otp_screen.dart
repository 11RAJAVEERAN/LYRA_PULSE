import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final AuthController controller = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();

    // Start 30 second countdown
    controller.startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final phone = controller.phoneController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // =========================================================
            // TOP BAR
            // =========================================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                10,
                24,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF172B4D),
                        size: 21,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'OTP VERIFICATION',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8A98A8),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),

            // =========================================================
            // CONTENT
            // =========================================================

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  30,
                ),
                child: Column(
                  children: [
                    // =================================================
                    // LYRA L LOGO
                    // =================================================

                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: const Color(0xFF071A2D),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF087BFF)
                                .withOpacity(0.16),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF20E1FF),
                                Color(0xFF287BFF),
                              ],
                            ).createShader(bounds);
                          },
                          child: Text(
                            'L',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 50,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // =================================================
                    // BRAND
                    // =================================================

                    Text(
                      'LYRA',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF071A2D),
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 5,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'P U L S E',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1683D5),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 42),

                    // =================================================
                    // TITLE
                    // =================================================

                    Text(
                      'Verify Your Number',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF102A43),
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Enter the 6-digit verification code',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF718096),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      'sent to +91 ${_maskedPhone(phone)}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1478D4),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // =================================================
                    // OTP CARD
                    // =================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        18,
                        22,
                        18,
                        22,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFE2E9F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.045),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // =========================================
                          // OTP INPUT
                          // =========================================

                          _OtpInput(
                            controller: controller.otpController,
                          ),

                          const SizedBox(height: 24),

                          // =========================================
                          // VERIFY BUTTON
                          // =========================================

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: Obx(
                              () => DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF176DFF),
                                      Color(0xFF16CFEF),
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF176DFF)
                                          .withOpacity(0.20),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      controller.isVerifying.value
                                          ? null
                                          : controller.verifyOtp,
                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.transparent,
                                    disabledBackgroundColor:
                                        Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(15),
                                    ),
                                  ),
                                  child:
                                      controller.isVerifying.value
                                          ? const SizedBox(
                                              width: 21,
                                              height: 21,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .center,
                                              children: [
                                                Text(
                                                  'Verify & Continue',
                                                  style:
                                                      GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                const Icon(
                                                  Icons
                                                      .arrow_forward_rounded,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =================================================
                    // RESEND
                    // =================================================

                    Text(
                      "Didn't receive the OTP?",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF7A8999),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Obx(
                      () {
                        final seconds =
                            controller.secondsRemaining.value;

                        if (seconds == 0) {
                          return TextButton(
                            onPressed: controller.resendOtp,
                            child: Text(
                              'Resend OTP',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1478D4),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          );
                        }

                        return Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: Color(0xFF1478D4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Resend OTP in ',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF718096),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${seconds}s',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1478D4),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // =================================================
                    // SECURITY INFO
                    // =================================================

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF7FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDCEEFF),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            color: Color(0xFF1478D4),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Never share your OTP with anyone.',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF61758A),
                                fontSize: 10.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    // =================================================
                    // POWERED BY
                    // =================================================

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 1.5,
                          color: const Color(0xFF176DFF),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'POWERED BY LYRATECH',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF9AA8B6),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          width: 28,
                          height: 1.5,
                          color: const Color(0xFF00D9FF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // MASK PHONE NUMBER
  // ===============================================================

  String _maskedPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'\D'), '');

    if (clean.isEmpty) {
      return '••••••••••';
    }

    if (clean.length <= 4) {
      return clean;
    }

    final lastFour = clean.substring(clean.length - 4);

    return '••••••$lastFour';
  }
}

// ===================================================================
// OTP INPUT
// ===================================================================

class _OtpInput extends StatelessWidget {
  const _OtpInput({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        color: const Color(0xFF102A43),
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: 14,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '• • • • • •',
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFFB8C5D1),
          fontSize: 21,
          fontWeight: FontWeight.w500,
          letterSpacing: 7,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFDCE5ED),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF18BDE5),
            width: 1.4,
          ),
        ),
      ),
    );
  }
}