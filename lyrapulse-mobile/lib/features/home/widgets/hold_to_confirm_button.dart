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
  static const _waveDuration = Duration(milliseconds: 1400);

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

    // Hold finished -> big success moment (vibration + beep).
    _isHolding = false;
    _isProcessing = true;
    HapticFeedback.heavyImpact();
    _playSuccessBeep();

    setState(() {});

    _waveController.forward(from: 0).then((_) {
      if (!mounted) return;

      _isProcessing = false;
      _lastHapticStep = 0;
      _holdController.reset();
      _waveController.reset();

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

    final waveColor = waveIndex.isEven ? AppColors.accent : AppColors.secondary;
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
          ]),
          builder: (context, child) {
            final waveProgress = _waveController.value;
            final holdValue = _holdController.value;
            final isWaveActive = _isProcessing;

            final glow =
                isWaveActive ? (1 - waveProgress).clamp(0.0, 1.0) : 0.0;

            final charge = _isHolding
                ? Curves.easeIn.transform(holdValue.clamp(0.0, 1.0))
                : 0.0;

            double scale = 1.0;
            if (_isHolding) {
              scale = 1.0 + 0.2 * Curves.easeOut.transform(holdValue);
            } else if (isWaveActive) {
              scale = 1.0 +
                  0.2 * (1 - Curves.easeOutBack.transform(waveProgress));
            }

            final shake = _isHolding && holdValue > 0.6
                ? math.sin(holdValue * 90) * (holdValue - 0.6) * 3
                : 0.0;

            final ringColor = isWaveActive
                ? AppColors.success
                : (_isHolding ? AppColors.accent : AppColors.secondary);

            final showDone = isWaveActive;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (_isHolding) ...[
                  Container(
                    width: 100 + charge * 40,
                    height: 100 + charge * 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          buttonColor.withValues(alpha: 0.28 * charge),
                          buttonColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: const Size(100, 100),
                    painter: _ChargePainter(
                      progress: holdValue,
                      color: buttonColor,
                      accent: AppColors.accent,
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
                          color: AppColors.primaryBlue
                              .withValues(alpha: 0.28 * glow),
                          blurRadius: 30 + (glow * 30),
                          spreadRadius: 4 + (glow * 8),
                        ),
                        BoxShadow(
                          color: AppColors.success
                              .withValues(alpha: 0.35 * glow),
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
                        SizedBox(
                          width: 106,
                          height: 106,
                          child: CircularProgressIndicator(
                            value: isWaveActive ? 1 : (_isHolding ? holdValue : 0),
                            strokeWidth: _isHolding ? 4.5 + holdValue * 3 : 4.5,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                AppColors.primaryBlue.withValues(alpha: 0.13),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(ringColor),
                          ),
                        ),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                showDone ? AppColors.success : buttonColor,
                                _isHolding
                                    ? AppColors.secondaryDark
                                    : (showDone
                                        ? AppColors.success
                                            .withValues(alpha: 0.8)
                                        : buttonColor.withValues(alpha: 0.78)),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: buttonColor.withValues(
                                  alpha: 0.24 + (charge * 0.3) + (glow * 0.25),
                                ),
                                blurRadius: 18 + (charge * 22) + (glow * 18),
                                spreadRadius: 1 + (charge * 4) + (glow * 3),
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

/// Spinning energy rays + glowing spark at the tip of the progress ring.
class _ChargePainter extends CustomPainter {
  _ChargePainter({
    required this.progress,
    required this.color,
    required this.accent,
  });

  final double progress;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final p = progress.clamp(0.0, 1.0);

    const rays = 16;
    final rotation = p * math.pi * 2;
    for (int i = 0; i < rays; i++) {
      final a = rotation + (i / rays) * math.pi * 2;
      final inner = 60 + p * 6;
      final len = (6 + p * 16) * (i.isEven ? 1.0 : 0.6);
      final paint = Paint()
        ..color = (i.isEven ? color : accent).withValues(alpha: 0.15 + p * 0.6)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * inner,
        center + Offset(math.cos(a), math.sin(a)) * (inner + len),
        paint,
      );
    }

    final tipAngle = -math.pi / 2 + p * math.pi * 2;
    final tip = center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * 53;
    canvas.drawCircle(
      tip,
      9,
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(tip, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ChargePainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.accent != accent;
}