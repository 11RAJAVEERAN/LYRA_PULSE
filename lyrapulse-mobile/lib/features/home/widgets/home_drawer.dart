import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/home_controller.dart';

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final home = Get.find<HomeController>();
    final auth = Get.find<AuthController>();

    void soon(String feature) {
      home.closeDrawer();
      home.comingSoon(feature);
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
            ),
            child: Obx(() {
              final employee = auth.employee.value;
              final name = employee?.name ?? '';
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.accent,
                  child: Text(name.isEmpty ? 'E' : name.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.title.copyWith(color: Colors.white)),
                ),
                const SizedBox(height: 14),
                Text(name.isEmpty ? 'Employee' : name,
                    style: AppTextStyles.title.copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                Text(
                  (employee?.employeeCode ?? '').isEmpty ? 'Lyra Pulse employee' : 'Employee ID: ${employee!.employeeCode}',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: .8)),
                ),
                if ((employee?.phoneNumber ?? '').isNotEmpty)
                  Text(Formatters.phone(employee!.phoneNumber),
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withValues(alpha: .8))),
              ]);
            }),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: [
              _Item(icon: Icons.home_rounded, label: 'Home', onTap: () {
                home.closeDrawer();
                home.showHome();
              }),
              _Item(icon: Icons.person_rounded, label: 'Profile', onTap: () {
                home.closeDrawer();
                home.showProfile();
              }),
              _Item(icon: Icons.notifications_rounded, label: 'Notifications', onTap: () => soon('Notifications')),
              _Item(icon: Icons.history_rounded, label: 'Attendance History', onTap: () => soon('Attendance history')),
              _Item(icon: Icons.calendar_month_rounded, label: 'Calendar', onTap: () => soon('Calendar')),
              _Item(icon: Icons.description_rounded, label: 'Permission', onTap: () => soon('Permission')),
              _Item(icon: Icons.event_busy_rounded, label: 'Leave', onTap: () => soon('Leave')),
            ]),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Obx(() => _Item(
                  icon: Icons.logout_rounded,
                  label: auth.isLoggingOut.value ? 'Signing out…' : 'Log out',
                  color: AppColors.error,
                  onTap: auth.isLoggingOut.value ? null : auth.logout,
                )),
          ),
        ]),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: color ?? AppColors.primary, size: 22),
        title: Text(label, style: AppTextStyles.label.copyWith(color: color ?? AppColors.textPrimary)),
      );
}
