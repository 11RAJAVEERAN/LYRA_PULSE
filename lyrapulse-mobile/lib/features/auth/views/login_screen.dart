import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
import '../../../app/theme/app_colors.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final keyboardOpen = media.viewInsets.bottom > 0;

    const double designWidth = 441;
    const double designHeight = 776;

    final double sx = size.width / designWidth;
    final double sy = size.height / designHeight;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.surfaceMuted,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availableHeight = constraints.maxHeight;
            final double contentHeight = keyboardOpen
                ? availableHeight
                : (776 * sy).clamp(0.0, double.infinity);

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: keyboardOpen
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: SizedBox(
                width: size.width,
                height: keyboardOpen ? availableHeight : contentHeight,
                child: Stack(
                  children: [
                    // BACKGROUND
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.surfaceMuted,
                              AppColors.surfaceMuted,
                              AppColors.surfaceMuted,
                            ],
                          ),
                        ),
                      ),
                    ),

                    // TOP ILLUSTRATION
                    Positioned(
                      left: 0,
                      top: 0,
                      width: size.width,
                      height: (keyboardOpen ? 220 : 300) * sy,
                      child: Image.asset(
                        'assets/images/login_illustration.png',
                        fit: BoxFit.fill,
                      ),
                    ),

                    // LYRA PULSE
                    Positioned(
                      top: (keyboardOpen ? 245 : 384) * sy,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Lyra Pulse',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 28 * ((sx + sy) / 2),
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                          height: 1,
                        ),
                      ),
                    ),

                    // EMPLOYEE LOGIN
                    Positioned(
                      top: (keyboardOpen ? 278 : 418) * sy,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Employee Login',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 12 * ((sx + sy) / 2),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    // PHONE NUMBER LABEL
                    Positioned(
                      top: (keyboardOpen ? 330 : 465) * sy,
                      left: 28 * sx,
                      child: Text(
                        'Phone Number',
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 12 * ((sx + sy) / 2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    // PHONE NUMBER FIELD
                    Positioned(
                      top: (keyboardOpen ? 352 : 487) * sy,
                      left: 28 * sx,
                      right: 26 * sx,
                      height: 48 * sy,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(
                            8 * ((sx + sy) / 2),
                          ),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // COUNTRY CODE
                            Padding(
                              padding: EdgeInsets.only(
                                left: 15 * sx,
                                right: 10 * sx,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '+91',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 11 * ((sx + sy) / 2),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 3 * sx),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 15 * ((sx + sy) / 2),
                                    color: AppColors.textSecondary,
                                  ),
                                ],
                              ),
                            ),

                            // DIVIDER
                            Container(
                              width: 1,
                              height: 24 * sy,
                              color: AppColors.border,
                            ),

                            // PHONE INPUT
                            Expanded(
                              child: TextField(
                                controller: controller.phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.done,
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontSize: 14 * ((sx + sy) / 2),
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  hintText: 'Enter your phone number',
                                  hintStyle: GoogleFonts.inter(
                                    color: AppColors.borderStrong,
                                    fontSize: 10.5 * ((sx + sy) / 2),
                                    fontWeight: FontWeight.w400,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
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

                    // LOGIN BUTTON
                    Positioned(
                      top: (keyboardOpen ? 420 : 554) * sy,
                      left: 28 * sx,
                      right: 26 * sx,
                      height: 46 * sy,
                      child: Material(
                        color: AppColors.surface,
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
                                  AppColors.secondaryDark,
                                  AppColors.secondary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.secondaryDark.withValues(alpha: 0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Login',
                                style: GoogleFonts.inter(
                                  color: AppColors.surface,
                                  fontSize: 12 * ((sx + sy) / 2),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // POWERED BY LYRATECH
                    if (!keyboardOpen)
                      Positioned(
                        top: 699 * sy,
                        left: 0,
                        right: 0,
                        child: Text(
                          'POWERED BY LYRATECH',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: AppColors.borderStrong,
                            fontSize: 8 * ((sx + sy) / 2),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.3,
                          ),
                        ),
                      ),

                    // BOTTOM WAVES
                    if (!keyboardOpen)
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
          },
        ),
      ),
    );
  }
}

// BOTTOM WAVES
class _LoginBottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path wave1 = Path()
      ..moveTo(0, h * 0.38)
      ..cubicTo(
        w * 0.18,
        h * 0.12,
        w * 0.35,
        h * 0.48,
        w * 0.54,
        h * 0.56,
      )
      ..cubicTo(
        w * 0.72,
        h * 0.64,
        w * 0.82,
        h * 0.27,
        w,
        h * 0.12,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final Paint paint1 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surfaceBorder,
          AppColors.infoSurface,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(wave1, paint1);

    final Path wave2 = Path()
      ..moveTo(0, h * 0.58)
      ..cubicTo(
        w * 0.18,
        h * 0.34,
        w * 0.35,
        h * 0.80,
        w * 0.55,
        h * 0.82,
      )
      ..cubicTo(
        w * 0.76,
        h * 0.84,
        w * 0.84,
        h * 0.36,
        w,
        h * 0.30,
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final Paint paint2 = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.secondarySoft,
          AppColors.surfaceMuted,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(wave2, paint2);
  }

  @override
  bool shouldRepaint(covariant _LoginBottomWavePainter oldDelegate) {
    return false;
  }
}

