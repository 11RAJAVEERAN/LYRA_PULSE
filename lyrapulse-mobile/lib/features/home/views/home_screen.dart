import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../attendance/controllers/attendance_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/views/profile_view.dart';
import '../controllers/home_controller.dart';
import '../widgets/attendance_hero_card.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/home_drawer.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/today_summary_card.dart';
import '../widgets/welcome_header.dart';
import '../widgets/workplace_card.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final attendance = Get.find<AttendanceController>();
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: const HomeDrawer(),
      body: Obx(() {
        if (controller.tabIndex.value == HomeController.profileTab) {
          return const ProfileView();
        }
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: attendance.refreshToday,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppDimensions.pagePadding,
                      18, AppDimensions.pagePadding, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Obx(() => WelcomeHeader(
                            employeeName:
                                auth.employee.value?.name ?? 'Employee',
                            employeeCode:
                                auth.employee.value?.employeeCode ?? '',
                            onAvatarTap: controller.openDrawer,
                            onNotificationTap: () =>
                                controller.comingSoon('Notifications'),
                          )),
                      const SizedBox(height: 20),
                      const AttendanceHeroCard(),
                      const SizedBox(height: 14),
                      const TodaySummaryCard(),
                      const SizedBox(height: 22),
                      Text('Quick Actions', style: AppTextStyles.title),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final textScale =
                              MediaQuery.textScalerOf(context).scale(1);
                          final cardHeight =
                              (76 * textScale).clamp(76.0, 112.0);
                          final cardWidth = (constraints.maxWidth - 10) / 2;
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: cardWidth / cardHeight,
                            children: [
                              QuickActionCard(
                                icon: Icons.description_outlined,
                                title: 'Permission',
                                subtitle: 'Coming soon',
                                isComingSoon: true,
                                color: AppColors.warning,
                                onTap: () =>
                                    controller.comingSoon('Permission'),
                              ),
                              QuickActionCard(
                                icon: Icons.history_rounded,
                                title: 'History',
                                subtitle: 'Attendance',
                                color: AppColors.secondary,
                                onTap: controller.openAttendanceHistory,
                              ),
                              QuickActionCard(
                                icon: Icons.event_busy_rounded,
                                title: 'Leave',
                                subtitle: 'Coming soon',
                                isComingSoon: true,
                                color: AppColors.info,
                                onTap: () => controller.comingSoon('Leave'),
                              ),
                              QuickActionCard(
                                icon: Icons.calendar_month_rounded,
                                title: 'Calendar',
                                subtitle: 'Coming soon',
                                isComingSoon: true,
                                color: AppColors.accent,
                                onTap: () => controller.comingSoon('Calendar'),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 22),
                      Text('Your workplace', style: AppTextStyles.title),
                      const SizedBox(height: 12),
                      const WorkplaceCard(),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: Obx(() => BottomNavBar(
            selectedIndex: controller.tabIndex.value,
            onChanged: controller.onTabSelected,
          )),
    );
  }
}
