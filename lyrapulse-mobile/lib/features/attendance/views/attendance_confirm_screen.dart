import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_flow_widgets.dart';

/// Step 3: photo preview + confirmation. Nothing is recorded until the server confirms.
class AttendanceConfirmScreen extends GetView<AttendanceController> {
  const AttendanceConfirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Leaving without submitting removes the temporary photo.
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && controller.result.value == null) controller.discardPhoto();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.pagePadding, 12, AppDimensions.pagePadding, 20),
            child: Obx(() {
              final action = controller.action.value;
              final path = controller.photoPath.value;
              final verification = controller.verification.value;
              final position = controller.position.value;
              final submitting = controller.isSubmitting.value;
              final error = controller.submitError.value;
              final label = attendanceTitle(action);
              return Column(children: [
                FlowHeader(action: action, step: 3, subtitle: 'Review and confirm'),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                        child: SizedBox(
                          height: 260,
                          width: double.infinity,
                          child: path == null
                              ? const ColoredBox(color: AppColors.hover)
                              : Image.file(File(path), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FlowCard(
                        child: Column(children: [
                          FlowInfoRow(
                              icon: Icons.fingerprint_rounded, label: 'Action', value: label),
                          if (verification != null && verification.branchName.isNotEmpty)
                            FlowInfoRow(
                                icon: Icons.apartment_rounded,
                                label: 'Branch',
                                value: verification.branchName),
                          if (verification != null)
                            FlowInfoRow(
                                icon: Icons.straighten_rounded,
                                label: 'Distance from branch',
                                value: Formatters.distance(verification.distanceMeters)),
                          if (position != null)
                            FlowInfoRow(
                                icon: Icons.gps_fixed_rounded,
                                label: 'GPS accuracy',
                                value: '±${position.accuracy.round()} m'),
                          const FlowInfoRow(
                              icon: Icons.schedule_rounded,
                              label: 'Time',
                              value: 'Recorded by the server'),
                        ]),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        FlowBanner(message: error),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                AppButton(
                  label: error == null ? 'Confirm $label' : 'Try again',
                  icon: Icons.check_circle_rounded,
                  useGradient: true,
                  loading: submitting,
                  onPressed: submitting ? null : controller.submit,
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: submitting ? null : controller.retakePhoto,
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: Text('Retake photo',
                      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
