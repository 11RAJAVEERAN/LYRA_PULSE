import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF14244A),
              Color(0xFF0B1838),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Bottom decorative wave
            Positioned(
              left: -80,
              right: -80,
              bottom: -20,
              child: SizedBox(
                height: 220,
                child: CustomPaint(
                  painter: _SplashWavePainter(),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLogo(),

                  const SizedBox(height: 28),

                  const Text(
                    'Lyra Pulse',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Work Better Together',
                    style: TextStyle(
                      color: Color(0xFFE1E7F5),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 92,
      height: 92,
      child: CustomPaint(
        painter: _LyraLogoPainter(),
      ),
    );
  }
}

class _LyraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6546FF),
          Color(0xFF2E8CFF),
        ],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    final path = Path();

    // Left vertical shape
    path.moveTo(size.width * 0.22, size.height * 0.18);
    path.quadraticBezierTo(
      size.width * 0.22,
      size.height * 0.10,
      size.width * 0.31,
      size.height * 0.07,
    );

    path.lineTo(size.width * 0.43, size.height * 0.03);

    path.lineTo(size.width * 0.43, size.height * 0.59);

    path.lineTo(size.width * 0.68, size.height * 0.59);

    path.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.59,
      size.width * 0.82,
      size.height * 0.72,
    );

    path.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.84,
      size.width * 0.69,
      size.height * 0.84,
    );

    path.lineTo(size.width * 0.30, size.height * 0.84);

    path.quadraticBezierTo(
      size.width * 0.22,
      size.height * 0.84,
      size.width * 0.22,
      size.height * 0.75,
    );

    path.close();

    canvas.drawPath(path, paint);

    // Blue lower section
    final bluePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF3B82F6),
          Color(0xFF00A8FF),
        ],
      ).createShader(
        Rect.fromLTWH(0, size.height * .4, size.width, size.height),
      );

    final bluePath = Path();

    bluePath.moveTo(size.width * 0.43, size.height * 0.58);
    bluePath.lineTo(size.width * 0.69, size.height * 0.58);

    bluePath.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.58,
      size.width * 0.82,
      size.height * 0.71,
    );

    bluePath.quadraticBezierTo(
      size.width * 0.82,
      size.height * 0.83,
      size.width * 0.69,
      size.height * 0.83,
    );

    bluePath.lineTo(size.width * 0.43, size.height * 0.83);

    bluePath.close();

    canvas.drawPath(bluePath, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final purplePaint = Paint()
      ..color = const Color(0xFF29206B).withOpacity(0.65)
      ..style = PaintingStyle.fill;

    final bluePaint = Paint()
      ..color = const Color(0xFF214C9C).withOpacity(0.35)
      ..style = PaintingStyle.fill;

    // Back wave
    final backWave = Path();

    backWave.moveTo(0, size.height * 0.65);

    backWave.cubicTo(
      size.width * 0.15,
      size.height * 0.30,
      size.width * 0.30,
      size.height * 0.95,
      size.width * 0.50,
      size.height * 0.55,
    );

    backWave.cubicTo(
      size.width * 0.68,
      size.height * 0.20,
      size.width * 0.82,
      size.height * 0.80,
      size.width,
      size.height * 0.45,
    );

    backWave.lineTo(size.width, size.height);
    backWave.lineTo(0, size.height);
    backWave.close();

    canvas.drawPath(backWave, bluePaint);

    // Front wave
    final frontWave = Path();

    frontWave.moveTo(0, size.height * 0.75);

    frontWave.cubicTo(
      size.width * 0.18,
      size.height * 0.40,
      size.width * 0.30,
      size.height * 0.95,
      size.width * 0.48,
      size.height * 0.65,
    );

    frontWave.cubicTo(
      size.width * 0.65,
      size.height * 0.38,
      size.width * 0.80,
      size.height * 0.90,
      size.width,
      size.height * 0.55,
    );

    frontWave.lineTo(size.width, size.height);
    frontWave.lineTo(0, size.height);
    frontWave.close();

    canvas.drawPath(frontWave, purplePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}