
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onFingerprintAction;
  final bool isCheckedIn;
  final bool isOnBreak;
  final bool isCompleted;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
    required this.onFingerprintAction,
    required this.isCheckedIn,
    required this.isOnBreak,
    required this.isCompleted,
  });

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  Timer? _holdTimer;
  Timer? _progressTimer;

  late final AnimationController _flashController;
  late final AnimationController _pulseController;

  double _holdProgress = 0;
  bool _isHolding = false;
  bool _isAuthenticating = false;
  bool _actionTriggered = false;

  Color _activeFlashColor = Colors.greenAccent;

  static const Duration _holdDuration = Duration(seconds: 3);

  Color get _flashColor {
    if (widget.isCompleted) {
      return Colors.grey;
    }

    // Returning from a break resumes office working time.
    if (widget.isOnBreak) {
      return Colors.greenAccent;
    }

    // Check In is green; break checkout and office checkout are red.
    return widget.isCheckedIn
        ? Colors.redAccent
        : Colors.greenAccent;
  }

  String get _fingerprintLabel {
    if (widget.isCompleted) {
      return 'Attendance Completed';
    }

    if (!widget.isCheckedIn) {
      return 'Hold to Check In';
    }

    if (widget.isOnBreak) {
      return 'Hold to Return';
    }

    final now = DateTime.now();
    final closingTime = DateTime(
      now.year,
      now.month,
      now.day,
      18,
      30,
    );

    if (now.isBefore(closingTime)) {
      return 'Hold to Start Break';
    }

    return 'Hold to Check Out';
  }

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isCheckedIn != widget.isCheckedIn ||
        oldWidget.isOnBreak != widget.isOnBreak ||
        oldWidget.isCompleted != widget.isCompleted) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    _flashController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startHold() {
    if (widget.isCompleted ||
        _isHolding ||
        _isAuthenticating ||
        _actionTriggered) {
      return;
    }

    _holdTimer?.cancel();
    _progressTimer?.cancel();

    _activeFlashColor = _flashColor;

    setState(() {
      _isHolding = true;
      _holdProgress = 0;
    });

    final startTime = DateTime.now();

    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 30),
      (timer) {
        if (!mounted || !_isHolding) {
          timer.cancel();
          return;
        }

        final elapsed = DateTime.now().difference(startTime);
        final progress = (elapsed.inMilliseconds /
                _holdDuration.inMilliseconds)
            .clamp(0.0, 1.0);

        setState(() {
          _holdProgress = progress;
        });

        if (progress >= 1.0) {
          timer.cancel();
        }
      },
    );

    _holdTimer = Timer(_holdDuration, () {
      if (!mounted || !_isHolding || _actionTriggered) {
        return;
      }

      setState(() {
        _holdProgress = 1;
        _isHolding = false;
        _isAuthenticating = true;
        _actionTriggered = true;
      });

      _flashController.forward(from: 0);
      _authenticateAndContinue();
    });
  }

  void _endHold() {
    if (_actionTriggered) return;

    _holdTimer?.cancel();
    _progressTimer?.cancel();

    if (!mounted) return;

    setState(() {
      _isHolding = false;
      _holdProgress = 0;
    });
  }

  Future<void> _authenticateAndContinue() async {
    if (!mounted) return;

    try {
      // No phone biometric prompt. Continue with the app's attendance flow.
      widget.onFingerprintAction();
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _actionTriggered = false;
          _isHolding = false;
          _holdProgress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.15),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 88,
          child: Row(
            children: [
              _buildNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.calendar_month_rounded,
                label: 'Calendar',
                index: 1,
              ),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -5),
                    child: _buildFingerprintButton(),
                  ),
                ),
              ),
              _buildNavItem(
                icon: Icons.history_rounded,
                label: 'History',
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = widget.selectedIndex == index;
    final color = isSelected
        ? const Color(0xFF635BFF)
        : Colors.grey.shade500;

    return Expanded(
      child: InkWell(
        onTap: () => widget.onChanged(index),
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 23, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFingerprintButton() {
    final buttonColor = widget.isCompleted
        ? Colors.grey
        : const Color(0xFF635BFF);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart:
          widget.isCompleted ? null : (_) => _startHold(),
      onLongPressEnd: (_) => _endHold(),
      onLongPressCancel: _endHold,
      child: SizedBox(
        width: 100,
        height: 82,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([
                _pulseController,
                _flashController,
              ]),
              builder: (context, child) {
                final pulse = _isHolding
                    ? 1 + (_pulseController.value * 0.04)
                    : 1.0;

                return Transform.scale(
                  scale: pulse,
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (_isHolding)
                          CustomPaint(
                            size: const Size(70, 70),
                            painter: _HoldProgressPainter(
                              progress: _holdProgress,
                              color: _activeFlashColor,
                            ),
                          ),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: buttonColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: buttonColor.withValues(
                                  alpha: 0.30,
                                ),
                                blurRadius: _isHolding ? 18 : 10,
                                spreadRadius: _isHolding ? 2 : 0,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            size: 35,
                            color: Colors.white,
                          ),
                        ),
                        if (_flashController.isAnimating)
                          CustomPaint(
                            size: const Size(70, 70),
                            painter: _ElectricFlashPainter(
                              progress: _flashController.value,
                              color: _activeFlashColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 1),
            Flexible(
              child: Text(
                _isAuthenticating
                    ? 'Please wait...'
                    : _isHolding
                        ? '${(_holdProgress * 3).toStringAsFixed(1)} sec'
                        : _fingerprintLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: buttonColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _HoldProgressPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _HoldProgressPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}

class _ElectricFlashPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ElectricFlashPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        3,
      );

    final sparkPaint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);
    const innerRadius = 22.0;
    final outerRadius = 28.0 + (progress * 8.0);

    for (int i = 0; i < 16; i++) {
      final angle = (2 * math.pi * i / 16) - math.pi / 2;
      final direction = i.isEven ? 1.0 : -1.0;

      final start = Offset(
        center.dx + math.cos(angle) * innerRadius,
        center.dy + math.sin(angle) * innerRadius,
      );

      final bendRadius =
          innerRadius + (outerRadius - innerRadius) * 0.5;

      final bend = Offset(
        center.dx +
            math.cos(angle + direction * 0.12) * bendRadius,
        center.dy +
            math.sin(angle + direction * 0.12) * bendRadius,
      );

      final end = Offset(
        center.dx + math.cos(angle) * outerRadius,
        center.dy + math.sin(angle) * outerRadius,
      );

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(bend.dx, bend.dy)
        ..lineTo(end.dx, end.dy);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, sparkPaint);

      if (i.isEven) {
        final branchStart = Offset(
          center.dx +
              math.cos(angle) * (bendRadius - 2),
          center.dy +
              math.sin(angle) * (bendRadius - 2),
        );

        final branchEnd = Offset(
          center.dx +
              math.cos(angle + direction * 0.35) *
                  (bendRadius + 5),
          center.dy +
              math.sin(angle + direction * 0.35) *
                  (bendRadius + 5),
        );

        final branch = Path()
          ..moveTo(branchStart.dx, branchStart.dy)
          ..lineTo(branchEnd.dx, branchEnd.dy);

        canvas.drawPath(branch, glowPaint);
        canvas.drawPath(branch, sparkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _ElectricFlashPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}
