import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        title: const Text(
          'Menu',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF17212D),
          ),
        ),
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 1,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
          children: [
            MenuProfileCard(
              employeeName: 'Madhavan',
              employeeId: '118',
              onTap: controller.openProfile,
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
                  onTap: () => controller.showComingSoon('Mediclaim'),
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
                  onTap: () => controller.showComingSoon('My Documents'),
                ),
                MenuOptionTile(
                  icon: Icons.policy_outlined,
                  title: 'Company Policies',
                  onTap: () =>
                      controller.showComingSoon('Company Policies'),
                ),
              ],
            ),
            const SizedBox(height: 26),

            // Account
            MenuSection(
              title: 'Account',
              children: [
                MenuOptionTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: controller.openNotifications,
                ),
                MenuOptionTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  onTap: controller.logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
