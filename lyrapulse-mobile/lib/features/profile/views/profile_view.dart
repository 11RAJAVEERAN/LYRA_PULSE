import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
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
        return RefreshIndicator(
          onRefresh: controller.refreshProfile,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    const SizedBox(height: 16),
                    if (controller.refreshError.value != null)
                      _ProfileError(
                        message: controller.refreshError.value!,
                        onRetry: controller.refreshProfile,
                      ),
                    if (employee == null)
                      _ProfileUnavailable(
                        loading: controller.isRefreshing.value,
                        onRetry: controller.refreshProfile,
                      )
                    else
                      ProfileContent(employee: employee),
                    const SizedBox(height: 20),
                    AppButton(
                      label: controller.isLoggingOut.value
                          ? 'Signing out…'
                          : 'Log out',
                      onPressed: controller.isLoggingOut.value
                          ? null
                          : controller.logout,
                      icon: Icons.logout_rounded,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ProfileUnavailable extends StatelessWidget {
  const _ProfileUnavailable({
    required this.loading,
    required this.onRetry,
  });

  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.person_off_outlined,
                size: 32, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              'Employee profile is unavailable.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            TextButton(
              onPressed: loading ? null : onRetry,
              child: Text(loading ? 'Refreshing…' : 'Try again'),
            ),
          ],
        ),
      );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: AppColors.errorBackground,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_outlined,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.errorDark,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
}
