import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Reference design size
    const double designWidth = 441;
    const double designHeight = 776;

    final double sx = size.width / designWidth;
    final double sy = size.height / designHeight;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFF8FBFF),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),
      resizeToAvoidBottomInset: true,

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),

        child: Stack(
          children: [

            // ==========================================================
            // BACKGROUND
            // ==========================================================

            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF8FBFF),
                      Color(0xFFF6FAFF),
                      Color(0xFFF9FCFF),
                    ],
                  ),
                ),
              ),
            ),

            // ==========================================================
            // TOP ILLUSTRATION
            // ==========================================================

            Positioned(
              left: 0,
              top: 0,
              width: size.width,
              height: 300 * sy,
              child: Image.asset(
                'assets/images/login_illustration.png.png',
                fit: BoxFit.fill,
              ),
            ),

            // ==========================================================
            // LYRA PULSE
            // ==========================================================

            Positioned(
              top: 384 * sy,
              left: 0,
              right: 0,
              child: Text(
                'Lyra Pulse',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF11295E),
                  fontSize: 28 * ((sx + sy) / 2),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.7,
                  height: 1,
                ),
              ),
            ),

            // ==========================================================
            // EMPLOYEE LOGIN
            // ==========================================================

            Positioned(
              top: 418 * sy,
              left: 0,
              right: 0,
              child: Text(
                'Employee Login',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF29436F),
                  fontSize: 12 * ((sx + sy) / 2),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // ==========================================================
            // PHONE NUMBER LABEL
            // ==========================================================

            Positioned(
              top: 465 * sy,
              left: 28 * sx,
              child: Text(
                'Phone Number',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF29477B),
                  fontSize: 12 * ((sx + sy) / 2),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // ==========================================================
            // PHONE FIELD
            // ==========================================================

            Positioned(
              top: 487 * sy,
              left: 28 * sx,
              right: 26 * sx,
              height: 48 * sy,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),

                  borderRadius: BorderRadius.circular(
                    8 * ((sx + sy) / 2),
                  ),

                  border: Border.all(
                    color: const Color(0xFFD6E2F2),
                    width: 1,
                  ),
                ),

                child: Row(
                  children: [

                    // ==================================================
                    // +91
                    // ==================================================

                    Padding(
                      padding: EdgeInsets.only(
                        left: 15 * sx,
                        right: 10 * sx,
                      ),

                      child: Row(
                        children: [

                          Text(
                            '+91',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF34517E),
                              fontSize: 11 * ((sx + sy) / 2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          SizedBox(
                            width: 3 * sx,
                          ),

                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 15 * ((sx + sy) / 2),
                            color: const Color(0xFF577296),
                          ),
                        ],
                      ),
                    ),

                    // ==================================================
                    // DIVIDER
                    // ==================================================

                    Container(
                      width: 1,
                      height: 24 * sy,
                      color: const Color(0xFFDCE6F2),
                    ),

                    // ==================================================
                    // PHONE INPUT
                    // ==================================================

                    Expanded(
                      child: TextField(
                        controller: controller.phoneController,

                        keyboardType: TextInputType.phone,

                        textInputAction: TextInputAction.done,

                        maxLength: 10,

                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],

                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1C3764),
                          fontSize: 11 * ((sx + sy) / 2),
                          fontWeight: FontWeight.w500,
                        ),

                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,

                          hintText:
                              'Enter your phone number',

                          hintStyle: GoogleFonts.poppins(
                            color: const Color(0xFFA0B0C7),
                            fontSize: 10.5 * ((sx + sy) / 2),
                            fontWeight: FontWeight.w400,
                          ),

                          contentPadding:
                              EdgeInsets.symmetric(
                            horizontal: 12 * sx,
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================================
            // LOGIN BUTTON
            // ==========================================================

            Positioned(
              top: 554 * sy,
              left: 28 * sx,
              right: 26 * sx,
              height: 46 * sy,

              child: Material(
                color: Colors.transparent,

                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    8 * ((sx + sy) / 2),
                  ),

                  onTap: () {
                    FocusScope.of(context).unfocus();
                    controller.sendOtp();
                  },

                  child: Ink(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        8 * ((sx + sy) / 2),
                      ),

                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,

                        colors: [
                          Color(0xFF4139B5),
                          Color(0xFF5D55DF),
                        ],
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4D45C9)
                              .withOpacity(0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Center(
                      child: Text(
                        'Login',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12 * ((sx + sy) / 2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ==========================================================
            // POWERED BY LYRATECH
            // ==========================================================

            Positioned(
              top: 699 * sy,
              left: 0,
              right: 0,
              child: Text(
                'POWERED BY LYRATECH',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF94A7C0),
                  fontSize: 8 * ((sx + sy) / 2),
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.3,
                ),
              ),
            ),

            // ==========================================================
            // BOTTOM SOFT WAVES
            // ==========================================================

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 105 * sy,

              child: IgnorePointer(
                child: CustomPaint(
                  painter: _LoginBottomWavePainter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// BOTTOM WAVES
// ====================================================================

class _LoginBottomWavePainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final double w = size.width;
    final double h = size.height;

    // ---------------------------------------------------------------
    // First wave
    // ---------------------------------------------------------------

    final Path wave1 = Path();

    wave1.moveTo(
      0,
      h * 0.38,
    );

    wave1.cubicTo(
      w * 0.18,
      h * 0.12,
      w * 0.35,
      h * 0.48,
      w * 0.54,
      h * 0.56,
    );

    wave1.cubicTo(
      w * 0.72,
      h * 0.64,
      w * 0.82,
      h * 0.27,
      w,
      h * 0.12,
    );

    wave1.lineTo(
      w,
      h,
    );

    wave1.lineTo(
      0,
      h,
    );

    wave1.close();

    final Paint paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x221C82FF),
          Color(0x121D6DFF),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          w,
          h,
        ),
      );

    canvas.drawPath(
      wave1,
      paint1,
    );

    // ---------------------------------------------------------------
    // Second wave
    // ---------------------------------------------------------------

    final Path wave2 = Path();

    wave2.moveTo(
      0,
      h * 0.58,
    );

    wave2.cubicTo(
      w * 0.18,
      h * 0.34,
      w * 0.35,
      h * 0.80,
      w * 0.55,
      h * 0.82,
    );

    wave2.cubicTo(
      w * 0.76,
      h * 0.84,
      w * 0.84,
      h * 0.36,
      w,
      h * 0.30,
    );

    wave2.lineTo(
      w,
      h,
    );

    wave2.lineTo(
      0,
      h,
    );

    wave2.close();

    final Paint paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x171B78FF),
          Color(0x081B65FF),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          w,
          h,
        ),
      );

    canvas.drawPath(
      wave2,
      paint2,
    );
  }

  @override
  bool shouldRepaint(
    covariant _LoginBottomWavePainter oldDelegate,
  ) {
    return false;
  }
}