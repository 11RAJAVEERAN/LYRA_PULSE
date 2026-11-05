import 'package:get/get.dart';

import '../../features/attendance/controllers/camera_capture_controller.dart';
import '../../features/attendance/views/attendance_confirm_screen.dart';
import '../../features/attendance/views/attendance_success_screen.dart';
import '../../features/attendance/views/camera_capture_screen.dart';
import '../../features/attendance/views/location_check_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/otp_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/splash/controllers/splash_controller.dart';
import '../../features/splash/views/splash_screen.dart';
import 'app_routes.dart';

abstract final class AppPages {
  /// SplashController lives only while a splash route is on the stack.
  static final BindingsBuilder _splashBinding = BindingsBuilder(() {
    Get.lazyPut<SplashController>(() => SplashController());
  });

  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashScreen(),
      binding: _splashBinding,
    ),
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: _splashBinding,
    ),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(name: AppRoutes.otp, page: () => const OtpScreen()),
    GetPage(name: AppRoutes.home, page: () => const HomeScreen()),

    // ATTENDANCE FLOW (AttendanceController is app-wide, see InitialBinding)
    GetPage(name: AppRoutes.attendanceLocation, page: () => const LocationCheckScreen()),
    GetPage(
      name: AppRoutes.attendanceCamera,
      page: () => const CameraCaptureScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CameraCaptureController>(() => CameraCaptureController());
      }),
    ),
    GetPage(name: AppRoutes.attendanceConfirm, page: () => const AttendanceConfirmScreen()),
    GetPage(name: AppRoutes.attendanceSuccess, page: () => const AttendanceSuccessScreen()),
  ];
}