import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/attendance_controller.dart';
import '../controllers/camera_capture_controller.dart';
import '../widgets/attendance_flow_widgets.dart';

/// Step 2: live camera (camera only, no gallery) and capture.
class CameraCaptureScreen extends GetView<CameraCaptureController> {
  const CameraCaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attendance = Get.find<AttendanceController>();
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.pagePadding, 12, AppDimensions.pagePadding, 24),
          child: Column(children: [
            Obx(() => FlowHeader(
                  action: attendance.action.value,
                  step: attendance.locationRequired ? 2 : 1,
                  totalSteps: attendance.locationRequired ? 3 : 2,
                  subtitle: 'Take your attendance photo',
                  onDark: true,
                )),
            const SizedBox(height: 18),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
                child: ColoredBox(
                  color: AppColors.primary,
                  child: _Preview(controller: controller),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Obx(() {
              if (controller.errorMessage.value != null) {
                return AppButton(
                  label: 'Try again',
                  icon: Icons.refresh_rounded,
                  onPressed: controller.initCamera,
                );
              }
              final enabled = controller.isReady.value && !controller.isCapturing.value;
              return _ShutterButton(
                busy: controller.isCapturing.value,
                onTap: enabled ? controller.capture : null,
              );
            }),
          ]),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.controller});

  final CameraCaptureController controller;

  // Own Obx: this widget's build runs outside the parent's tracking scope.
  @override
  Widget build(BuildContext context) => Obx(_buildPreview);

  Widget _buildPreview() {
    final error = controller.errorMessage.value;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.no_photography_rounded, color: Colors.white, size: 44),
            const SizedBox(height: 14),
            Text(error,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: Colors.white)),
            const SizedBox(height: 14),
            TextButton(
              onPressed: controller.openSettings,
              child: Text('Open app settings',
                  style: AppTextStyles.label.copyWith(color: AppColors.accent)),
            ),
          ]),
        ),
      );
    }
    final camera = controller.camera.value;
    if (!controller.isReady.value || camera == null || !camera.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    final size = camera.value.previewSize;
    return Stack(fit: StackFit.expand, children: [
      if (size == null)
        CameraPreview(camera)
      else
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            // previewSize is reported in landscape; the UI is portrait.
            width: size.height,
            height: size.width,
            child: CameraPreview(camera),
          ),
        ),
      // Framing guide.
      IgnorePointer(
        child: Center(
          child: Container(
            width: 230,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(150),
              border: Border.all(color: Colors.white.withValues(alpha: .7), width: 2),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: onTap == null && !busy ? .5 : 1,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 74,
            height: 74,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                    )
                  : null,
            ),
          ),
        ),
      );
}
