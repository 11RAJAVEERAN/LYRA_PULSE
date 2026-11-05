abstract final class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String home = '/home';

  // Attendance flow (Home -> location -> camera -> confirm -> success)
  static const String attendanceLocation = '/attendance/location';
  static const String attendanceCamera = '/attendance/camera';
  static const String attendanceConfirm = '/attendance/confirm';
  static const String attendanceSuccess = '/attendance/success';
}
