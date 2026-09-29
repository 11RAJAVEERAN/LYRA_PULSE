import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.onDark = false,
    this.compact = false,
  });

  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Login screen:
    // compact = true -> L logo மட்டும்
    if (compact) {
      return const SizedBox(
        width: 58,
        height: 58,
        child: _LyraMark(),
      );
    }

    // Other screens / default logo
    final titleStyle = AppTextStyles.headline.copyWith(
      color: onDark ? Colors.white : AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 72,
          height: 72,
          child: _LyraMark(),
        ),
        const SizedBox(height: 12),
        Text(
          'LYRA PULSE',
          style: titleStyle,
        ),
      ],
    );
  }
}

class _LyraMark extends StatelessWidget {
  const _LyraMark();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LyraMarkPainter(),
    );
  }
}

class _LyraMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary,
        AppColors.secondary,
        AppColors.accent,
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

    final width = size.width;
    final height = size.height;

    // Vertical part of L
    final verticalPath = Path();

    verticalPath.moveTo(width * 0.35, height * 0.12);
    verticalPath.quadraticBezierTo(
      width * 0.35,
      height * 0.07,
      width * 0.42,
      height * 0.04,
    );

    verticalPath.quadraticBezierTo(
      width * 0.52,
      0,
      width * 0.52,
      height * 0.12,
    );

    verticalPath.lineTo(
      width * 0.52,
      height * 0.67,
    );

    verticalPath.quadraticBezierTo(
      width * 0.52,
      height * 0.73,
      width * 0.59,
      height * 0.73,
    );

    verticalPath.lineTo(
      width * 0.78,
      height * 0.73,
    );

    verticalPath.quadraticBezierTo(
      width * 0.88,
      height * 0.73,
      width * 0.91,
      height * 0.81,
    );

    verticalPath.quadraticBezierTo(
      width * 0.94,
      height * 0.90,
      width * 0.83,
      height * 0.91,
    );

    verticalPath.lineTo(
      width * 0.48,
      height * 0.91,
    );

    verticalPath.quadraticBezierTo(
      width * 0.30,
      height * 0.91,
      width * 0.30,
      height * 0.72,
    );

    verticalPath.lineTo(
      width * 0.30,
      height * 0.18,
    );

    verticalPath.quadraticBezierTo(
      width * 0.30,
      height * 0.13,
      width * 0.35,
      height * 0.12,
    );

    verticalPath.close();

    canvas.drawPath(verticalPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}