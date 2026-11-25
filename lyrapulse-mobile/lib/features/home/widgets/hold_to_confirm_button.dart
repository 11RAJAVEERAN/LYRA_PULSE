import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

// Aurora palette (green -> teal -> blue), like in-display fingerprint effects.
const _auroraGreen = Color(0xFF34D399);
const _auroraTeal = Color(0xFF06B6D4);
const _auroraBlue = Color(0xFF60A5FA);
const _auroraStops = [_auroraGreen, _auroraTeal, _auroraBlue];

/// v: 0..1 -> green .. teal .. blue
Color _auroraAt(double v) {
  final s = v.clamp(0.0, 1.0) * (_auroraStops.length - 1);
  final i = s.floor().clamp(0, _auroraStops.length - 2);
  return Color.lerp(_auroraStops[i], _auroraStops[i + 1], s - i)!;
}

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
  late final AnimationController _swirlController; // looping particle motion

  // Success beep (generated in code, no asset file needed).
  final AudioPlayer _player = AudioPlayer();
  late final Uint8List _beepBytes = _buildSuccessBeep();

  bool _isHolding = false;
  bool _isProcessing = false;
  int _lastHapticStep = 0;

  static const _holdDuration = Duration(seconds: 2);
  static const _waveDuration = Duration(milliseconds: 1400);
  static const _swirlDuration = Duration(milliseconds: 3000);

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

    _swirlController = AnimationController(
      vsync: this,
      duration: _swirlDuration,
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

    // Hold finished -> big success moment (vibration + beep).
    _isHolding = false;
    _isProcessing = true;
    _swirlController.stop();
    HapticFeedback.heavyImpact();
    _playSuccessBeep();

    setState(() {});

    _waveController.forward(from: 0).then((_) {
      if (!mounted) return;

      _isProcessing = false;
      _lastHapticStep = 0;
      _holdController.reset();
      _waveController.reset();
      _swirlController.reset();

      setState(() {});

      // Navigate only after all pulse waves finish.
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

    _swirlController.repeat();
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

    _swirlController.stop();
    _swirlController.reset();

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
    _swirlController.dispose();
    _player.dispose();
    super.dispose();
  }

  /// Bigger, overlapping pulse waves for the success burst.
  Widget _buildPulseWave(double progress, int waveIndex) {
    final waveProgress =
        ((progress - waveIndex * 0.18) / 0.64).clamp(0.0, 1.0);

    if (waveProgress <= 0 || waveProgress >= 1) {
      return const SizedBox.shrink();
    }

    final eased = Curves.easeOutCubic.transform(waveProgress);
    final size = 92 + (eased * 150);
    final opacity = (1 - eased) * 0.8;

    final waveColor = waveIndex.isEven ? _auroraGreen : _auroraBlue;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: waveColor.withValues(alpha: opacity),
          width: 3.2 - (eased * 1.8),
        ),
        boxShadow: [
          BoxShadow(
            color: waveColor.withValues(alpha: opacity * 0.5),
            blurRadius: 16 * (1 - eased),
            spreadRadius: 2 * (1 - eased),
          ),
        ],
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
            _swirlController,
          ]),
          builder: (context, child) {
            final waveProgress = _waveController.value;
            final holdValue = _holdController.value;
            final swirlT = _swirlController.value;
            final isWaveActive = _isProcessing;

            final glow =
                isWaveActive ? (1 - waveProgress).clamp(0.0, 1.0) : 0.0;

            final charge = _isHolding
                ? Curves.easeIn.transform(holdValue.clamp(0.0, 1.0))
                : 0.0;

            // Aurora fades in almost instantly after press (~200 ms).
            final appear = _isHolding
                ? Curves.easeOut.transform((holdValue * 10).clamp(0.0, 1.0))
                : 0.0;

            double scale = 1.0;
            if (_isHolding) {
              scale = 1.0 + 0.12 * Curves.easeOut.transform(holdValue);
            } else if (isWaveActive) {
              scale = 1.0 +
                  0.2 * (1 - Curves.easeOutBack.transform(waveProgress));
            }

            final shake = _isHolding && holdValue > 0.7
                ? math.sin(holdValue * 90) * (holdValue - 0.7) * 3
                : 0.0;

            final ringColor =
                isWaveActive ? AppColors.success : AppColors.secondary;


            final showDone = isWaveActive;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (_isHolding) ...[
                  // Soft green/blue aura behind everything
                  Container(
                    width: 130 + charge * 50,
                    height: 130 + charge * 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          _auroraGreen.withValues(alpha: 0.38 * appear),
                          _auroraBlue.withValues(alpha: 0.14 * appear),
                          _auroraBlue.withValues(alpha: 0),
                         
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                  // Swirling particles + aurora ribbons
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: _AuroraSwirlPainter(
                      t: swirlT,
                      progress: holdValue,
                      appear: appear,
                    ),
                  ),
                ],

                if (isWaveActive) ...[
                  _buildPulseWave(waveProgress, 0),
                  _buildPulseWave(waveProgress, 1),
                  _buildPulseWave(waveProgress, 2),
                  Container(
                    width: 100 + (glow * 40),
                    height: 100 + (glow * 40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _auroraBlue.withValues(alpha: 0.30 * glow),
                          blurRadius: 30 + (glow * 30),
                          spreadRadius: 4 + (glow * 8),
                        ),
                        BoxShadow(
                          color: _auroraGreen.withValues(alpha: 0.40 * glow),
                          blurRadius: 24 + (glow * 24),
                          spreadRadius: 3 + (glow * 6),
                        ),
                      ],
                    ),
                  ),
                ],

                Transform.translate(
                  offset: Offset(shake, 0),
                  child: Transform.scale(
                    scale: scale,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Track ring (turns full green on DONE)
                        SizedBox(
                          width: 106,
                          height: 106,
                          child: CircularProgressIndicator(
                            value: isWaveActive ? 1 : 0,
                            strokeWidth: 4.5,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.13),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(ringColor),
                          ),
                        ),
                        // Aurora progress ring while holding
                        if (_isHolding)
                          CustomPaint(
                            size: const Size(106, 106),
                            painter: _AuroraRingPainter(
                              progress: holdValue,
                              rotation: swirlT * math.pi * 2,
                              strokeWidth: 4.5 + holdValue * 2.5,
                            ),
                          ),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isHolding
                                  ? const [_auroraGreen, _auroraTeal]
                                  : [
                                      showDone ? AppColors.success : buttonColor,
                                      showDone
                                          ? AppColors.success
                                              .withValues(alpha: 0.8)
                                          : buttonColor.withValues(alpha: 0.78),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isHolding ? _auroraGreen : buttonColor)
                                    .withValues(
                                  alpha: 0.24 + (charge * 0.35) + (glow * 0.25),
                                ),
                                blurRadius: 18 + (charge * 24) + (glow * 18),
                                spreadRadius: 1 + (charge * 5) + (glow * 3),
                              ),
                              if (_isHolding)
                                BoxShadow(
                                  color: _auroraBlue
                                      .withValues(alpha: 0.30 * appear),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              if (isWaveActive)
                                BoxShadow(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.30 * glow),
                                  blurRadius: 22,
                                  spreadRadius: 2,
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
                                size: showDone ? 46 : 42 + holdValue * 4,
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Green -> blue progress ring with a glowing spark at the tip.
class _AuroraRingPainter extends CustomPainter {
  _AuroraRingPainter({
    required this.progress,
    required this.rotation,
    required this.strokeWidth,
  });

  final double progress;
  final double rotation;
  final double strokeWidth;

  // First = last -> seamless loop while rotating.
  static const _colors = [
    _auroraGreen,
    _auroraTeal,
    _auroraBlue,
    _auroraTeal,
    _auroraGreen,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final shader = SweepGradient(
      colors: _colors,
      transform: GradientRotation(rotation),
    ).createShader(rect);

    final p = progress.clamp(0.0, 1.0);
    final sweep = p * math.pi * 2;

    // Soft glow
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
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

    // Spark at the tip
    if (p > 0) {
      final tipAngle = -math.pi / 2 + sweep;
      final tip =
          center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
      canvas.drawCircle(
        tip,
        9,
        Paint()
          ..color = _auroraTeal.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      canvas.drawCircle(tip, 3.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraRingPainter old) =>
      old.progress != progress ||
      old.rotation != rotation ||
      old.strokeWidth != strokeWidth;
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.radius,
    required this.dir,
    required this.speed,
    required this.size,
    required this.phase,
    required this.hue,
  });

  final double angle;
  final double radius;
  final int dir; // +1 / -1 rotation direction
  final int speed; // integer -> seamless loop
  final double size;
  final double phase;
  final double hue; // 0..1 along the aurora palette
}

List<_Particle> _buildParticles() {
  final r = math.Random(7);
  return List.generate(
    70,
    (_) => _Particle(
      angle: r.nextDouble() * math.pi * 2,
      radius: 44 + r.nextDouble() * 34,
      dir: r.nextBool() ? 1 : -1,
      speed: 1 + r.nextInt(2),
      size: 0.8 + r.nextDouble() * 2.2,
      phase: r.nextDouble() * math.pi * 2,
      hue: r.nextDouble(),
    ),
  );
}

final List<_Particle> _particles = _buildParticles();

/// Glowing particle cloud + flowing aurora ribbons around the button.
class _AuroraSwirlPainter extends CustomPainter {
  _AuroraSwirlPainter({
    required this.t,
    required this.progress,
    required this.appear,
  });

  final double t; // 0..1 looping
  final double progress; // 0..1 hold progress
  final double appear; // 0..1 fade-in

  final Paint _dot = Paint();
  final Paint _dotGlow = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

  @override
  void paint(Canvas canvas, Size size) {
    if (appear <= 0) return;

    final c = size.center(Offset.zero);
    const tau = math.pi * 2;
    final spread = 1 + progress * 0.18; // cloud slowly expands while holding

    // Flowing aurora ribbons
    for (int k = 0; k < 3; k++) {
      final r = (54 + k * 10.0) * spread;
      final dir = k.isEven ? 1 : -1;
      final start = dir * t * tau * (1 + k) + k * 2.1;
      final sweep = 1.3 + 0.5 * math.sin(t * tau + k);
      final col = _auroraAt(k / 2);
      final rect = Rect.fromCircle(center: c, radius: r);

      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = col.withValues(alpha: 0.38 * appear)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = col.withValues(alpha: 0.85 * appear)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }

    // Sparkling particles
    for (final p in _particles) {
      final ang = p.angle +
          p.dir * t * tau * p.speed +
          math.sin(t * tau * 2 + p.phase) * 0.18;
      final rad =
          (p.radius + math.sin(t * tau * p.speed + p.phase) * 5) * spread;
      final pos = c + Offset(math.cos(ang), math.sin(ang)) * rad;

      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(t * tau * 2 + p.phase));
      final alpha = (twinkle * appear).clamp(0.0, 1.0);
      final col = _auroraAt(p.hue);

      if (p.size > 2) {
        _dotGlow.color = col.withValues(alpha: alpha * 0.45);
        canvas.drawCircle(pos, p.size * 2.4, _dotGlow);
      }
      _dot.color = col.withValues(alpha: alpha);
      canvas.drawCircle(pos, p.size * (0.8 + 0.4 * twinkle), _dot);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraSwirlPainter old) =>
      old.t != t || old.progress != progress || old.appear != appear;
}