abstract final class AppConstants {
  static const int otpLength = 6;
  static const int otpCountdownSeconds = 30;

  /// Minimum time the splash screen stays visible, so the branding animation
  /// can play even when the session check finishes instantly.
  static const Duration splashMinDuration = Duration(seconds: 4);
}