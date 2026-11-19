import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/attendance_model.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_flow_widgets.dart';

/// Shown only after the backend confirmed the check-in / check-out.
class AttendanceSuccessScreen extends StatefulWidget {
  const AttendanceSuccessScreen({super.key});

  @override
  State<AttendanceSuccessScreen> createState() =>
      _AttendanceSuccessScreenState();
}

class _AttendanceSuccessScreenState extends State<AttendanceSuccessScreen>
    with TickerProviderStateMixin {
  final AttendanceController controller = Get.find<AttendanceController>();

  late final AnimationController _intro;
  late final AnimationController _pulse;
  late final AnimationController _confetti;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    _confetti = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));

    final rnd = math.Random(7);
    const palette = [
      AppColors.success,
      Color(0xFFFFC107),
      Color(0xFF42A5F5),
      Color(0xFFEC407A),
      Color(0xFF7E57C2),
      Color(0xFFFF7043),
    ];
    _particles = List.generate(80, (_) {
      return _Particle(
        angle: -math.pi / 2 + (rnd.nextDouble() - 0.5) * math.pi * 1.5,
        speed: 0.35 + rnd.nextDouble() * 0.75,
        size: 6 + rnd.nextDouble() * 7,
        spin: (rnd.nextDouble() - 0.5) * 14,
        color: palette[rnd.nextInt(palette.length)],
        isCircle: rnd.nextBool(),
        delay: rnd.nextDouble() * 0.12,
      );
    });

    // Small delay so the screen is on-screen before the celebration starts.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      HapticFeedback.heavyImpact();
      _intro.forward();
      _confetti.forward();
      _pulse.repeat();
      await Future.delayed(const Duration(milliseconds: 350));
      HapticFeedback.mediumImpact();
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    _confetti.dispose();
    super.dispose();
  }

  /// Staggered fade + slide-up reveal driven by the intro controller.
  Widget _reveal(double start, double end, Widget child) {
    final anim = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - anim.value)),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = controller.result.value;
    final isCheckIn =
        (result?.action ?? controller.action.value) == AttendanceAction.checkIn;
    final checkIn = result?.checkInAt;
    final checkOut = result?.checkOutAt;
    final worked =
        (checkIn != null && checkOut != null) ? checkOut.difference(checkIn) : null;
    final distance = result?.distanceMeters;

    return Scaffold(
      body: Stack(children: [
        // Soft green glow at the top
        Positioned(
          top: -120,
          left: -60,
          right: -60,
          child: Container(
            height: 380,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AppColors.success.withOpacity(0.16),
                AppColors.success.withOpacity(0.0),
              ]),
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding, 16, AppDimensions.pagePadding, 20),
            child: Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(children: [
                    const SizedBox(height: 28),

                    // ── Badge: ripples + pop + drawn check ────────────────
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(alignment: Alignment.center, children: [
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (_, __) => CustomPaint(
                            size: const Size(220, 220),
                            painter: _RipplePainter(
                                progress: _pulse.value,
                                color: AppColors.success),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _intro,
                          builder: (_, __) {
                            final pop = Curves.elasticOut.transform(
                                const Interval(0.0, 0.35).transform(_intro.value));
                            final draw = Curves.easeOutCubic.transform(
                                const Interval(0.18, 0.5).transform(_intro.value));
                            return Transform.scale(
                              scale: pop,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.success,
                                      AppColors.success.withOpacity(0.78),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.success.withOpacity(0.4),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  painter: _CheckPainter(progress: draw),
                                ),
                              ),
                            );
                          },
                        ),
                      ]),
                    ),
                    const SizedBox(height: 8),

                    // ── Title + subtitle ──────────────────────────────────
                    _reveal(
                      0.30,
                      0.60,
                      Column(children: [
                        Text(isCheckIn ? 'Checked in' : 'Checked out',
                            style: AppTextStyles.headline,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        // Text(
                        //   isCheckIn
                        //       ? 'Your attendance has been recorded. Have a productive day!'
                        //       : 'Your day is complete. See you tomorrow!',
                        //   style: AppTextStyles.bodySmall,
                        //   textAlign: TextAlign.center,
                        // ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ── Check-in / Check-out tiles ────────────────────────
                    _reveal(
                      0.40,
                      0.70,
                      Row(children: [
                        Expanded(
                          child: _TimeTile(
                            icon: Icons.login_rounded,
                            label: 'Check in',
                            value: Formatters.time12(checkIn),
                            active: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeTile(
                            icon: Icons.logout_rounded,
                            label: 'Check out',
                            value: isCheckIn
                                ? '--:--'
                                : Formatters.time12(checkOut),
                            active: !isCheckIn,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ── Details card (colorful rows) ──────────────────────
                    _reveal(
                      0.55,
                      0.90,
                      FlowCard(
                        child: Column(children: [
                          _ColorInfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: Formatters.dayLabel(
                                checkIn ?? DateTime.now()),
                            color: AppColors.primaryBlue,
                          ),
                          _ColorInfoRow(
                            icon: Icons.login_rounded,
                            label: 'Check in',
                            value: Formatters.time12(checkIn),
                            color: AppColors.success,
                          ),
                          if (!isCheckIn)
                            _ColorInfoRow(
                              icon: Icons.logout_rounded,
                              label: 'Check out',
                              value: Formatters.time12(checkOut),
                              color: AppColors.warning,
                            ),
                          if (worked != null)
                            _ColorInfoRow(
                              icon: Icons.timer_outlined,
                              label: 'Total hours',
                              value: Formatters.durationShort(worked),
                              color: AppColors.secondary,
                            ),
                          if (distance != null)
                            _ColorInfoRow(
                              icon: Icons.verified_rounded,
                              label: 'Distance from branch',
                              value: Formatters.distance(distance),
                              color: AppColors.accent,
                            ),
                        ]),
                      ),
                    ),

                    // ── Location verified ─────────────────────────────────
                    if (distance != null) ...[
                      const SizedBox(height: 14),
                      // _reveal(
                      //   0.70,
                      //   0.98,
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                            // const Icon(Icons.location_on_rounded,
                            //     size: 16, color: AppColors.success),
                            // const SizedBox(width: 6),
                            // Flexible(
                            //   child: Text(
                            //     'Location verified • ${Formatters.distance(distance)} from branch',
                            //     style: AppTextStyles.bodySmall.copyWith(
                            //         color: AppColors.success,
                            //         fontWeight: FontWeight.w600),
                            //   ),
                            // ),
                        //   ],
                        // ),
                      // ),
                    ],
                    const SizedBox(height: 12),
                  ]),
                ),
              ),
              const SizedBox(height: 14),
              _reveal(
                0.75,
                1.0,
                AppButton(
                  label: 'Done',
                  // icon: Icons.home_rounded,
                  useGradient: true,
                  onPressed: Get.back,
                ),
              ),
            ]),
          ),
        ),

        // ── Confetti burst (on top, ignores touches) ────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _confetti,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _confetti.value,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Info row with a colorful rounded icon chip.
class _ColorInfoRow extends StatelessWidget {
  const _ColorInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
     
     
     
      child: Row(
  children: [
    Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    ),
    const SizedBox(width: 14),
    Expanded(
      child: Text(
        label,
        style: AppTextStyles.bodySmall,
      ),
    ),
    const SizedBox(width: 12),
    Text(
      value,
      textAlign: TextAlign.right,
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    ),
  ],
),
    );







  }
}

/// Check-in / check-out time tile.
class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.active,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: active
            ? AppColors.successBackground.withOpacity(0.6)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.success.withOpacity(0.35) : Colors.transparent,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text(value,
            style: AppTextStyles.headline.copyWith(fontSize: 20),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ─────────────────────────── Painters ───────────────────────────

/// Draws the check mark stroke progressively (0 → 1).
class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.28, h * 0.52)
      ..lineTo(w * 0.44, h * 0.67)
      ..lineTo(w * 0.73, h * 0.36);

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckPainter old) => old.progress != progress;
}

/// Expanding, fading rings behind the badge.
class _RipplePainter extends CustomPainter {
  _RipplePainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const rings = 3;
    for (int i = 0; i < rings; i++) {
      final t = (progress + i / rings) % 1.0;
      final radius = 59 + (size.width / 2 - 59) * t;
      final paint = Paint()
        ..color = color.withOpacity((1 - t) * 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter old) => old.progress != progress;
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.spin,
    required this.color,
    required this.isCircle,
    required this.delay,
  });

  final double angle;
  final double speed;
  final double size;
  final double spin;
  final Color color;
  final bool isCircle;
  final double delay;
}

/// Confetti bursting upward from behind the badge, then falling with gravity.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});
  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.22);

    for (final p in particles) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final dx = math.cos(p.angle) * p.speed * size.width * 0.75 * t;
      final dy = math.sin(p.angle) * p.speed * size.height * 0.5 * t +
          size.height * 0.85 * t * t; // gravity
      final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0);

      final paint = Paint()..color = p.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * t);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: p.size, height: p.size * 0.55),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}