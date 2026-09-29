import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    // ===============================================================
    // INITIAL
    // ===============================================================

    GetPage(
      name: AppRoutes.initial,
      page: () => const SplashScreen(),
    ),

    // ===============================================================
    // SPLASH
    // ===============================================================

    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashScreen(),
    ),

    // ===============================================================
    // AUTH
    // ===============================================================

    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
    ),

    GetPage(
      name: AppRoutes.otp,
      page: () => const OtpScreen(),
    ),

    // ===============================================================
    // HOME
    // ===============================================================

    GetPage(
      name: AppRoutes.home,
      page: () => const HomeScreen(),
    ),

    // ===============================================================
    // ATTENDANCE FLOW
    // ===============================================================

    GetPage(
      name: AppRoutes.locationVerification,
      page: () => const LocationVerificationScreen(),
    ),

    // ===============================================================
    // PERMISSION FLOW
    // ===============================================================

    // Step 1
    // Home
    //   ↓
    // Permission Start

    GetPage(
      name: AppRoutes.permissionStart,
      page: () => const PermissionStartScreen(),
    ),

    // Step 2
    // Permission Start
    //   ↓
    // Permission Submitted

    GetPage(
      name: AppRoutes.permissionSubmitted,
      page: () => const PermissionSubmittedScreen(),
    ),

    // Step 3
    // Permission Submitted
    //   ↓
    // Permission Return
    //   ↓
    // Location + Face Verification

    GetPage(
      name: AppRoutes.permissionReturn,
      page: () => const PermissionReturnScreen(),
    ),

    // ===============================================================
    // BOTTOM NAVIGATION
    // ===============================================================

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

// ===================================================================
// PLACEHOLDER PAGE
// ===================================================================
//
// Temporary screen for bottom navigation.
// Later Attendance / Leave / Profile can be replaced
// with their actual screens.
// ===================================================================

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