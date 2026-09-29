import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';

class CheckInSuccessScreen extends StatefulWidget {
  const CheckInSuccessScreen({super.key});

  @override
  State<CheckInSuccessScreen> createState() =>
      _CheckInSuccessScreenState();
}

class _CheckInSuccessScreenState extends State<CheckInSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _successController;

  final Random _random = Random();

  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();

    // =============================================================
    // CONFETTI ANIMATION
    // =============================================================

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    // =============================================================
    // SUCCESS ICON ANIMATION
    // =============================================================

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    // =============================================================
    // CREATE CONFETTI PARTICLES
    // =============================================================

    _particles = List.generate(
      55,
      (index) => _ConfettiParticle(
        x: _random.nextDouble(),
        delay: _random.nextDouble() * 0.35,
        size: 4 + _random.nextDouble() * 5,
        rotation: _random.nextDouble() * pi * 2,
        rotationSpeed:
            (_random.nextDouble() - 0.5) * 8,
        horizontalMovement:
            (_random.nextDouble() - 0.5) * 0.35,
        speed:
            0.65 + _random.nextDouble() * 0.5,
        shape: index % 3,
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),
      body: SafeArea(
        child: Stack(
          children: [
            // =======================================================
            // BACKGROUND GLOW
            // =======================================================

            Positioned(
              top: -150,
              right: -130,
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

            // =======================================================
            // MAIN CONTENT
            // =======================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                22,
                24,
                22,
                30,
              ),
              child: Column(
                children: [
                  // ===================================================
                  // TOP BAR
                  // ===================================================

                  Row(
                    children: [
                      _backButton(),
                      const Spacer(),
                      _secureBadge(),
                    ],
                  ),

                  const SizedBox(height: 55),

                  // ===================================================
                  // SUCCESS ICON
                  // ===================================================

                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _successController,
                      curve: Curves.elasticOut,
                    ),
                    child: _successIcon(),
                  ),

                  const SizedBox(height: 28),

                  // ===================================================
                  // TITLE
                  // ===================================================

                  Text(
                    'CHECK-IN',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 6),

                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFF24E5C0),
                          Color(0xFF20DFFF),
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'SUCCESSFUL',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Your attendance has been successfully recorded.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF7F96AB),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ===================================================
                  // EMPLOYEE CARD
                  // ===================================================

                  _employeeCard(),

                  const SizedBox(height: 14),

                  // ===================================================
                  // ATTENDANCE DETAILS
                  // ===================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xCC071A2D),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF16435F),
                      ),
                    ),
                    child: Column(
                      children: [
                        _detailRow(
                          icon: Icons.access_time_rounded,
                          title: 'Check-In Time',
                          value:
                              TimeOfDay.now().format(context),
                          iconColor:
                              const Color(0xFF29DFF7),
                        ),

                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          child: Divider(
                            color: Color(0xFF16384F),
                            height: 1,
                          ),
                        ),

                        _detailRow(
                          icon:
                              Icons.location_on_outlined,
                          title: 'Location',
                          value: 'Verified',
                          iconColor:
                              const Color(0xFF24E5C0),
                          showCheck: true,
                        ),

                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          child: Divider(
                            color: Color(0xFF16384F),
                            height: 1,
                          ),
                        ),

                        _detailRow(
                          icon: Icons.face_outlined,
                          title: 'Face Verification',
                          value: 'Verified',
                          iconColor:
                              const Color(0xFF24E5C0),
                          showCheck: true,
                        ),

                        const Padding(
                          padding:
                              EdgeInsets.symmetric(
                            vertical: 13,
                          ),
                          child: Divider(
                            color: Color(0xFF16384F),
                            height: 1,
                          ),
                        ),

                        _detailRow(
                          icon: Icons.straighten_rounded,
                          title: 'Distance',
                          value: 'Within Office Range',
                          iconColor:
                              const Color(0xFF24E5C0),
                          showCheck: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ===================================================
                  // STATUS BADGE
                  // ===================================================

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A302D),
                      borderRadius:
                          BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF1A665A),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF24E5C0),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ATTENDANCE MARKED',
                          style: GoogleFonts.poppins(
                            color:
                                const Color(0xFF24E5C0),
                            fontSize: 9,
                            fontWeight:
                                FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ===================================================
                  // DONE BUTTON
                  // ===================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(0xFF0FAF91),
                            Color(0xFF24E5C0),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF24E5C0)
                                    .withOpacity(0.22),
                            blurRadius: 22,
                            offset:
                                const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Get.offAllNamed(
                            AppRoutes.home,
                          );
                        },
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent,
                          foregroundColor:
                              Colors.white,
                          shadowColor:
                              Colors.transparent,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.home_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Back to Home',
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

                  const SizedBox(height: 24),

                  // ===================================================
                  // SECURITY
                  // ===================================================

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
                        'Attendance securely recorded',
                        style: GoogleFonts.poppins(
                          color:
                              const Color(0xFF536D83),
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ===================================================
                  // POWERED BY
                  // ===================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 1.5,
                        decoration:
                            const BoxDecoration(
                          gradient:
                              LinearGradient(
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
                          color:
                              const Color(0xFF536D83),
                          fontSize: 8,
                          fontWeight:
                              FontWeight.w600,
                          letterSpacing: 2.1,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Container(
                        width: 28,
                        height: 1.5,
                        decoration:
                            const BoxDecoration(
                          gradient:
                              LinearGradient(
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

            // =========================================================
            // CONFETTI — TOP LAYER
            // =========================================================

            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ConfettiPainter(
                        progress:
                            _confettiController.value,
                        particles: _particles,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // SUCCESS ICON
  // ===============================================================

  Widget _successIcon() {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF092F2B),
        border: Border.all(
          color: const Color(0xFF24E5C0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF24E5C0)
                    .withOpacity(0.18),
            blurRadius: 35,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0C453D),
          border: Border.all(
            color:
                const Color(0xFF24E5C0)
                    .withOpacity(0.4),
          ),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Color(0xFF24E5C0),
          size: 48,
        ),
      ),
    );
  }

  // ===============================================================
  // EMPLOYEE CARD
  // ===============================================================

  Widget _employeeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF081D31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF16435F),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A3047),
              border: Border.all(
                color: const Color(0xFF20DFFF),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF29DFF7),
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee Name',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Employee ID: EMP001',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF718CA1),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF24E5C0),
            size: 21,
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // DETAIL ROW
  // ===============================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    bool showCheck = false,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0A2941),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF9CB0C0),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: showCheck
                    ? const Color(0xFF24E5C0)
                    : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (showCheck) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF24E5C0),
                size: 16,
              ),
            ],
          ],
        ),
      ],
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
        borderRadius:
            BorderRadius.circular(14),
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
  // SECURE BADGE
  // ===============================================================

  Widget _secureBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2136),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1D4564),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                const BoxDecoration(
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
// CONFETTI PARTICLE
// ===================================================================

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.delay,
    required this.size,
    required this.rotation,
    required this.rotationSpeed,
    required this.horizontalMovement,
    required this.speed,
    required this.shape,
  });

  final double x;
  final double delay;
  final double size;
  final double rotation;
  final double rotationSpeed;
  final double horizontalMovement;
  final double speed;
  final int shape;
}

// ===================================================================
// CONFETTI PAINTER
// ===================================================================

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_ConfettiParticle> particles;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    for (final particle in particles) {
      final adjustedProgress =
          ((progress - particle.delay) /
                  (1 - particle.delay))
              .clamp(0.0, 1.0);

      if (adjustedProgress <= 0 ||
          adjustedProgress >= 1) {
        continue;
      }

      // -------------------------------------------------------------
      // FALLING POSITION
      // -------------------------------------------------------------

      final y = -30 +
          (size.height * 0.82) *
              pow(adjustedProgress, 0.9);

      final wave = sin(
            adjustedProgress * pi * 3 +
                particle.x * 8,
          ) *
          particle.horizontalMovement *
          size.width;

      final x =
          particle.x * size.width + wave;

      // -------------------------------------------------------------
      // FADE OUT NEAR END
      // -------------------------------------------------------------

      double opacity = 1.0;

      if (adjustedProgress > 0.75) {
        opacity =
            1 -
                ((adjustedProgress - 0.75) /
                    0.25);
      }

      // -------------------------------------------------------------
      // ROTATION
      // -------------------------------------------------------------

      final rotation =
          particle.rotation +
              particle.rotationSpeed *
                  adjustedProgress;

      // -------------------------------------------------------------
      // COLORS
      // -------------------------------------------------------------

      final colors = [
        const Color(0xFF24E5C0),
        const Color(0xFF20DFFF),
        const Color(0xFF287EFF),
        const Color(0xFFFFFFFF),
        const Color(0xFF0FAF91),
      ];

      final paint = Paint()
        ..color = colors[
                (particle.x * colors.length)
                    .floor()
                    .clamp(
                      0,
                      colors.length - 1,
                    )
              ]
            .withOpacity(opacity);

      // -------------------------------------------------------------
      // DRAW
      // -------------------------------------------------------------

      canvas.save();

      canvas.translate(x, y);

      canvas.rotate(rotation);

      final width = particle.size * 1.7;
      final height = particle.size;

      if (particle.shape == 0) {
        // RECTANGLE
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: width,
              height: height,
            ),
            const Radius.circular(1),
          ),
          paint,
        );
      } else if (particle.shape == 1) {
        // CIRCLE
        canvas.drawCircle(
          Offset.zero,
          particle.size / 2,
          paint,
        );
      } else {
        // DIAMOND
        final path = Path()
          ..moveTo(
            0,
            -particle.size,
          )
          ..lineTo(
            particle.size,
            0,
          )
          ..lineTo(
            0,
            particle.size,
          )
          ..lineTo(
            -particle.size,
            0,
          )
          ..close();

        canvas.drawPath(
          path,
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(
    covariant _ConfettiPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}