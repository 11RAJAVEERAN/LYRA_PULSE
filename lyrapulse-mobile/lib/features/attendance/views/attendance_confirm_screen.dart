import 'dart:async';
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
            padding: const EdgeInsets.fromLTRB(
                AppDimensions.pagePadding, 12, AppDimensions.pagePadding, 20),
            child: Obx(() {
              final action = controller.action.value;
              final path = controller.photoPath.value;
              final verification = controller.verification.value;
              final position = controller.position.value;
              final submitting = controller.isSubmitting.value;
              final error = controller.submitError.value;
              final label = attendanceTitle(action);
              return Column(children: [
                FlowHeader(
                  action: action,
                  step: (controller.locationRequired ? 1 : 0) +
                      (controller.photoRequired ? 1 : 0) +
                      1,
                  totalSteps: (controller.locationRequired ? 1 : 0) +
                      (controller.photoRequired ? 1 : 0) +
                      1,
                  subtitle: 'Review and confirm',
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.cardRadius),
                        child: SizedBox(
                          height: 260,
                          width: double.infinity,
                          child: path == null
                              ? const ColoredBox(
                                  color: AppColors.hover,
                                  child: Center(
                                    child: Icon(Icons.fact_check_rounded,
                                        size: 64, color: AppColors.primaryBlue),
                                  ),
                                )
                              : Image.file(File(path), fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FlowCard(
                        child: Column(children: [
                          _ColorInfoRow(
                            icon: Icons.fingerprint_rounded,
                            label: 'Action',
                            value: label,
                            color: AppColors.primaryBlue,
                          ),
                          if (controller.locationRequired &&
                              verification != null &&
                              verification.branchName.isNotEmpty)
                            _ColorInfoRow(
                              icon: Icons.apartment_rounded,
                              label: 'Branch',
                              value: verification.branchName,
                              color: AppColors.secondary,
                            ),
                          if (controller.locationRequired &&
                              verification != null)
                            _ColorInfoRow(
                              icon: Icons.straighten_rounded,
                              label: 'Distance from branch',
                              value: Formatters.distance(
                                  verification.distanceMeters),
                              color: AppColors.accent,
                            ),
                          if (controller.locationRequired && position != null)
                            _ColorInfoRow(
                              icon: Icons.gps_fixed_rounded,
                              label: 'GPS accuracy',
                              value: '±${position.accuracy.round()} m',
                              color: AppColors.success,
                            ),
                          // Live ticking clock.
                          const _LiveTimeRow(color: AppColors.warning),
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
                if (controller.photoRequired)
                  TextButton.icon(
                    onPressed: submitting ? null : controller.retakePhoto,
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: Text('Retake photo',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textSecondary)),
                  ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}

/// Time row that updates every second. Only this row rebuilds.
class _LiveTimeRow extends StatefulWidget {
  const _LiveTimeRow({required this.color});

  final Color color;

  @override
  State<_LiveTimeRow> createState() => _LiveTimeRowState();
}

class _LiveTimeRowState extends State<_LiveTimeRow> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(DateTime t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final h = hour12.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m:$s $period';
  }

  @override
  Widget build(BuildContext context) {
    return _ColorInfoRow(
      icon: Icons.schedule_rounded,
      label: 'Time',
      value: _format(_now),
      color: widget.color,
    );
  }
}

/// Info row with a colorful rounded icon chip.
class _ColorInfoRow extends StatelessWidget {
  const _ColorInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
     child: Row(
  children: [
    Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: color),
    ),
    const SizedBox(width: 14),
    Expanded(
      child: Text(
        label,
        style: AppTextStyles.bodySmall,
      ),
    ),
    const SizedBox(width: 12),
    Flexible(
      child: Text(
        value,
        textAlign: TextAlign.right,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  ],
),
    );
  }
}