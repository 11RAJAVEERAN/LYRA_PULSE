import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/today_status_card.dart';
import '../widgets/today_summary_card.dart';
import '../widgets/welcome_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding, 22, AppDimensions.pagePadding, 0),
            sliver: SliverList(
                delegate: SliverChildListDelegate([
              Obx(() => WelcomeHeader(
                    employeeName: authController.employee.value?.name ?? 'Employee',
                    employeeCode: authController.employee.value?.employeeCode ?? '',
                    onNotificationTap: () => _comingSoon(),
                  )),
              const SizedBox(height: 26),
              const TodayStatusCard(),
              const SizedBox(height: 28),
              Text('Quick Actions', style: AppTextStyles.title),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.65,
                children: const [
                  QuickActionCard(
                      icon: Icons.login_rounded,
                      title: 'Check In',
                      color: AppColors.primary),
                  QuickActionCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'Attendance',
                      color: AppColors.secondary),
                  QuickActionCard(
                      icon: Icons.description_outlined,
                      title: 'Permission',
                      color: AppColors.warning),
                  QuickActionCard(
                      icon: Icons.logout_rounded,
                      title: 'Check Out',
                      color: AppColors.success),
                ],
              ),
              const SizedBox(height: 28),
              Text('Today\'s Summary', style: AppTextStyles.title),
              const SizedBox(height: 14),
              const TodaySummaryCard(),
              const SizedBox(height: 22),
            ])),
          ),
        ]),
      ),
      bottomNavigationBar: BottomNavBar(
          selectedIndex: selectedIndex,
          onChanged: (index) {
            setState(() => selectedIndex = index);
            if (index != 0) _comingSoon();
          }),
    );
  }

  void _comingSoon() => Get.snackbar('Lyra Pulse', 'Coming Soon',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      backgroundColor: AppColors.primaryDark,
      colorText: Colors.white);
}
