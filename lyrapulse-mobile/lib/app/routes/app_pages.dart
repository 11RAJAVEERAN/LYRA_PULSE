
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../features/home/bindings/home_binding.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/otp_screen.dart';

import '../../features/home/views/home_screen.dart';
import '../../features/splash/views/splash_screen.dart';

import '../../features/attendance/views/location_verification_screen.dart';

import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/bindings/profile_binding.dart';

import '../../features/permission/permission_screen.dart';
import '../../features/permission/views/permission_submitted_screen.dart';
import '../../features/permission/views/permission_return_screen.dart';

import 'package:lyrapulse_mobile/features/leave/bindings/leave_binding.dart';
import 'package:lyrapulse_mobile/features/leave/views/leave_screen.dart';
import 'package:lyrapulse_mobile/features/leave/views/apply_leave_screen.dart';

import 'app_routes.dart';
import 'app_back_handler.dart';
import '../theme/app_colors.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = [
    // SPLASH
    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashScreen(),
    ),

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
    // HomeScreen has its own back and exit confirmation handling.
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),

    // LOCATION VERIFICATION
    GetPage(
      name: AppRoutes.locationVerification,
      page: () => const AppBackHandler(
        child: LocationVerificationScreen(
          isCheckOut: false,
        ),
      ),
    ),

    // PERMISSION
    GetPage(
      name: AppRoutes.permissionStart,
      page: () => const AppBackHandler(
        child: PermissionScreen(),
      ),
    ),

    GetPage(
      name: AppRoutes.permissionSubmitted,
      page: () => const AppBackHandler(
        child: PermissionSubmittedScreen(),
      ),
    ),

    GetPage(
      name: AppRoutes.permissionReturn,
      page: () => const AppBackHandler(
        child: PermissionReturnScreen(),
      ),
    ),

    // ATTENDANCE
    GetPage(
      name: AppRoutes.attendance,
      page: () => const AppBackHandler(
        child: _PlaceholderPage(
          title: 'Attendance',
          icon: Icons.access_time_rounded,
        ),
      ),
    ),

    // LEAVE
    GetPage(
      name: AppRoutes.leave,
      page: () => AppBackHandler(
        child: const LeaveScreen(),
      ),
      binding: LeaveBinding(),
    ),

    GetPage(
      name: AppRoutes.applyLeave,
      page: () => AppBackHandler(
        child: const ApplyLeaveScreen(),
      ),
      binding: LeaveBinding(),
    ),

    // PROFILE
    GetPage(
      name: AppRoutes.profile,
      page: () => AppBackHandler(
        child: const ProfileScreen(),
      ),
      binding: ProfileBinding(),
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
      backgroundColor: AppColors.textPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.surface,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: AppColors.surface,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Center(
        child: Icon(
          icon,
          color: AppColors.accent,
          size: 60,
        ),
      ),
    );
  }
}
