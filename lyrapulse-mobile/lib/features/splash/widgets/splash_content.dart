import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class SplashContent extends StatefulWidget {
  const SplashContent({super.key});

  @override
  State<SplashContent> createState() => _SplashContentState();
}

class _SplashContentState extends State<SplashContent>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _dotsController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // Main splash animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Running dots animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _logoScale = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.65,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.0,
          0.45,
          curve: Curves.easeIn,
        ),
      ),
    );

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.45,
          1.0,
          curve: Curves.easeIn,
        ),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: double.infinity,

      // App background color
      color: AppColors.background,

      child: Stack(
        children: [
          // ============================================================
          // TOP LEFT BACKGROUND GLOW
          // ============================================================
          Positioned(
            top: -size.width * 0.30,
            left: -size.width * 0.30,
            child: _buildGlowCircle(
              size: size.width * 0.70,
              colors: [
                AppColors.primary.withOpacity(0.20),
                AppColors.accent.withOpacity(0.10),
                Colors.transparent,
              ],
            ),
          ),

          // ============================================================
          // BOTTOM RIGHT BACKGROUND GLOW
          // ============================================================
          Positioned(
            right: -size.width * 0.35,
            bottom: -size.width * 0.35,
            child: _buildGlowCircle(
              size: size.width * 0.78,
              colors: [
                Colors.transparent,
                AppColors.accent.withOpacity(0.10),
                AppColors.primary.withOpacity(0.20),
              ],
            ),
          ),

          // ============================================================
          // MAIN CONTENT
          // ============================================================
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Column(
                  children: [
                    // --------------------------------------------------
                    // LOGO + TITLE
                    // --------------------------------------------------
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -50),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // L LOGO
                            Opacity(
                              opacity: _logoFade.value,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: Image.asset(
                                  'assets/logo/image.png',
                                  width: size.width * 0.35,
                                  height: size.width * 0.32,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // ------------------------------------------------
                            // LYRA PULSE
                            // ------------------------------------------------
                            Opacity(
                              opacity: _textFade.value,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'LYRA PULSE',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: AppColors.primary,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 9),

                            // ------------------------------------------------
                            // TAGLINE
                            // ------------------------------------------------
                            // Opacity(
                            //   opacity: _textFade.value,
                            //   child: FittedBox(
                            //     fit: BoxFit.scaleDown,
                            //     child: Text(
                            //       'WORK BETTER TOGETHER',
                            //       textAlign: TextAlign.center,
                            //       style: GoogleFonts.inter(
                            //         color: AppColors.primaryDark,
                            //         fontSize: 15,
                            //         fontWeight: FontWeight.w400,
                                   
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),

                    // ======================================================
                    // RUNNING 3 DOTS
                    // ======================================================
                    Opacity(
                      opacity: _textFade.value,
                      child: AnimatedBuilder(
                        animation: _dotsController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildAnimatedDot(0),
                              const SizedBox(width: 12),
                              _buildAnimatedDot(1),
                              const SizedBox(width: 12),
                              _buildAnimatedDot(2),
                            ],
                          );
                        },
                      ),
                    ),

                    // ======================================================
                    // FROM LYRA TECH
                    // ======================================================
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 35,
                        bottom: 45,
                      ),
                      child: Opacity(
                        opacity: _textFade.value,
                        child: Column(
                          children: [
                            Text(
                              'FROM',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 2.5,
                              ),
                            ),

                            const SizedBox(height: 6),

                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'LYRA TECH',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3.0,
                                ),
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
        ],
      ),
    );
  }

  // ================================================================
  // BACKGROUND GLOW
  // ================================================================
  Widget _buildGlowCircle({
    required double size,
    required List<Color> colors,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: colors,
        ),
      ),
    );
  }

  // ================================================================
  // RUNNING DOT
  // ================================================================
  Widget _buildAnimatedDot(int index) {
    final value = (_dotsController.value + (index * 0.20)) % 1.0;

    // Active period for each dot
    final distance = (value - 0.5).abs();
    final activeValue = (1.0 - distance * 2).clamp(0.0, 1.0);

    final scale = 0.75 + (activeValue * 0.35);
    final opacity = 0.35 + (activeValue * 0.65);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(
                  activeValue * 0.35,
                ),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}