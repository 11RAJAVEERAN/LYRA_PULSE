
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_tab_bar.dart';
import '../widgets/profile_content.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Refresh profile',
              onPressed: controller.isRefreshing.value
                  ? null
                  : controller.refreshProfile,
              icon: controller.isRefreshing.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.primary,
                    ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // Profile Header
          _profileHeader(),

          // API Error
          Obx(() {
            final error = controller.refreshError.value;

            if (error == null) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Material(
                color: AppColors.errorBackground,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          error,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: controller.refreshProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 22),

          // Profile Tabs
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: ProfileTabBar(),
          ),

          const SizedBox(height: 12),

          // Scrollable Profile Content
          const Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 20),
              child: ProfileContent(),
            ),
          ),
        ],
      ),
    );
  }



  Widget _profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secondaryDark,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          const ProfileAvatar(),

          // const SizedBox(height: 16),

          // Obx(
          //   () => Text(
          //     controller.fullName.value,
          //     textAlign: TextAlign.center,
          //     style: GoogleFonts.inter(
          //       fontSize: 22,
          //       fontWeight: FontWeight.w700,
          //       color: AppColors.surface,
          //     ),
          //   ),
          // ),

          // const SizedBox(height: 6),

          // Obx(
          //   () => Text(
          //     'Employee ID: ${controller.employeeId.value}',
          //     style: GoogleFonts.inter(
          //       fontSize: 13,
          //       color: AppColors.surface,
          //       fontWeight: FontWeight.w500,
          //     ),
          //   ),
          // ),

          // const SizedBox(height: 14),

          // Obx(
          //   () => Container(
          //     padding: const EdgeInsets.symmetric(
          //       horizontal: 15,
          //       vertical: 7,
          //     ),
          //     decoration: BoxDecoration(
          //       color: AppColors.surface.withValues(alpha: 0.14),
          //       borderRadius: BorderRadius.circular(20),
          //       border: Border.all(
          //         color: AppColors.surface,
          //       ),
          //     ),
          //     child: Text(
          //       controller.designation.value,
          //       style: GoogleFonts.inter(
          //         color: AppColors.surface,
          //         fontSize: 12,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
