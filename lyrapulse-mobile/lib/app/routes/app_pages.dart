import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/otp_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/splash/controllers/splash_controller.dart';
import '../../features/splash/views/splash_screen.dart';
import 'app_routes.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = [
    // Splash
    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put<SplashController>(SplashController());
      }),
    ),

    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder(() {
        Get.put<SplashController>(SplashController());
      }),
    ),

    // Login
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(
          () => AuthController(),
        );
      }),
    ),

    // OTP
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.lazyPut<AuthController>(
            () => AuthController(),
          );
        }
      }),
    ),

    // Home
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),
  ];
}