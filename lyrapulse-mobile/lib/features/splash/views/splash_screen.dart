import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _waveController;
  late AnimationController _pulseController;
  late AnimationController _loaderController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    // ============================================================
    // MAIN ENTRANCE ANIMATION
    // ============================================================

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutBack,
    );

    _logoOpacity = CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    );

    _textOpacity = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(
        0.28,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _contentSlide = Tween<double>(
      begin: 22,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeOutCubic,
      ),
    );

    // ============================================================
    // WAVES
    // ============================================================

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // ============================================================
    // LOGO BREATHING / GLOW
    // ============================================================

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // ============================================================
    // LOADING BARS
    // ============================================================

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    // ============================================================
    // PARTICLES
    // ============================================================

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Start entrance
    _mainController.forward();

    // ============================================================
    // GO TO LOGIN
    // ============================================================

    Timer(
      const Duration(seconds: 4),
      () {
        if (!mounted) return;

        Get.offNamed(AppRoutes.login);
      },
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    _loaderController.dispose();
    _particleController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final bool isSmallPhone = size.height < 700;
    final bool isTablet = size.shortestSide >= 600;

    final double logoSize = isTablet
        ? 125
        : isSmallPhone
            ? 92
            : 108;

    final double titleSize = isTablet
        ? 34
        : isSmallPhone
            ? 27
            : 30;

    final double taglineSize = isTablet
        ? 15
        : isSmallPhone
            ? 10.5
            : 12;

    return Scaffold(
      backgroundColor: const Color(0xFF020A22),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // ==========================================================
          // BACKGROUND
          // ==========================================================

          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF071A43),
                    Color(0xFF061535),
                    Color(0xFF020A22),
                    Color(0xFF02081C),
                  ],
                  stops: [
                    0.0,
                    0.38,
                    0.72,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // ==========================================================
          // TOP LEFT AMBIENT GLOW
          // ==========================================================

          Positioned(
            top: -150,
            left: -120,
            child: _ambientGlow(
              size: isTablet ? 430 : 330,
              color: const Color(0xFF006EFF),
              opacity: 0.20,
            ),
          ),

          // ==========================================================
          // TOP RIGHT BLUE GLOW
          // ==========================================================

          Positioned(
            top: -90,
            right: -150,
            child: _ambientGlow(
              size: isTablet ? 380 : 300,
              color: const Color(0xFF174BFF),
              opacity: 0.13,
            ),
          ),

          // ==========================================================
          // CENTER BLUE AMBIENT LIGHT
          // ==========================================================

          Positioned(
            top: size.height * 0.28,
            left: size.width * 0.15,
            right: size.width * 0.15,
            child: IgnorePointer(
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF156FFF).withOpacity(0.13),
                      const Color(0xFF087DFF).withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==========================================================
          // PARTICLES
          // ==========================================================

          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  progress: _particleController.value,
                ),
              );
            },
          ),

          // ==========================================================
          // BOTTOM WAVES
          // ==========================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: isTablet
                ? 390
                : isSmallPhone
                    ? 270
                    : 330,
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PremiumWavePainter(
                    progress: _waveController.value,
                  ),
                );
              },
            ),
          ),

          // ==========================================================
          // MAIN CENTER CONTENT
          // ==========================================================

          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      _contentSlide.value,
                    ),
                    child: child,
                  );
                },

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // LOGO AREA
                    // ==================================================

                    FadeTransition(
                      opacity: _logoOpacity,

                      child: AnimatedBuilder(
                        animation: _pulseController,

                        builder: (context, child) {
                          final double pulse =
                              1.0 + (_pulseController.value * 0.025);

                          return Transform.scale(
                            scale: pulse,
                            child: child,
                          );
                        },

                        child: SizedBox(
                          width: logoSize + 60,
                          height: logoSize + 60,

                          child: Stack(
                            alignment: Alignment.center,

                            children: [
                              // ----------------------------------------
                              // LOGO GLOW
                              // ----------------------------------------

                              AnimatedBuilder(
                                animation: _pulseController,

                                builder: (context, child) {
                                  final double opacity =
                                      0.16 +
                                      (_pulseController.value * 0.10);

                                  return Container(
                                    width: logoSize * 1.05,
                                    height: logoSize * 1.05,

                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,

                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF008CFF)
                                              .withOpacity(opacity),
                                          blurRadius: 45,
                                          spreadRadius: 12,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              // ----------------------------------------
                              // CIRCULAR LIGHT ARC
                              // ----------------------------------------

                              AnimatedBuilder(
                                animation: _waveController,

                                builder: (context, child) {
                                  return CustomPaint(
                                    size: Size(
                                      logoSize + 25,
                                      logoSize + 25,
                                    ),

                                    painter: _LogoArcPainter(
                                      progress: _waveController.value,
                                    ),
                                  );
                                },
                              ),

                              // ----------------------------------------
                              // L LOGO
                              // ----------------------------------------

                              SizedBox(
                                width: logoSize,
                                height: logoSize,

                                child: const CustomPaint(
                                  painter: _LyraLogoPainter(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // LYRA PULSE
                    // ==================================================

                    FadeTransition(
                      opacity: _textOpacity,

                      child: Text(
                        'Lyra Pulse',
                        textAlign: TextAlign.center,

                        style: GoogleFonts.poppins(
                          color: const Color(0xFFF7FAFF),
                          fontSize: titleSize,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.05,

                          shadows: [
                            Shadow(
                              color: const Color(0xFF2D79FF)
                                  .withOpacity(0.30),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==================================================
                    // TAGLINE
                    // ==================================================

                    FadeTransition(
                      opacity: _textOpacity,

                      child: Text(
                        'WORK BETTER TOGETHER',
                        textAlign: TextAlign.center,

                        style: GoogleFonts.poppins(
                          color: const Color(0xFFB9D3F7),
                          fontSize: taglineSize,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // LOADING BARS
                    // ==================================================

                    FadeTransition(
                      opacity: _textOpacity,

                      child: AnimatedBuilder(
                        animation: _loaderController,

                        builder: (context, child) {
                          return SizedBox(
                            height: 28,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.center,

                              children: List.generate(
                                5,
                                (index) {
                                  final double wave =
                                      math.sin(
                                    (_loaderController.value *
                                            math.pi *
                                            2) +
                                        (index * 0.8),
                                  );

                                  final double barHeight =
                                      9 + ((wave + 1) * 7);

                                  final double opacity =
                                      0.30 + ((wave + 1) * 0.25);

                                  return Container(
                                    width: 5,
                                    height: barHeight,

                                    margin:
                                        const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),

                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(8),

                                      gradient:
                                          const LinearGradient(
                                        begin:
                                            Alignment.topCenter,
                                        end:
                                            Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF69B7FF),
                                          Color(0xFF087DFF),
                                        ],
                                      ),

                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              const Color(0xFF159CFF)
                                                  .withOpacity(
                                            opacity * 0.55,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // AMBIENT GLOW
  // ==============================================================

  Widget _ambientGlow({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(opacity * 0.35),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// LYRA L LOGO
// ==================================================================

class _LyraLogoPainter extends CustomPainter {
  const _LyraLogoPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final double w = size.width;
    final double h = size.height;

    final Path path = Path();

    // ==============================================================
    // TOP VERTICAL
    // ==============================================================

    path.moveTo(
      w * 0.38,
      h * 0.10,
    );

    path.cubicTo(
      w * 0.38,
      h * 0.04,
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

    path.lineTo(
      w * 0.62,
      h * 0.58,
    );

    // ==============================================================
    // INNER CURVE
    // ==============================================================

    path.cubicTo(
      w * 0.62,
      h * 0.63,
      w * 0.65,
      h * 0.65,
      w * 0.70,
      h * 0.65,
    );

    // ==============================================================
    // HORIZONTAL ARM
    // ==============================================================

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

    // ==============================================================
    // BOTTOM CURVE
    // ==============================================================

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
      h * 0.10,
    );

    path.close();

    // ==============================================================
    // LOGO GLOW
    // ==============================================================

    final Paint glowPaint = Paint()
      ..isAntiAlias = true
      ..color = const Color(0xFF008CFF).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        13,
      );

    canvas.drawPath(
      path,
      glowPaint,
    );

    // ==============================================================
    // LOGO GRADIENT
    // ==============================================================

    final Paint logoPaint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF6D72FF),
          Color(0xFF328CFF),
          Color(0xFF087DFF),
          Color(0xFF00BFFF),
        ],
        stops: [
          0.0,
          0.35,
          0.72,
          1.0,
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
      path,
      logoPaint,
    );

    // ==============================================================
    // SMALL INNER HIGHLIGHT
    // ==============================================================

    final Paint highlightPaint = Paint()
      ..isAntiAlias = true
      ..color = Colors.white.withOpacity(0.12);

    final Path highlightPath = Path();

    highlightPath.moveTo(
      w * 0.45,
      h * 0.05,
    );

    highlightPath.cubicTo(
      w * 0.41,
      h * 0.08,
      w * 0.41,
      h * 0.14,
      w * 0.41,
      h * 0.20,
    );

    highlightPath.lineTo(
      w * 0.41,
      h * 0.54,
    );

    highlightPath.cubicTo(
      w * 0.41,
      h * 0.58,
      w * 0.43,
      h * 0.60,
      w * 0.46,
      h * 0.60,
    );

    highlightPath.lineTo(
      w * 0.46,
      h * 0.05,
    );

    highlightPath.close();

    canvas.drawPath(
      highlightPath,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _LyraLogoPainter oldDelegate,
  ) {
    return false;
  }
}

// ==================================================================
// LOGO ARC
// ==================================================================

class _LogoArcPainter extends CustomPainter {
  final double progress;

  _LogoArcPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Rect rect = Offset.zero & size;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: progress * math.pi * 2,
        endAngle: progress * math.pi * 2 + math.pi * 1.5,
        colors: [
          Colors.transparent,
          const Color(0xFF197BFF).withOpacity(0.15),
          const Color(0xFF00D9FF).withOpacity(0.80),
          Colors.transparent,
        ],
        stops: const [
          0.0,
          0.45,
          0.72,
          1.0,
        ],
      ).createShader(rect);

    canvas.drawArc(
      rect.deflate(3),
      progress * math.pi * 2,
      math.pi * 1.35,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _LogoArcPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

// ==================================================================
// PARTICLE PAINTER
// ==================================================================

class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final List<_Particle> particles = [
      _Particle(
        x: 0.14,
        y: 0.28,
        radius: 1.3,
        speed: 0.8,
        color: const Color(0xFF159CFF),
      ),
      _Particle(
        x: 0.82,
        y: 0.34,
        radius: 1.1,
        speed: 0.6,
        color: const Color(0xFF6B5CFF),
      ),
      _Particle(
        x: 0.20,
        y: 0.47,
        radius: 0.9,
        speed: 0.7,
        color: const Color(0xFF00CFFF),
      ),
      _Particle(
        x: 0.76,
        y: 0.53,
        radius: 1.4,
        speed: 0.5,
        color: const Color(0xFF4E72FF),
      ),
      _Particle(
        x: 0.34,
        y: 0.62,
        radius: 0.8,
        speed: 0.9,
        color: const Color(0xFF8C6BFF),
      ),
      _Particle(
        x: 0.90,
        y: 0.66,
        radius: 0.9,
        speed: 0.75,
        color: const Color(0xFF00BFFF),
      ),
    ];

    for (final particle in particles) {
      final double movement =
          math.sin(
                (progress * math.pi * 2 * particle.speed) +
                    particle.x * 4,
              ) *
              5;

      final Offset position = Offset(
        size.width * particle.x,
        size.height * particle.y + movement,
      );

      final double opacity =
          0.20 +
          ((math.sin(
                    progress * math.pi * 2 +
                        particle.y * 5,
                  ) +
                  1) /
              2) *
              0.45;

      final Paint paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          3,
        );

      canvas.drawCircle(
        position,
        particle.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _ParticlePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}

class _Particle {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final Color color;

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.color,
  });
}

// ==================================================================
// PREMIUM WAVE PAINTER
// ==================================================================

class _PremiumWavePainter extends CustomPainter {
  final double progress;

  _PremiumWavePainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final double width = size.width;
    final double height = size.height;

    // ==============================================================
    // WAVE 1 - BLUE
    // ==============================================================

    _drawFilledWave(
      canvas: canvas,
      size: size,
      progress: progress,
      baseY: height * 0.52,
      amplitude: 24,
      frequency: 1.25,
      phase: 0,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x50105CFF),
          Color(0x30116EFF),
          Color(0x00105CFF),
        ],
      ),
    );

    // ==============================================================
    // WAVE 2 - CYAN
    // ==============================================================

    _drawFilledWave(
      canvas: canvas,
      size: size,
      progress: progress,
      baseY: height * 0.64,
      amplitude: 30,
      frequency: 1.5,
      phase: 1.5,
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x45136EFF),
          Color(0x2513A4FF),
          Color(0x000B4EFF),
        ],
      ),
    );

    // ==============================================================
    // WAVE 3 - PURPLE
    // ==============================================================

    _drawFilledWave(
      canvas: canvas,
      size: size,
      progress: progress,
      baseY: height * 0.76,
      amplitude: 28,
      frequency: 1.35,
      phase: 3.0,
      gradient: const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0x605D28E8),
          Color(0x383E2DB8),
          Color(0x00131C62),
        ],
      ),
    );

    // ==============================================================
    // NEON CONTOUR LINES
    // ==============================================================

    _drawContourLine(
      canvas: canvas,
      size: size,
      progress: progress,
      baseY: height * 0.55,
      amplitude: 17,
      frequency: 1.2,
      phase: 0.4,
      color: const Color(0xFF087DFF),
      opacity: 0.65,
      strokeWidth: 1.2,
    );

    _drawContourLine(
      canvas: canvas,
      size: size,
      progress: progress,
      baseY: height * 0.68,
      amplitude: 19,
      frequency: 1.5,
      phase: 2.0,
      color: const Color(0xFF00CFFF),
      opacity: 0.45,
      strokeWidth: 1.0,
    );

    _drawContourLine(
      canvas: canvas,
      size: size,
      progress: progress,
      baseY: height * 0.79,
      amplitude: 20,
      frequency: 1.4,
      phase: 3.2,
      color: const Color(0xFF8062FF),
      opacity: 0.55,
      strokeWidth: 1.1,
    );

    // ==============================================================
    // THIN SUBTLE LINES
    // ==============================================================

    for (int i = 0; i < 7; i++) {
      final Path path = Path();

      final double baseY =
          height * 0.54 + i * 12;

      path.moveTo(
        0,
        baseY,
      );

      for (
        double x = 0;
        x <= width;
        x += 5
      ) {
        final double n = x / width;

        final double y =
            baseY +
            math.sin(
                  n * math.pi * 2 +
                      progress * math.pi * 2 +
                      i * 0.25,
                ) *
                9;

        path.lineTo(
          x,
          y,
        );
      }

      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45
        ..color = Colors.white.withOpacity(0.055);

      canvas.drawPath(
        path,
        paint,
      );
    }
  }

  // ================================================================
  // FILLED WAVE
  // ================================================================

  void _drawFilledWave({
    required Canvas canvas,
    required Size size,
    required double progress,
    required double baseY,
    required double amplitude,
    required double frequency,
    required double phase,
    required Gradient gradient,
  }) {
    final double width = size.width;
    final double height = size.height;

    final Path path = Path();

    path.moveTo(
      0,
      baseY,
    );

    for (
      double x = 0;
      x <= width;
      x += 4
    ) {
      final double n = x / width;

      final double y =
          baseY +
          math.sin(
                n * math.pi * 2 * frequency +
                    progress * math.pi * 2 +
                    phase,
              ) *
              amplitude;

      path.lineTo(
        x,
        y,
      );
    }

    path.lineTo(
      width,
      height,
    );

    path.lineTo(
      0,
      height,
    );

    path.close();

    final Paint paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(
          0,
          0,
          width,
          height,
        ),
      );

    canvas.drawPath(
      path,
      paint,
    );
  }

  // ================================================================
  // CONTOUR LINE
  // ================================================================

  void _drawContourLine({
    required Canvas canvas,
    required Size size,
    required double progress,
    required double baseY,
    required double amplitude,
    required double frequency,
    required double phase,
    required Color color,
    required double opacity,
    required double strokeWidth,
  }) {
    final double width = size.width;

    final Path path = Path();

    path.moveTo(
      0,
      baseY,
    );

    for (
      double x = 0;
      x <= width;
      x += 4
    ) {
      final double n = x / width;

      final double y =
          baseY +
          math.sin(
                n * math.pi * 2 * frequency +
                    progress * math.pi * 2 +
                    phase,
              ) *
              amplitude;

      path.lineTo(
        x,
        y,
      );
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(opacity);

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PremiumWavePainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}