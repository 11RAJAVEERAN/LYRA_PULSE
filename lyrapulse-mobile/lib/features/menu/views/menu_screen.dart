
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/menu_controller.dart';
import '../widgets/menu_item.dart';
import '../widgets/menu_profile_card.dart';
import '../widgets/menu_section.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<LyraMenuController>()
        ? Get.find<LyraMenuController>()
        : Get.put(LyraMenuController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Menu',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
           
          ),
        ),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 1,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
          children: [
            // Profile
            Obx(
              () => MenuProfileCard(
                employeeName: authController.employee.value?.name.isNotEmpty == true
                    ? authController.employee.value!.name
                    : 'Loading profile…',
                employeeId: authController.employee.value?.employeeCode.isNotEmpty == true
                    ? authController.employee.value!.employeeCode
                    : '—',
                onTap: controller.openProfile,
              ),
            ),

            const SizedBox(height: 28),

            // Schedule
            MenuSection(
              title: 'Schedule',
              children: [
                MenuOptionTile(
                  icon: Icons.access_time_rounded,
                  title: 'Upcoming Shifts',
                  onTap: controller.openUpcomingShifts,
                ),
                MenuOptionTile(
                  icon: Icons.celebration_outlined,
                  title: 'Holidays',
                  onTap: controller.openHolidays,
                ),
              ],
            ),

            const SizedBox(height: 26),

            // Pay & Benefits
            MenuSection(
              title: 'Pay & Benefits',
              children: [
                MenuOptionTile(
                  icon: Icons.request_quote_outlined,
                  title: 'Payslips',
                  onTap: controller.openPayslips,
                ),
                MenuOptionTile(
                  icon: Icons.description_outlined,
                  title: 'Loans & Advances',
                  onTap: controller.openLoansAdvances,
                ),
                MenuOptionTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'Arrears',
                  onTap: controller.openArrears,
                ),
                MenuOptionTile(
                  icon: Icons.folder_open_outlined,
                  title: 'Mediclaim',
                  badgeText: 'Coming Soon',
                  onTap: () {
                    controller.showComingSoon('Mediclaim');
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            // Documents
            MenuSection(
              title: 'Documents',
              children: [
                MenuOptionTile(
                  icon: Icons.folder_outlined,
                  title: 'My Documents',
                  onTap: () {
                    controller.showComingSoon('My Documents');
                  },
                ),
                MenuOptionTile(
                  icon: Icons.policy_outlined,
                  title: 'Company Policies',
                  onTap: () {
                    controller.showComingSoon('Company Policies');
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            // Settings
            MenuSection(
              title: 'Settings',
              children: [
                MenuOptionTile(
                  icon: Icons.language_rounded,
                  title: 'App Language',
                  onTap: () {
                    controller.showComingSoon('App Language');
                  },
                ),
                MenuOptionTile(
                  icon: Icons.palette_outlined,
                  title: 'App Theme',
                  onTap: () {
                    controller.showComingSoon('App Theme');
                  },
                ),
                MenuOptionTile(
                  icon: Icons.system_update_rounded,
                  title: 'Check for Updates',
                  onTap: () {
                    controller.showComingSoon('Check for Updates');
                  },
                ),
              ],
            ),

            const SizedBox(height: 26),

            // // Account
            // MenuSection(
            //   title: 'Account',
            //   children: [
            //     MenuOptionTile(
            //       icon: Icons.notifications_none_rounded,
            //       title: 'Notifications',
            //       onTap: controller.openNotifications,
            //     ),
            //   ],
            // ),

            // const SizedBox(height: 22),

            // Logout Button
            _buildLogoutButton(controller),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(LyraMenuController controller) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showLogoutDialog(controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            Text(
              'Logout',
              style: Get.textTheme.titleMedium?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<void> _showLogoutDialog(LyraMenuController controller) {
  return Get.dialog(
    AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Logout',
            style: Get.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to logout from your account?',
            textAlign: TextAlign.center,
            style: Get.textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: Get.back,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  controller.logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}
