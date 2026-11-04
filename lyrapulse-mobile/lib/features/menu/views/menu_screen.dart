
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Menu',
          style: GoogleFonts.inter(
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
            MenuProfileCard(
              employeeName: 'Madhavan',
              employeeId: '118',
              onTap: () {
                Get.toNamed('/profile');
              },
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

MenuSection(
  title: 'Settings',
  children: [
    MenuOptionTile(
      icon: Icons.language_rounded,
      title: 'App Language',
      onTap: controller.openAppLanguage,
    ),
    MenuOptionTile(
      icon: Icons.palette_outlined,
      title: 'App Theme',
      onTap: controller.openAppTheme,
    ),
    MenuOptionTile(
      icon: Icons.system_update_rounded,
      title: 'Check for Updates',
      onTap: controller.checkForUpdates,
    ),
  ],
),
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
    onTap: () {
      Get.defaultDialog(
        title: 'Logout',
        middleText: 'Are you sure you want to logout?',
        textCancel: 'Cancel',
        textConfirm: 'Logout',
        confirmTextColor: AppColors.surface,
        buttonColor: AppColors.error,
        onConfirm: () {
          Get.back();
          controller.logout();
        },
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 17),
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.logout_rounded,
            color: AppColors.error,
            size: 21,
          ),
          SizedBox(width: 10),
          Text(
            'Logout',
            style: GoogleFonts.inter(
              color: AppColors.error,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}
}