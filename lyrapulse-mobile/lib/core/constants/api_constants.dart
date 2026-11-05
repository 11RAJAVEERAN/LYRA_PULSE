abstract final class ApiConstants {
  static const String apiPrefix = 'api/v1/';
  static const String sendOtp = 'auth/employee/send-otp/';
  static const String resendOtp = 'auth/employee/resend-otp/';
  static const String verifyOtp = 'auth/employee/verify-otp/';
  static const String currentUser = 'auth/me/';
  static const String logout = 'auth/logout/';
  static const String employeeMe = 'mobile/me/';

  // Attendance (employee only; employee, branch and time are decided by the server)
  static const String attendanceVerifyLocation = 'attendance/verify-location/';
  static const String attendanceCheckIn = 'attendance/check-in/';
  static const String attendanceCheckOut = 'attendance/check-out/';
  static const String attendanceToday = 'attendance/today/';
}