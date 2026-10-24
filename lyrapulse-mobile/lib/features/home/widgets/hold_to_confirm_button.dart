
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _HoldToConfirmButtonState
    extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

   _controller.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    widget.onConfirm();
    _controller.reset();
  }
});
  }

  void _startHold() {
    if (_completed) return;

    _controller.forward(from: 0);
  }

  void _cancelHold() {
    if (!_completed) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void didUpdateWidget(covariant HoldToConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isCheckOut != widget.isCheckOut) {
      _completed = false;
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isCheckOut
        ? const Color(0xFFFF7043)
        : const Color(0xFF22C55E);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _cancelHold(),
      onTapCancel: _cancelHold,
      child: SizedBox(
        width: 97,
        height: 97,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                   SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: _controller.value,
                    strokeWidth: 5,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.blue.withValues(alpha: 0.15),
                    valueColor: 
                    const AlwaysStoppedAnimation<Color>
                    (Color(0xFF2563EB),
                    ),
                  ),
                ),



                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.28),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isCheckOut
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        color: Colors.white,
                        size: 25,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.isCheckOut ? 'CHECK OUT' : 'CHECK IN',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                // Positioned(
                //   bottom: 0,
                //   child: Container(
                //     padding: const EdgeInsets.symmetric(
                //       horizontal: 10,
                //       vertical: 4,
                //     ),
                //     decoration: BoxDecoration(
                //       color: Theme.of(context).colorScheme.surface,
                //       borderRadius: BorderRadius.circular(20),
                //     ),
                //     child: Text(
                //       _controller.isAnimating
                //           ? '${(3 - (_controller.value * 3)).ceil()} sec'
                //           : 'Hold 3 sec',
                //       style: GoogleFonts.inter(
                //         fontSize: 10,
                //         fontWeight: FontWeight.w700,
                //         color: color,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            );
          },
        ),
      ),
    );
  }
}
