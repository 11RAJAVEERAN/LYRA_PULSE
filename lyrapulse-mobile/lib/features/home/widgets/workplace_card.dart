import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';

/// Branch, department and designation of the signed-in employee (from /mobile/me/).
class WorkplaceCard extends StatelessWidget {
  const WorkplaceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Obx(() {
      final employee = auth.employee.value;
      final rows = <(IconData, String, String)>[
        if ((employee?.branch ?? '').isNotEmpty) (Icons.apartment_rounded, 'Branch', employee!.branch!),
        if ((employee?.department ?? '').isNotEmpty) (Icons.groups_rounded, 'Department', employee!.department!),
        if ((employee?.designation ?? '').isNotEmpty) (Icons.badge_rounded, 'Designation', employee!.designation!),
      ];
      if (rows.isEmpty) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Icon(row.$1, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(row.$2, style: AppTextStyles.bodySmall),
                const SizedBox(width: 12),
                Expanded(child: Text(row.$3, textAlign: TextAlign.end, style: AppTextStyles.label, overflow: TextOverflow.ellipsis)),
              ]),
            ),
        ]),
      );
    });
  }
}
