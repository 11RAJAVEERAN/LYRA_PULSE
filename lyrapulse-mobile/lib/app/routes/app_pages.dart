import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/otp_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/splash/views/splash_screen.dart';
import '../../features/attendance/views/location_verification_screen.dart';
import '../../features/permission/views/permission_start_screen.dart';
import '../../features/permission/views/permission_submitted_screen.dart';
import '../../features/permission/views/permission_return_screen.dart';

import 'app_routes.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = [
    // INITIAL
    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashScreen(),
    ),

    // SPLASH
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),

    // LOGIN
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put<AuthController>(AuthController());
        }
      }),
    ),

    // OTP
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put<AuthController>(AuthController());
        }
      }),
    ),

    // HOME
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),

    // ATTENDANCE
    GetPage(
      name: AppRoutes.locationVerification,
      page: () => const LocationVerificationScreen(),
    ),

    // PERMISSION START
    GetPage(
      name: AppRoutes.permissionStart,
      page: () => const PermissionStartScreen(),
    ),

    // PERMISSION SUBMITTED
    GetPage(
      name: AppRoutes.permissionSubmitted,
      page: () => const PermissionSubmittedScreen(),
    ),

    // PERMISSION RETURN
    GetPage(
      name: AppRoutes.permissionReturn,
      page: () => const PermissionReturnScreen(),
    ),

    // BOTTOM NAVIGATION
    GetPage(
      name: AppRoutes.attendance,
      page: () => const _PlaceholderPage(
        title: 'Attendance',
        icon: Icons.access_time_rounded,
      ),
    ),

    GetPage(
      name: AppRoutes.leave,
      page: () => const _PlaceholderPage(
        title: 'Leave',
        icon: Icons.event_available_rounded,
      ),
    ),

    GetPage(
      name: AppRoutes.profile,
      page: () => const _PlaceholderPage(
        title: 'Profile',
        icon: Icons.person_outline_rounded,
      ),
    ),
  ];
}

// PLACEHOLDER PAGE

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF04111F),
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Icon(
          icon,
          color: const Color(0xFF20DFFF),
          size: 60,
        ),
      ),
    );
  }
}