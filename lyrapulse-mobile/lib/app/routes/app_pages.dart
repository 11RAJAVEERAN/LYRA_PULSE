import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/otp_screen.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/splash/views/splash_screen.dart';
import '../../features/attendance/views/location_verification_screen.dart';

// Permission
import '../../features/permission/permission_screen.dart';
import '../../features/permission/views/permission_submitted_screen.dart';
import '../../features/permission/views/permission_return_screen.dart';

// Leave
import '../../features/leave/views/leave_screen.dart';

import 'app_routes.dart';
import '../theme/app_colors.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = [
    // --------------------------------------------------
    // SPLASH
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashScreen(),
    ),

    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),

    // --------------------------------------------------
    // LOGIN
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put<AuthController>(AuthController());
        }
      }),
    ),

    // --------------------------------------------------
    // OTP
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<AuthController>()) {
          Get.put<AuthController>(AuthController());
        }
      }),
    ),

    // --------------------------------------------------
    // HOME
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.home,
      page: () => HomeScreen(),
    ),

    // --------------------------------------------------
    // LOCATION VERIFICATION
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.locationVerification,
      page: () => const LocationVerificationScreen(
      isCheckOut: false,
),    ),

    // --------------------------------------------------
    // PERMISSION
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.permissionStart,
      page: () => const PermissionScreen(),
    ),

    // --------------------------------------------------
    // PERMISSION SUBMITTED
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.permissionSubmitted,
      page: () => const PermissionSubmittedScreen(),
    ),

    // --------------------------------------------------
    // PERMISSION RETURN
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.permissionReturn,
      page: () => const PermissionReturnScreen(),
    ),

    // --------------------------------------------------
    // ATTENDANCE
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.attendance,
      page: () => const _PlaceholderPage(
        title: 'Attendance',
        icon: Icons.access_time_rounded,
      ),
    ),

    // --------------------------------------------------
    // LEAVE
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.leave,
      page: () => const LeaveScreen(),
    ),

    // --------------------------------------------------
    // PROFILE
    // --------------------------------------------------
    GetPage(
      name: AppRoutes.profile,
      page: () => const _PlaceholderPage(
        title: 'Profile',
        icon: Icons.person_outline_rounded,
      ),
    ),
  ];
}

// ======================================================
// PLACEHOLDER PAGE
// ======================================================

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
      backgroundColor: AppColors.hexFF04111F,
      appBar: AppBar(
        backgroundColor: AppColors.hexFF04111F,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.white,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Icon(
          icon,
          color: AppColors.hexFF20DFFF,
          size: 60,
        ),
      ),
    );
  }
}
