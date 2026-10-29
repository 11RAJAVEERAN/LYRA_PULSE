
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class HoldToConfirmButton extends StatefulWidget {
  final bool isCheckOut;
  final VoidCallback onConfirm;

  const HoldToConfirmButton({
    super.key,
    required this.isCheckOut,
    required this.onConfirm,
  });

  @override
  State<HoldToConfirmButton> createState() =>
      _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with TickerProviderStateMixin {
  late final AnimationController _holdController;
  late final AnimationController _waveController;

  bool _isHolding = false;
  bool _isProcessing = false;

  static const _holdDuration = Duration(seconds: 2);
  static const _waveDuration = Duration(milliseconds: 1100);

  Color get _buttonColor => widget.isCheckOut
      ? AppColors.orange
      : AppColors.success;

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
  }

  void _handleHoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_isHolding) {
      return;
    }

    // Hold has finished. Start the pulse animation only now.
    _isHolding = false;
    _isProcessing = true;

    setState(() {});

    _waveController.forward(from: 0).then((_) {
      if (!mounted) return;

      _isProcessing = false;
      _holdController.reset();
      _waveController.reset();

      setState(() {});

      // Navigate only after all pulse waves finish.
      widget.onConfirm();
    });
  }

  void _startHold() {
    if (_isHolding || _isProcessing) return;

    setState(() {
      _isHolding = true;
    });

    // Keep pulse waves completely inactive during the hold.
    _waveController.stop();
    _waveController.reset();

    _holdController.forward(from: 0);
  }

  void _cancelHold() {
    if (!_isHolding) return;

    _isHolding = false;

    _holdController.stop();
    _holdController.reset();

    // Early release cancels without starting the pulse animation.
    _waveController.stop();
    _waveController.reset();

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant HoldToConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isCheckOut != widget.isCheckOut && _isHolding) {
      _cancelHold();
    }
  }

  @override
  void dispose() {
    _holdController.removeStatusListener(_handleHoldStatus);
    _holdController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Widget _buildPulseWave(double progress, int waveIndex) {
    // Three waves expand one after another.
    final waveProgress =
        ((progress * 3) - waveIndex).clamp(0.0, 1.0);

    if (waveProgress <= 0 || waveProgress >= 1) {
      return const SizedBox.shrink();
    }

    final eased = Curves.easeOutCubic.transform(waveProgress);
    final size = 88 + (eased * 94);
    final opacity = (1 - eased) * 0.72;

    final waveColor =
        waveIndex.isEven ? AppColors.accent : AppColors.secondary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: waveColor.withValues(alpha: opacity),
          width: 2.5 - (eased * 1.2),
        ),
        boxShadow: [
          BoxShadow(
            color: waveColor.withValues(alpha: opacity * 0.5),
            blurRadius: 12 * (1 - eased),
            spreadRadius: 1.5 * (1 - eased),
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
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      child: SizedBox(
        width: 100,
        height: 100,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _holdController,
            _waveController,
          ]),
          builder: (context, child) {
            final progress = _waveController.value;
            final isWaveActive = _isProcessing;

            final glow = isWaveActive
                ? (1 - progress).clamp(0.0, 1.0)
                : 0.0;

            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Pulse waves: appear only after the 2-second hold.
                if (isWaveActive) ...[
                  _buildPulseWave(progress, 0),
                  _buildPulseWave(progress, 1),
                  _buildPulseWave(progress, 2),

                  // Blue-purple ambient glow.
                  Container(
                    width: 94 + (glow * 24),
                    height: 94 + (glow * 24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(
                            alpha: 0.24 * glow,
                          ),
                          blurRadius: 25 + (glow * 25),
                          spreadRadius: 3 + (glow * 5),
                        ),
                        BoxShadow(
                          color: AppColors.secondary.withValues(
                            alpha: 0.25 * glow,
                          ),
                          blurRadius: 18 + (glow * 18),
                          spreadRadius: 2 + (glow * 4),
                        ),
                      ],
                    ),
                  ),
                ],

                // Hold progress ring. No pulse animation during hold.
                SizedBox(
                  width: 106,
                  height: 106,
                  child: CircularProgressIndicator(
                    value: _isHolding ? _holdController.value : 0,
                    strokeWidth: 4.5,
                    strokeCap: StrokeCap.round,
                    backgroundColor:
                        AppColors.primaryBlue.withValues(alpha: 0.13),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isHolding ? AppColors.accent : AppColors.secondary,
                    ),
                  ),
                ),

                // Fingerprint button.
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        buttonColor,
                        _isHolding
                            ? AppColors.secondaryDark
                            : buttonColor.withValues(alpha: 0.78),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: buttonColor.withValues(
                          alpha: 0.24 + (glow * 0.25),
                        ),
                        blurRadius: 18 + (glow * 18),
                        spreadRadius: 1 + (glow * 3),
                      ),
                      if (isWaveActive)
                        BoxShadow(
                          color: AppColors.secondary.withValues(
                            alpha: 0.30 * glow,
                          ),
                          blurRadius: 22,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        size: 42,
                        color: AppColors.surface.withValues(
                          alpha: isWaveActive ? 0.9 + (glow * 0.1) : 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.isCheckOut ? 'CHECK OUT' : 'CHECK IN',
                        style: GoogleFonts.inter(
                          color: AppColors.surface,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
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
