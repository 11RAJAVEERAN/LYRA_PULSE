abstract final class AppRoutes {
  // ===============================================================
  // MAIN ROUTES
  // ===============================================================

  static const String initial = '/';

  static const String splash = '/splash';

  static const String login = '/login';

  static const String otp = '/otp';

  static const String home = '/home';

  // ===============================================================
  // ATTENDANCE FLOW
  // ===============================================================

  static const String locationVerification =
      '/location-verification';

  // ===============================================================
  // PERMISSION FLOW
  // ===============================================================

  // Step 1:
  // Home → Permission Start

  static const String permissionStart =
      '/permission-start';

  // Step 2:
  // Permission Start → Permission Submitted

  static const String permissionSubmitted =
      '/permission-submitted';

  // Step 3:
  // Permission Submitted → Permission Return

  static const String permissionReturn =
      '/permission-return';

  // ===============================================================
  // BOTTOM NAVIGATION
  // ===============================================================

  static const String attendance =
      '/attendance';

  static const String leave =
      '/leave';

  static const String profile =
      '/profile';
}