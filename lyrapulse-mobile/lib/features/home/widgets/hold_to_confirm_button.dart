import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class HoldToConfirmButton extends StatefulWidget {
  final bool isCheckOut;
  final bool isEnabled;
  final VoidCallback onConfirm;

  const HoldToConfirmButton({
    super.key,
    required this.isCheckOut,
    this.isEnabled = true,
    required this.onConfirm,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with TickerProviderStateMixin {
  late final AnimationController _holdController;
  late final AnimationController _waveController;

  // Success beep (generated in code, no asset file needed).
  final AudioPlayer _player = AudioPlayer();
  late final Uint8List _beepBytes = _buildSuccessBeep();

  bool _isHolding = false;
  bool _isProcessing = false;
  int _lastHapticStep = 0;

  static const _holdDuration = Duration(seconds: 2);
  static const _waveDuration = Duration(milliseconds: 1300);

  Color get _buttonColor =>
      widget.isCheckOut ? AppColors.warning : AppColors.success;

  @override
  void initState() {
    super.initState();

    _holdController = AnimationController(
      vsync: this,
      duration: _holdDuration,
    );

    _waveController = AnimationController(
      vsync: this,
      duration: _waveDuration,
    );

    _holdController.addStatusListener(_handleHoldStatus);
    _holdController.addListener(_handleHoldTick);
  }

  // ───────────────────────── Beep sound ─────────────────────────

  /// Builds a tiny 16-bit mono WAV in memory: two rising tones (ding-ding).
  static Uint8List _buildSuccessBeep() {
    const sampleRate = 44100;
    // (frequency Hz, duration ms)
    const tones = [(880.0, 130), (1320.0, 260)];

    final samples = <int>[];
    for (final tone in tones) {
      final freq = tone.$1;
      final n = (sampleRate * tone.$2 / 1000).round();
      final attack = sampleRate * 0.008; // 8 ms fade-in (no click)
      final release = sampleRate * 0.12; // soft fade-out
      for (int i = 0; i < n; i++) {
        final env = math.min(1.0, i / attack) * math.min(1.0, (n - i) / release);
        final v = math.sin(2 * math.pi * freq * i / sampleRate) * env * 0.55;
        samples.add((v * 32767).round());
      }
    }

    final dataLen = samples.length * 2;
    final bytes = ByteData(44 + dataLen);

    void writeStr(int offset, String s) {
      for (int i = 0; i < s.length; i++) {
        bytes.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLen, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little); // PCM chunk size
    bytes.setUint16(20, 1, Endian.little); // PCM format
    bytes.setUint16(22, 1, Endian.little); // mono
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(28, sampleRate * 2, Endian.little); // byte rate
    bytes.setUint16(32, 2, Endian.little); // block align
    bytes.setUint16(34, 16, Endian.little); // bits per sample
    writeStr(36, 'data');
    bytes.setUint32(40, dataLen, Endian.little);

    for (int i = 0; i < samples.length; i++) {
      bytes.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return bytes.buffer.asUint8List();
  }

  Future<void> _playSuccessBeep() async {
    try {
      await _player.stop();
      await _player.play(BytesSource(_beepBytes), volume: 1.0);
    } catch (_) {
      // Sound is a bonus; never break the confirm flow because of it.
      SystemSound.play(SystemSoundType.click);
    }
  }

  // ───────────────────────── Hold logic ─────────────────────────

  /// Gentle haptic "ticks" at 25%, 50%, 75%.
  void _handleHoldTick() {
    if (!_isHolding) return;
    final step = (_holdController.value * 4).floor();
    if (step > _lastHapticStep && step < 4) {
      _lastHapticStep = step;
      HapticFeedback.mediumImpact();
    }
  }

  void _handleHoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_isHolding) {
      return;
    }

    // Ring complete -> BLAST (vibration + beep + visual burst).
    _isHolding = false;
    _isProcessing = true;
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 90), () {
      if (mounted && _isProcessing) HapticFeedback.heavyImpact();
    });
    _playSuccessBeep();

    setState(() {});

    _waveController.forward(from: 0).then((_) {
      if (!mounted) return;

      _isProcessing = false;
      _lastHapticStep = 0;
      _holdController.reset();
      _waveController.reset();

      setState(() {});

      // Navigate only after the blast finishes.
      widget.onConfirm();
    });
  }

  void _startHold() {
    if (!widget.isEnabled || _isHolding || _isProcessing) return;

    HapticFeedback.lightImpact();
    _lastHapticStep = 0;

    setState(() {
      _isHolding = true;
    });

    _waveController.stop();
    _waveController.reset();

    _holdController.forward(from: 0);
  }

  void _cancelHold() {
    if (!_isHolding) return;

    _isHolding = false;
    _lastHapticStep = 0;

    _holdController.stop();
    _holdController.reset();

    _waveController.stop();
    _waveController.reset();

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant HoldToConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if ((oldWidget.isCheckOut != widget.isCheckOut ||
            oldWidget.isEnabled != widget.isEnabled) &&
        _isHolding) {
      _cancelHold();
    }
  }

  @override
  void dispose() {
    _holdController.removeStatusListener(_handleHoldStatus);
    _holdController.removeListener(_handleHoldTick);
    _holdController.dispose();
    _waveController.dispose();
    _player.dispose();
    super.dispose();
  }

  /// Thin trailing pulse rings after the blast (single colour).
  Widget _buildPulseWave(double progress, int waveIndex, Color color) {
    // Starts a bit after the blast so they trail it.
    final waveProgress =
        ((progress - 0.12 - waveIndex * 0.14) / 0.6).clamp(0.0, 1.0);

    if (waveProgress <= 0 || waveProgress >= 1) {
      return const SizedBox.shrink();
    }

    final eased = Curves.easeOutCubic.transform(waveProgress);
    final size = 96 + (eased * 120);
    final opacity = (1 - eased) * 0.45;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: opacity),
          width: 2.0 - (eased * 1.0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _buttonColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.isEnabled ? (_) => _startHold() : null,
      onTapUp: widget.isEnabled ? (_) => _cancelHold() : null,
      onTapCancel: widget.isEnabled ? _cancelHold : null,
      child: SizedBox(
        width: 100,
        height: 100,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _holdController,
            _waveController,
          ]),
          builder: (context, child) {
            final waveProgress = _waveController.value;
            final holdValue = _holdController.value;
            final isWaveActive = _isProcessing;
            final showDone = isWaveActive;

            final activeColor = showDone ? AppColors.success : buttonColor;

            final glow =
                isWaveActive ? (1 - waveProgress).clamp(0.0, 1.0) : 0.0;

            final charge = _isHolding
                ? Curves.easeIn.transform(holdValue.clamp(0.0, 1.0))
                : 0.0;

            // Halo fades in quickly after press (~200 ms).
            final appear = _isHolding
                ? Curves.easeOut.transform((holdValue * 10).clamp(0.0, 1.0))
                : 0.0;

            // Hold: slow grow. Blast: quick punch up (1.06 -> 1.2) then settle.
            double scale = 1.0;
            if (_isHolding) {
              scale = 1.0 + 0.06 * Curves.easeOut.transform(holdValue);
            } else if (isWaveActive) {
              const punchAt = 0.12;
              if (waveProgress < punchAt) {
                final k = Curves.easeOut.transform(waveProgress / punchAt);
                scale = 1.06 + 0.14 * k;
              } else {
                final k = Curves.easeOutCubic
                    .transform((waveProgress - punchAt) / (1 - punchAt));
                scale = 1.2 - 0.2 * k;
              }
            }

            // Slightly lighter / darker shades of the same colour -> premium look.
            final hsl = HSLColor.fromColor(activeColor);
            final light = hsl
                .withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0))
                .toColor();
            final dark = hsl
                .withLightness((hsl.lightness - 0.06).clamp(0.0, 1.0))
                .toColor();

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Soft single-colour halo while holding
                if (_isHolding)
                  Container(
                    width: 120 + charge * 24,
                    height: 120 + charge * 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          buttonColor.withValues(alpha: 0.20 * appear),
                          buttonColor.withValues(alpha: 0.07 * appear),
                          buttonColor.withValues(alpha: 0),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),

                // ───── BLAST ─────
                if (isWaveActive) ...[
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: _BlastPainter(
                      t: waveProgress,
                      color: AppColors.success,
                    ),
                  ),
                  _buildPulseWave(waveProgress, 0, AppColors.success),
                  _buildPulseWave(waveProgress, 1, AppColors.success),
                ],

                Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Track ring
                      SizedBox(
                        width: 104,
                        height: 104,
                        child: CircularProgressIndicator(
                          value: isWaveActive ? 1 : 0,
                          strokeWidth: 4,
                          strokeCap: StrokeCap.round,
                          backgroundColor: buttonColor.withValues(alpha: 0.14),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.success),
                        ),
                      ),

                      // Progress ring while holding
                      if (_isHolding)
                        CustomPaint(
                          size: const Size(104, 104),
                          painter: _ProgressRingPainter(
                            progress: holdValue,
                            color: buttonColor,
                            strokeWidth: 4.5,
                          ),
                        ),

                      // Full ring glow flash right at blast
                      if (isWaveActive)
                        CustomPaint(
                          size: const Size(104, 104),
                          painter: _ProgressRingPainter(
                            progress: 1,
                            color: AppColors.success,
                            strokeWidth: 4.5,
                            glowStrength: glow,
                            showTip: false,
                          ),
                        ),

                      // Main button
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [light, dark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: activeColor.withValues(
                                alpha: 0.22 + (charge * 0.14) + (glow * 0.28),
                              ),
                              blurRadius: 16 + (charge * 8) + (glow * 22),
                              spreadRadius: 0 + (charge * 2) + (glow * 4),
                              offset: Offset(0, 6 * (1 - glow * 0.7)),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              showDone
                                  ? Icons.check_rounded
                                  : Icons.fingerprint_rounded,
                              size: showDone ? 44 : 40 + holdValue * 3,
                              color: AppColors.surface,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              showDone
                                  ? 'DONE'
                                  : (_isHolding
                                      ? '${(holdValue * 100).round()}%'
                                      : (widget.isCheckOut
                                          ? 'CHECK OUT'
                                          : 'CHECK IN')),
                              style: GoogleFonts.inter(
                                color: AppColors.surface,
                                fontSize: _isHolding ? 11 : 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Clean single-colour progress ring with a small white dot at the tip.
class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.glowStrength = 1.0,
    this.showTip = true,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final double glowStrength; // 0..1 (used for the blast flash)
  final bool showTip;

  @override
  void paint(Canvas canvas, Size size) {
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;

    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = p * math.pi * 2;

    // Subtle tint variation of the SAME colour (no rainbow).
    final hsl = HSLColor.fromColor(color);
    final lighter = hsl
        .withLightness((hsl.lightness + 0.14).clamp(0.0, 1.0))
        .toColor();

    final shader = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + math.pi * 2,
      colors: [color, lighter],
    ).createShader(rect);

    // Soft glow
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..color = color.withValues(alpha: 0.28 + 0.4 * glowStrength)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4 + 6 * glowStrength
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 + 5 * glowStrength),
    );

    // Main ring
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Small tip dot
    if (showTip) {
      final tipAngle = -math.pi / 2 + sweep;
      final tip =
          center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
      canvas.drawCircle(tip, 2.4, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.glowStrength != glowStrength ||
      old.showTip != showTip;
}

/// The success blast: flash + shockwave ring + radial sparks.
/// t: 0..1 (the wave controller value).
class _BlastPainter extends CustomPainter {
  _BlastPainter({required this.t, required this.color});

  final double t;
  final Color color;

  static const int _sparkCount = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const tau = math.pi * 2;

    final hsl = HSLColor.fromColor(color);
    final lighter = hsl
        .withLightness((hsl.lightness + 0.22).clamp(0.0, 1.0))
        .toColor();

    // 1) Flash: quick bright burst behind the button.
    if (t < 0.28) {
      final f = t / 0.28;
      final e = Curves.easeOut.transform(f);
      final r = 46 + e * 46;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: (1 - f) * 0.65),
              color.withValues(alpha: (1 - f) * 0.45),
              color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.5, 1.0],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    // 2) Shockwave ring: thick -> thin as it expands.
    final sw = (t / 0.7).clamp(0.0, 1.0);
    if (sw > 0 && sw < 1) {
      final e = Curves.easeOutCubic.transform(sw);
      final r = 52 + e * 64;
      final stroke = 7.0 * (1 - e) + 0.8;
      final alpha = (1 - e) * 0.9;

      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke + 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = lighter.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    // 3) Radial sparks (alternating long dashes and dots).
    final st = ((t - 0.02) / 0.75).clamp(0.0, 1.0);
    if (st > 0 && st < 1) {
      final e = Curves.easeOutCubic.transform(st);
      final fade = (1 - st);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final dot = Paint()..style = PaintingStyle.fill;

      for (int i = 0; i < _sparkCount; i++) {
        final angle = i / _sparkCount * tau + (i.isOdd ? 0.09 : 0.0);
        final dir = Offset(math.cos(angle), math.sin(angle));
        final variant = i % 3; // 0 long, 1 medium, 2 dot

        final travel = variant == 0 ? 70.0 : (variant == 1 ? 54.0 : 62.0);
        final startR = 52 + e * travel;

        if (variant == 2) {
          dot.color = lighter.withValues(alpha: fade);
          canvas.drawCircle(c + dir * (startR + 6), 2.2 * fade + 0.4, dot);
        } else {
          final len = (variant == 0 ? 16.0 : 9.0) * fade + 2;
          paint
            ..color = (i.isEven ? color : lighter).withValues(alpha: fade)
            ..strokeWidth = (variant == 0 ? 2.6 : 2.0) * (0.5 + 0.5 * fade);
          canvas.drawLine(c + dir * startR, c + dir * (startR + len), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BlastPainter old) =>
      old.t != t || old.color != color;
}