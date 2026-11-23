import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_flow_widgets.dart';

/// Step 1: fresh GPS fix + real `verify-location/` call.
class LocationCheckScreen extends GetView<AttendanceController> {
  const LocationCheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppDimensions.pagePadding, 12, AppDimensions.pagePadding, 20),
          child: Obx(() {
            final action = controller.action.value;
            final status = controller.locationStatus.value;
            final notConfirmed = status == LocationStatus.outside ||
                status == LocationStatus.failed;

            return Column(children: [
              FlowHeader(
                action: action,
                step: 1,
                totalSteps:
                    controller.locationRequired && controller.photoRequired
                        ? 3
                        : 2,
                subtitle: 'Verify your location',
              ),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  child: _StatusCard(controller: controller),
                ),
              ),
              const SizedBox(height: 12),

              // Location confirm aagala na mattum: settings (if needed) + check again.
              if (notConfirmed) ..._recoveryActions(status),

              AppButton(
                label:
                    controller.photoRequired ? 'Continue to photo' : 'Continue',
                icon: controller.photoRequired
                    ? Icons.photo_camera_rounded
                    : Icons.arrow_forward_rounded,
                useGradient: true,
                onPressed: status == LocationStatus.verified
                    ? controller.continueToCamera
                    : null,
              ),
            ]);
          }),
        ),
      ),
    );
  }

  List<Widget> _recoveryActions(LocationStatus status) {
    final type = controller.locationFailure.value;
    final needsSettings = status == LocationStatus.failed &&
        (type == LocationFailureType.serviceDisabled ||
            type == LocationFailureType.deniedForever);

    return [
      if (needsSettings) ...[
        AppButton(
          label: type == LocationFailureType.serviceDisabled
              ? 'Open location settings'
              : 'Open app settings',
          icon: Icons.settings_rounded,
          onPressed: controller.openLocationSettings,
        ),
        const SizedBox(height: 10),
      ],
      OutlinedButton.icon(
        onPressed: controller.verifyLocation,
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: Text(
          'Check location again',
          style: GoogleFonts.inter(),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.inputRadius)),
        ),
      ),
      const SizedBox(height: 10),
    ];
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller});

  final AttendanceController controller;

  // Own Obx: this widget's build runs outside the parent Obx's tracking scope.
  @override
  Widget build(BuildContext context) => Obx(_buildCard);

  Widget _buildCard() {
    final status = controller.locationStatus.value;
    final verification = controller.verification.value;
    final position = controller.position.value;

    late final IconData icon;
    late final Color color;
    late final Color background;
    late final String title;
    late final String body;
    switch (status) {
      case LocationStatus.idle:
      case LocationStatus.checking:
        icon = Icons.my_location_rounded;
        color = AppColors.info;
        background = AppColors.infoBackground;
        title = 'Verifying your location';
        body = 'Getting a precise GPS fix and checking it against your branch…';
      case LocationStatus.verified:
        icon = Icons.verified_rounded;
        color = AppColors.success;
        background = AppColors.successBackground;
        title = 'Location verified';
        body = 'You are within the allowed attendance area.';
      case LocationStatus.outside:
        icon = Icons.wrong_location_rounded;
        color = AppColors.warningDark;
        background = AppColors.warningBackground;
        title = 'Outside attendance area';
        body = controller.locationMessage.value;
      case LocationStatus.failed:
        icon = Icons.location_off_rounded;
        color = AppColors.error;
        background = AppColors.errorBackground;
        title = 'Location unavailable';
        body = controller.locationMessage.value;
    }

    return FlowCard(
      child: Column(children: [
        const SizedBox(height: 6),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: status == LocationStatus.checking ||
                  status == LocationStatus.idle
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child:
                      CircularProgressIndicator(strokeWidth: 3, color: color),
                )
              : Icon(icon, size: 36, color: color),
        ),
        const SizedBox(height: 16),
        Text(title, style: AppTextStyles.title, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(body, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        if (verification != null) ...[
          const SizedBox(height: 18),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          if (verification.branchName.isNotEmpty)
            _ColorInfoRow(
              icon: Icons.apartment_rounded,
              label: 'Branch',
              value: verification.branchName,
              color: AppColors.primaryBlue,
            ),
          _ColorInfoRow(
            icon: Icons.straighten_rounded,
            label: 'Distance from branch',
            value: Formatters.distance(verification.distanceMeters),
            color: AppColors.secondary,
          ),
          _ColorInfoRow(
            icon: Icons.radar_rounded,
            label: 'Allowed radius',
            value: Formatters.distance(
                verification.allowedRadiusMeters.toDouble()),
            color: AppColors.accent,
          ),
        ],
        if (position != null)
          _ColorInfoRow(
            icon: Icons.gps_fixed_rounded,
            label: 'GPS accuracy',
            value: '±${position.accuracy.round()} m',
            color: AppColors.success,
          ),
      ]),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySmall,
            ),
          ),
          const SizedBox(width: 18),
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
