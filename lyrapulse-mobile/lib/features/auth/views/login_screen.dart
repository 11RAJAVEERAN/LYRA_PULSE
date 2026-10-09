import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/asset_paths.dart';
import '../controllers/auth_controller.dart';
import '../widgets/phone_input.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  // Keeps the form phone-sized on Flutter Web / tablets.
  static const double _maxContentWidth = 480;
  static const double _maxIllustrationWidth = 560;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _BackdropPainter())),
          ),
          SafeArea(
            child: LayoutBuilder(builder: (context, constraints) {
              // The illustration keeps its aspect ratio; it only shrinks when
              // height is tight (short phones, keyboard open).
              final illustrationMaxHeight =
                  (constraints.maxHeight * 0.36).clamp(110.0, 340.0).toDouble();
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  // IntrinsicHeight lets the Spacer below absorb spare height
                  // on tall screens while still scrolling on short ones.
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _LoginIllustration(
                          maxWidth: _maxIllustrationWidth,
                          maxHeight: illustrationMaxHeight,
                        ),
                        const SizedBox(height: 4),
                        Semantics(
                          header: true,
                          child: Text('Employee Login',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.display
                                  .copyWith(color: AppColors.primary)),
                        ),
                        const SizedBox(height: 6),
                        Text('Sign in to continue to your account',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall
                                .copyWith(fontSize: 14)),
                        const SizedBox(height: 20),
                        _ContentWidth(
                            maxWidth: _maxContentWidth,
                            child: _LoginForm(controller: controller)),
                        const SizedBox(height: 14),
                        const _ContentWidth(
                            maxWidth: _maxContentWidth,
                            horizontalInset: 16,
                            child: _OrDivider()),
                        const SizedBox(height: 12),
                        const _SecurityBadge(),
                        const SizedBox(height: 20),
                        const Spacer(),
                        Text('POWERED BY LYRATECH',
                            style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.4)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Centers [child] with a max width and the standard page padding.
class _ContentWidth extends StatelessWidget {
  const _ContentWidth({
    required this.maxWidth,
    required this.child,
    this.horizontalInset = 0,
  });

  final double maxWidth;
  final double horizontalInset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.pagePadding + horizontalInset),
          child: child,
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius + 6),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.focusSubtle,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                    color: AppColors.infoBackground, shape: BoxShape.circle),
                child: const Icon(Icons.smartphone_rounded,
                    size: 24, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phone Number',
                        style: AppTextStyles.title
                            .copyWith(fontSize: 17, color: AppColors.primary)),
                    const SizedBox(height: 2),
                    Text('Enter your registered mobile number',
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PhoneInput(
            controller: controller.phoneController,
            // Same send-OTP flow as the Login button (it guards against
            // repeated submissions and runs the existing validation).
            onSubmitted: (_) => controller.sendOtp(),
          ),
          const SizedBox(height: 14),
          Obx(() {
            final sending = controller.isSendingOtp.value;
            return _LoginButton(
              loading: sending,
              onPressed: sending ? null : controller.sendOtp,
            );
          }),
        ],
      ),
    );
  }
}

/// Gradient Login button with a leading arrow badge. Private to this screen
/// because `AppButton` only supports a trailing icon; the shared button is
/// left untouched. Uses the same AppColors.primary -> secondary gradient.
class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimensions.cardRadius);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: loading ? 'Logging in' : 'Login',
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox(
        width: double.infinity,
        height: AppDimensions.buttonHeight + 2,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.selection,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: onPressed,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                          color: AppColors.surface, shape: BoxShape.circle),
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.all(7),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryBlue),
                            )
                          : const Icon(Icons.arrow_forward_rounded,
                              size: 18, color: AppColors.primaryBlue),
                    ),
                    const SizedBox(width: 12),
                    Text('Login',
                        style: AppTextStyles.button.copyWith(fontSize: 17)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual-only "OR" divider (no alternate login method exists).
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 1, color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('OR',
              style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
        ),
        const Expanded(child: Divider(height: 1, color: AppColors.border)),
      ],
    );
  }
}

/// Visual-only trust badge.
class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded,
              size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Flexible(
            child: Text('Secure · Fast · Reliable',
                style: AppTextStyles.bodySmall
                    .copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _LoginIllustration extends StatelessWidget {
  const _LoginIllustration({required this.maxWidth, required this.maxHeight});

  final double maxWidth;
  final double maxHeight;

  // Alpha-only fade masks: they soften the image edges into the page
  // background; the transparent/black values are never painted.
  static const _fadeColors = [
    Colors.transparent,
    Colors.black,
    Colors.black,
    Colors.transparent,
  ];

  @override
  Widget build(BuildContext context) {
    // No fixed size and no BoxFit.cover: the image scales to fit the width and
    // `maxHeight` while preserving its aspect ratio (never stretched/cropped).
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _fadeColors,
            stops: [0, 0.08, 0.94, 1],
          ).createShader(rect),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) => const LinearGradient(
              colors: _fadeColors,
              stops: [0, 0.05, 0.95, 1],
            ).createShader(rect),
            child: Image.asset(
              AssetPaths.loginIllustration,
              cacheWidth: 1000,
              semanticLabel: 'Employee checking in on a laptop',
              // A missing/corrupt asset must never crash the login screen.
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle corner curves and a dot grid, drawn only with existing theme tokens.
class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shape = Paint()..color = AppColors.selected;
    final w = size.width;
    final h = size.height;
    canvas
      ..drawCircle(Offset(0, h + w * 0.12), w * 0.38, shape)
      ..drawCircle(Offset(w * 1.02, h + w * 0.06), w * 0.30, shape);

    final dot = Paint()..color = AppColors.selection;
    const gap = 14.0;
    final originX = w - AppDimensions.pagePadding - gap * 2;
    final originY = h - 150;
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawCircle(
            Offset(originX + col * gap, originY + row * gap), 1.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => false;
}