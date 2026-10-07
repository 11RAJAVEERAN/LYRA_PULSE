import 'package:get/get.dart';

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
  ];
}