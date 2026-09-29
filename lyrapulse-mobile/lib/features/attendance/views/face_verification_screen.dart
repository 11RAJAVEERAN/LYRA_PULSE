import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_confirmation_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
    extends State<FaceVerificationScreen>
    with TickerProviderStateMixin {
  late final AnimationController pulseController;
  late final AnimationController scanController;

  bool isScanning = false;
  bool verified = false;

  @override
  void initState() {
    super.initState();

    pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    pulseController.dispose();
    scanController.dispose();
    super.dispose();
  }

  // ===============================================================
  // START FACE VERIFICATION
  // ===============================================================

  Future<void> _startVerification() async {
    if (isScanning || verified) return;

    setState(() {
      isScanning = true;
    });

    scanController.repeat();

    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    scanController.stop();

    setState(() {
      isScanning = false;
      verified = true;
    });
  }

  // ===============================================================
  // CONTINUE TO ATTENDANCE CONFIRMATION
  // ===============================================================

  void _continue() {
    if (!verified) return;

    Get.to(
      () => const AttendanceConfirmationScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),
      body: SafeArea(
        child: Stack(
          children: [
            // =========================================================
            // BACKGROUND GLOW
            // =========================================================

            Positioned(
              top: -170,
              right: -150,
              child: _glow(
                360,
                const Color(0xFF087BFF),
              ),
            ),

            Positioned(
              bottom: -180,
              left: -150,
              child: _glow(
                380,
                const Color(0xFF00D9FF),
              ),
            ),

            // =========================================================
            // CONTENT
            // =========================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                22,
                18,
                22,
                30,
              ),
              child: Column(
                children: [
                  // =====================================================
                  // TOP BAR
                  // =====================================================

                  Row(
                    children: [
                      _backButton(),
                      const Spacer(),
                      _secureBadge(),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =====================================================
                  // LYRA LOGO
                  // =====================================================

                  _lyraLogo(),

                  const SizedBox(height: 22),

                  // =====================================================
                  // TITLE
                  // =====================================================

                  Text(
                    'FACE',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 5),

                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFF20E4FF),
                          Color(0xFF287EFF),
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'VERIFICATION',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    verified
                        ? 'Your identity has been verified'
                        : 'Position your face inside the frame',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF7F96AB),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // FACE CAMERA CARD
                  // =====================================================

                  AnimatedBuilder(
                    animation: pulseController,
                    builder: (context, child) {
                      return Container(
                        width: double.infinity,
                        height: 370,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xCC071A2D),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: verified
                                ? const Color(0xFF24E5C0)
                                    .withOpacity(0.5)
                                : const Color(0xFF17415F),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: verified
                                  ? const Color(0xFF24E5C0)
                                      .withOpacity(0.08)
                                  : Colors.black.withOpacity(0.25),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(21),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF0D3048),
                                Color(0xFF061827),
                              ],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // CAMERA CORNERS

                              Positioned(
                                top: 22,
                                left: 22,
                                child: _corner(
                                  top: true,
                                  left: true,
                                ),
                              ),

                              Positioned(
                                top: 22,
                                right: 22,
                                child: _corner(
                                  top: true,
                                  left: false,
                                ),
                              ),

                              Positioned(
                                bottom: 22,
                                left: 22,
                                child: _corner(
                                  top: false,
                                  left: true,
                                ),
                              ),

                              Positioned(
                                bottom: 22,
                                right: 22,
                                child: _corner(
                                  top: false,
                                  left: false,
                                ),
                              ),

                              // FACE FRAME

                              SizedBox(
                                width: 205,
                                height: 270,
                                child: CustomPaint(
                                  painter: _FaceFramePainter(
                                    pulse: pulseController.value,
                                    verified: verified,
                                  ),
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(
                                        milliseconds: 300,
                                      ),
                                      width: 125,
                                      height: 165,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(
                                          65,
                                        ),
                                        border: Border.all(
                                          color: verified
                                              ? const Color(
                                                  0xFF24E5C0,
                                                )
                                              : const Color(
                                                  0xFF2BDFFF,
                                                ).withOpacity(
                                                  0.45 +
                                                      pulseController
                                                              .value *
                                                          0.25,
                                                ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Icon(
                                        verified
                                            ? Icons
                                                .verified_rounded
                                            : Icons
                                                .person_outline_rounded,
                                        size: 70,
                                        color: verified
                                            ? const Color(
                                                0xFF24E5C0,
                                              )
                                            : const Color(
                                                0xFF9CEFFF,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // SCANNING LINE

                              if (isScanning)
                                AnimatedBuilder(
                                  animation: scanController,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: 60 +
                                          scanController.value *
                                              245,
                                      left: 45,
                                      right: 45,
                                      child: Container(
                                        height: 2,
                                        decoration: BoxDecoration(
                                          gradient:
                                              const LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Color(0xFF22E6FF),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF00E5FF,
                                              ).withOpacity(0.8),
                                              blurRadius: 12,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // STATUS

                              Positioned(
                                bottom: 20,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color(0xFF071A2D),
                                    borderRadius:
                                        BorderRadius.circular(20),
                                    border: Border.all(
                                      color: verified
                                          ? const Color(
                                              0xFF24E5C0,
                                            ).withOpacity(0.35)
                                          : const Color(
                                              0xFF214B68,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Icon(
                                        verified
                                            ? Icons
                                                .check_circle_rounded
                                            : isScanning
                                                ? Icons
                                                    .radar_rounded
                                                : Icons
                                                    .face_outlined,
                                        size: 15,
                                        color: verified
                                            ? const Color(
                                                0xFF24E5C0,
                                              )
                                            : const Color(
                                                0xFF2BDFFF,
                                              ),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        verified
                                            ? 'FACE VERIFIED'
                                            : isScanning
                                                ? 'SCANNING...'
                                                : 'READY TO SCAN',
                                        style:
                                            GoogleFonts.poppins(
                                          color: verified
                                              ? const Color(
                                                  0xFF24E5C0,
                                                )
                                              : const Color(
                                                  0xFF9BB3C6,
                                                ),
                                          fontSize: 9,
                                          fontWeight:
                                              FontWeight.w700,
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 18),

                  // =====================================================
                  // LOCATION STATUS
                  // =====================================================

                  _verificationStatus(
                    icon: Icons.location_on_outlined,
                    title: 'Location Verified',
                    subtitle: 'Office location confirmed',
                    verified: true,
                  ),

                  const SizedBox(height: 10),

                  // =====================================================
                  // FACE STATUS
                  // =====================================================

                  _verificationStatus(
                    icon: Icons.face_outlined,
                    title: 'Face Verification',
                    subtitle: verified
                        ? 'Identity successfully verified'
                        : 'Waiting for verification',
                    verified: verified,
                  ),

                  const SizedBox(height: 20),

                  // =====================================================
                  // MAIN BUTTON
                  // =====================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: verified
                              ? const [
                                  Color(0xFF0FAF91),
                                  Color(0xFF24E5C0),
                                ]
                              : const [
                                  Color(0xFF176DFF),
                                  Color(0xFF18D5EF),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (verified
                                    ? const Color(0xFF24E5C0)
                                    : const Color(0xFF00CFFF))
                                .withOpacity(0.22),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isScanning
                            ? null
                            : verified
                                ? _continue
                                : _startVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent,
                          disabledBackgroundColor:
                              Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: isScanning
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 19,
                                    height: 19,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Scanning Face...',
                                    style:
                                        GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    verified
                                        ? Icons
                                            .arrow_forward_rounded
                                        : Icons.face_rounded,
                                    size: 21,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    verified
                                        ? 'Continue'
                                        : 'Start Face Verification',
                                    style:
                                        GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // =====================================================
                  // SECURITY
                  // =====================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF536D83),
                        size: 14,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Secure identity verification',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF536D83),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // POWERED BY

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 1.5,
                        decoration:
                            const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF176DFF),
                              Color(0xFF00D9FF),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'POWERED BY LYRATECH',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF536D83),
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.1,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Container(
                        width: 28,
                        height: 1.5,
                        decoration:
                            const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF00D9FF),
                              Color(0xFF176DFF),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // LYRA LOGO
  // ===============================================================

  Widget _lyraLogo() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF071E32),
        border: Border.all(
          color: const Color(0xFF20DFFF),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF00D9FF).withOpacity(0.18),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'L',
          style: GoogleFonts.poppins(
            color: const Color(0xFF25DFFF),
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // SECURE BADGE
  // ===============================================================

  Widget _secureBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2136),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1D4564),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF24E5C0),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SECURE',
            style: GoogleFonts.poppins(
              color: const Color(0xFF91AABD),
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // BACK BUTTON
  // ===============================================================

  Widget _backButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0A2136),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1D4564),
        ),
      ),
      child: IconButton(
        onPressed: Get.back,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }

  // ===============================================================
  // VERIFICATION STATUS
  // ===============================================================

  Widget _verificationStatus({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool verified,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF081D31),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: verified
              ? const Color(0xFF1A665A)
              : const Color(0xFF194663),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: verified
                  ? const Color(0xFF0B3B36)
                  : const Color(0xFF0B3042),
              borderRadius:
                  BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: verified
                  ? const Color(0xFF24E5C0)
                  : const Color(0xFF29E2F7),
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF6E879C),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            verified
                ? Icons.check_circle_rounded
                : Icons.circle_outlined,
            color: verified
                ? const Color(0xFF24E5C0)
                : const Color(0xFF49677D),
            size: 20,
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // CAMERA CORNER
  // ===============================================================

  Widget _corner({
    required bool top,
    required bool left,
  }) {
    return SizedBox(
      width: 26,
      height: 26,
      child: CustomPaint(
        painter: _CornerPainter(
          top: top,
          left: left,
        ),
      ),
    );
  }

  // ===============================================================
  // GLOW
  // ===============================================================

  Widget _glow(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.03),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// FACE FRAME
// ===================================================================

class _FaceFramePainter extends CustomPainter {
  const _FaceFramePainter({
    required this.pulse,
    required this.verified,
  });

  final double pulse;
  final bool verified;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    const radius = 102.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = verified
          ? const Color(0xFF24E5C0)
          : const Color(0xFF20DFFF)
              .withOpacity(
              0.45 + (pulse * 0.35),
            );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -0.8,
      1.7,
      false,
      paint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      2.35,
      1.7,
      false,
      paint,
    );

    final smallPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = verified
          ? const Color(0xFF24E5C0)
              .withOpacity(0.22)
          : const Color(0xFF287EFF)
              .withOpacity(0.25);

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius - 12,
      ),
      0.2,
      1.2,
      false,
      smallPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _FaceFramePainter oldDelegate,
  ) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.verified != verified;
  }
}

// ===================================================================
// CAMERA CORNER PAINTER
// ===================================================================

class _CornerPainter extends CustomPainter {
  const _CornerPainter({
    required this.top,
    required this.left,
  });

  final bool top;
  final bool left;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF25DFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;

    path.moveTo(
      x,
      y + (top ? 12 : -12),
    );

    path.lineTo(x, y);

    path.lineTo(
      x + (left ? 12 : -12),
      y,
    );

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _CornerPainter oldDelegate,
  ) {
    return false;
  }
}