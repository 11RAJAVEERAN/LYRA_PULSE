import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class SplashContent extends StatelessWidget {
  const SplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom wave background
        Positioned.fill(
          child: CustomPaint(
            painter: _SplashWavePainter(),
          ),
        ),

        // Logo + text
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LyraLogo(),

              const SizedBox(height: 20),

              const Text(
                'Lyra Pulse',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Work Better Together',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LyraLogo extends StatelessWidget {
  const _LyraLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _LyraLogoPainter(),
      ),
    );
  }
}

class _LyraLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.secondary,
        AppColors.primary,
        Color(0xFF0EA5E9),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      )
      ..style = PaintingStyle.fill;

    final path = Path();

    // Vertical part of Lyra logo
    path.moveTo(
      size.width * 0.27,
      size.height * 0.12,
    );

    path.quadraticBezierTo(
      size.width * 0.27,
      size.height * 0.05,
      size.width * 0.36,
      size.height * 0.02,
    );

    path.lineTo(
      size.width * 0.48,
      0,
    );

    path.lineTo(
      size.width * 0.48,
      size.height * 0.62,
    );

    // Bottom horizontal part
    path.lineTo(
      size.width * 0.72,
      size.height * 0.62,
    );

    path.quadraticBezierTo(
      size.width * 0.86,
      size.height * 0.62,
      size.width * 0.86,
      size.height * 0.76,
    );

    path.quadraticBezierTo(
      size.width * 0.86,
      size.height * 0.89,
      size.width * 0.72,
      size.height * 0.89,
    );

    path.lineTo(
      size.width * 0.34,
      size.height * 0.89,
    );

    path.quadraticBezierTo(
      size.width * 0.27,
      size.height * 0.89,
      size.width * 0.27,
      size.height * 0.80,
    );

path.quadraticBezierTo(
      size.width * 0.27,
      size.height * 0.89,
      size.width * 0.27,
      size.height * 0.80,
    );

  path.quadraticBezierTo(
      size.width * 0.27,
      size.height * 0.89,
      size.width * 0.27,
      size.height * 0.80,
    );


    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

class _SplashWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // First wave
    final firstPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.35)
      ..style = PaintingStyle.fill;

    final firstWave = Path();

    firstWave.moveTo(
      0,
      size.height * 0.77,
    );

    firstWave.cubicTo(
      size.width * 0.15,
      size.height * 0.65,
      size.width * 0.25,
      size.height * 0.72,
      size.width * 0.40,
      size.height * 0.82,
    );

    firstWave.cubicTo(
      size.width * 0.58,
      size.height * 0.94,
      size.width * 0.75,
      size.height * 0.74,
      size.width,
      size.height * 0.65,
    );

    firstWave.lineTo(
      size.width,
      size.height,
    );

    firstWave.lineTo(
      0,
      size.height,
    );

    firstWave.close();

    canvas.drawPath(
      firstWave,
      firstPaint,
    );

    // Purple wave
    final secondPaint = Paint()
      ..color = AppColors.secondary.withOpacity(0.38)
      ..style = PaintingStyle.fill;

    final secondWave = Path();

    secondWave.moveTo(
      0,
      size.height * 0.86,
    );

    secondWave.cubicTo(
      size.width * 0.18,
      size.height * 0.75,
      size.width * 0.32,
      size.height * 0.96,
      size.width * 0.50,
      size.height * 0.82,
    );

    secondWave.cubicTo(
      size.width * 0.70,
      size.height * 0.66,
      size.width * 0.82,
      size.height * 0.70,
      size.width,
      size.height * 0.60,
    );

    secondWave.lineTo(
      size.width,
      size.height,
    );

    secondWave.lineTo(
      0,
      size.height,
    );

    secondWave.close();

    canvas.drawPath(
      secondWave,
      secondPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}