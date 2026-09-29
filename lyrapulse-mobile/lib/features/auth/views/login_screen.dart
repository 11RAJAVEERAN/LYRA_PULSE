import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: Stack(
          children: [
            // ============================================================
            // MAIN LOGIN CONTENT
            // ============================================================
Positioned(
  top: screenHeight * 0.23,
  left: 10,
  right: 10,
  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ======================================================
                  // LYRA L LOGO
                  // ======================================================

                  SizedBox(
                    width: 65,
                    height: 65,
                    child: CustomPaint(
                      painter: _LyraLogoPainter(),
                    ),
                  ),

                  const SizedBox(height: 7),

                  // ======================================================
                  // LYRA PULSE
                  // ======================================================

                  Text(
                    'Lyra Pulse',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF172B5C),
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // ======================================================
                  // EMPLOYEE LOGIN
                  // ======================================================

                  Text(
                    'Employee Login',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF30446F),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ======================================================
                  // PHONE NUMBER LABEL
                  // ======================================================

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Phone Number',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF243B68),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ======================================================
                  // PHONE NUMBER FIELD
                  // ======================================================

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: _PhoneField(
                      controller: controller.phoneController,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ======================================================
                  // LOGIN BUTTON
                  // ======================================================

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: controller.login,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4038B5),
                        foregroundColor: Colors.white,

                        elevation: 0,

                        padding: EdgeInsets.zero,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),

                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ============================================================
            // POWERED BY LYRATECH
            // ============================================================

            Positioned(
              left: 0,
              right: 0,
              bottom: 52,

              child: Center(
                child: Text(
                 'POWERED BY LYRATECH',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8996B0),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// PHONE FIELD
// ======================================================================

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _PhoneField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 46,

      decoration: BoxDecoration(
        color: Colors.white,

        border: Border.all(
          color: const Color(0xFFD4DCEB),
          width: 1,
        ),

        borderRadius: BorderRadius.circular(6),
      ),

      child: Row(
        children: [
          const SizedBox(width: 12),

          // ============================================================
          // COUNTRY CODE
          // ============================================================

          Text(
            '+91',
            style: GoogleFonts.poppins(
              color: const Color(0xFF30446F),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: 10),

          // ============================================================
          // VERTICAL DIVIDER
          // ============================================================

          Container(
            width: 1,
            height: 21,
            color: const Color(0xFFD9DFEA),
          ),

          const SizedBox(width: 10),

          // ============================================================
          // PHONE INPUT
          // ============================================================

          Expanded(
            child: TextField(
              controller: controller,

              keyboardType: TextInputType.phone,

              textInputAction: TextInputAction.done,

              maxLength: 10,

              cursorColor: const Color(0xFF4038B5),

              style: GoogleFonts.poppins(
                color: const Color(0xFF172B5C),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),

              decoration: InputDecoration(
                counterText: '',

                border: InputBorder.none,

                enabledBorder: InputBorder.none,

                focusedBorder: InputBorder.none,

                isDense: true,

                contentPadding: EdgeInsets.zero,

                hintText: 'Enter your phone number',

                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFFA5B0C3),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ======================================================================
// LYRA L LOGO
// ======================================================================

class _LyraLogoPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final double w = size.width;
    final double h = size.height;

    final Path path = Path();

    // ================================================================
    // TOP OF L
    // ================================================================

    path.moveTo(
      w * 0.38,
      h * 0.08,
    );

    path.cubicTo(
      w * 0.38,
      h * 0.03,
      w * 0.43,
      0,
      w * 0.50,
      0,
    );

    path.cubicTo(
      w * 0.57,
      0,
      w * 0.62,
      h * 0.05,
      w * 0.62,
      h * 0.12,
    );

    // ================================================================
    // VERTICAL SECTION
    // ================================================================

    path.lineTo(
      w * 0.62,
      h * 0.58,
    );

    // ================================================================
    // CURVED INNER TRANSITION
    // ================================================================

    path.cubicTo(
      w * 0.62,
      h * 0.63,
      w * 0.65,
      h * 0.65,
      w * 0.70,
      h * 0.65,
    );

    // ================================================================
    // HORIZONTAL SECTION
    // ================================================================

    path.lineTo(
      w * 0.87,
      h * 0.65,
    );

    path.cubicTo(
      w * 0.94,
      h * 0.65,
      w,
      h * 0.70,
      w,
      h * 0.77,
    );

    path.cubicTo(
      w,
      h * 0.84,
      w * 0.94,
      h * 0.89,
      w * 0.87,
      h * 0.89,
    );

    path.lineTo(
      w * 0.48,
      h * 0.89,
    );

    // ================================================================
    // BOTTOM CURVE
    // ================================================================

    path.cubicTo(
      w * 0.38,
      h * 0.89,
      w * 0.31,
      h * 0.82,
      w * 0.31,
      h * 0.72,
    );

    path.lineTo(
      w * 0.31,
      h * 0.12,
    );

    path.cubicTo(
      w * 0.31,
      h * 0.06,
      w * 0.34,
      h * 0.03,
      w * 0.38,
      h * 0.08,
    );

    path.close();

    // ================================================================
    // LOGO GRADIENT
    // ================================================================

    final Paint logoPaint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF5C6EFF),
          Color(0xFF3D82FF),
          Color(0xFF087DFF),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          w,
          h,
        ),
      );

    // ================================================================
    // SOFT LOGO GLOW
    // ================================================================

    final Paint glowPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF3479FF).withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      );

    canvas.drawPath(
      path,
      glowPaint,
    );

    // ================================================================
    // DRAW LOGO
    // ================================================================

    canvas.drawPath(
      path,
      logoPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}