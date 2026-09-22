import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../controllers/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    Get.find<SplashController>();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, .72, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: .94, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, .72, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF061A52), Color(0xFF07123D), Color(0xFF150B52)],
            stops: [0, .52, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _GlowBackdrop()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 680;
                  final horizontalPadding =
                      constraints.maxWidth < 360 ? 22.0 : 28.0;
                  final topPadding =
                      (constraints.maxHeight * .075).clamp(26.0, 54.0);
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 26 : topPadding,
                      horizontalPadding,
                      compact ? 20 : 28,
                    ),
                    child: Column(
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: const _Branding(),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) => Transform.scale(
                                scale: 1 + (_animationController.value * .018),
                                child: child,
                              ),
                              child: const _FingerprintSection(),
                            ),
                          ),
                        ),
                        const _BottomSignature(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(painter: _MonogramPainter())),
        const SizedBox(height: 14),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFF6EDBFF), Color(0xFF6D4AFF)],
          ).createShader(bounds),
          child: Text(
            'Lyra Pulse',
            style: AppTextStyles.display.copyWith(
              color: Colors.white,
              fontSize: 35,
              letterSpacing: -.5,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Employee Attendance',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: .82),
            letterSpacing: 3.1,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FingerprintSection extends StatelessWidget {
  const _FingerprintSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scannerSize = math.max(
          170.0,
          math.min(
            224.0,
            math.min(constraints.maxWidth * .58, constraints.maxHeight - 78),
          ),
        );
        final ringSize = scannerSize - 20;
        final iconSize = scannerSize * .59;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: scannerSize,
              height: scannerSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: scannerSize - 8,
                    height: scannerSize - 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: .18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .2),
                          blurRadius: 34,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: ringSize,
                    height: ringSize,
                    child: const CustomPaint(painter: _ScanRingPainter()),
                  ),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8AFFFF),
                        Color(0xFF21B9FF),
                        Color(0xFF5940FF),
                      ],
                    ).createShader(bounds),
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tap your finger',
              style: AppTextStyles.title
                  .copyWith(color: Colors.white, fontSize: 19),
            ),
            const SizedBox(height: 6),
            Text(
              'to mark attendance',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: .68),
                letterSpacing: .5,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BottomSignature extends StatelessWidget {
  const _BottomSignature();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF27D9FF), Color(0xFF694BFF)],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'WORK • TRACK • GROW',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: .72),
            letterSpacing: 2.6,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 44, child: CustomPaint(painter: _WavePainter())),
      ],
    );
  }
}

class _GlowBackdrop extends StatelessWidget {
  const _GlowBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _GlowPainter()));
  }
}

class _MonogramPainter extends CustomPainter {
  const _MonogramPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 74, size.height / 74);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8AFFFF), Color(0xFF18C8FF), Color(0xFF4434FF)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.square;
    final path = Path()
      ..moveTo(16, 56)
      ..lineTo(16, 15)
      ..lineTo(58, 15)
      ..lineTo(58, 59)
      ..lineTo(33, 59)
      ..moveTo(33, 30)
      ..lineTo(33, 48)
      ..lineTo(45, 48);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanRingPainter extends CustomPainter {
  const _ScanRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0x0018D9FF),
          Color(0xFF18D9FF),
          Color(0xFF6B46FF),
          Color(0x0018D9FF),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    for (var index = 0; index < 16; index++) {
      final start = (math.pi * 2 * index / 16) + .08;
      final sweep = index.isEven ? .18 : .1;
      canvas.drawArc(Offset.zero & size, start, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        colors: [
          Color(0x0034D9FF),
          Color(0x8834D9FF),
          Color(0x884F46E5),
          Color(0x0034D9FF)
        ],
      ).createShader(Offset.zero & size);
    for (var index = 0; index < 3; index++) {
      final path = Path()
        ..moveTo(0, size.height * (.35 + index * .22))
        ..cubicTo(
          size.width * .25,
          -2 + index * 3,
          size.width * .5,
          size.height + index * 2,
          size.width,
          size.height * (.3 + index * .22),
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x331A9BFF), Color(0x001A9BFF)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .08, size.height * .08),
          radius: size.width * .65,
        ),
      );
    final purple = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x332B14D6), Color(0x002B14D6)],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * .95, size.height * .52),
          radius: size.width * .6,
        ),
      );
    canvas.drawRect(Offset.zero & size, blue);
    canvas.drawRect(Offset.zero & size, purple);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
