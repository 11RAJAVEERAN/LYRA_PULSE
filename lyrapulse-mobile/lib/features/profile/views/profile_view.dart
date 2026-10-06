import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_content.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProfileController>();
    return SafeArea(
      child: Obx(() {
        final employee = controller.employee;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding,
                24,
                AppDimensions.pagePadding,
                24,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text('My Profile', style: AppTextStyles.headline),
                  const SizedBox(height: 20),
                  if (employee == null)
                    Text('Employee profile is unavailable.', style: AppTextStyles.bodySmall)
                  else
                    ProfileContent(employee: employee),
                  const SizedBox(height: 20),
                  AppButton(
                    label: controller.isLoggingOut.value ? 'Signing out…' : 'Log out',
                    onPressed: controller.isLoggingOut.value ? null : controller.logout,
                    icon: Icons.logout_rounded,
                  ),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }
}