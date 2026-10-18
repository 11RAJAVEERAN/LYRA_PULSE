import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/attendance_model.dart';
import '../controllers/attendance_controller.dart';
import '../widgets/attendance_flow_widgets.dart';

/// Shown only after the backend confirmed the check-in / check-out.
class AttendanceSuccessScreen extends GetView<AttendanceController> {
  const AttendanceSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = controller.result.value;
    final isCheckIn = (result?.action ?? controller.action.value) == AttendanceAction.checkIn;
    final checkIn = result?.checkInAt;
    final checkOut = result?.checkOutAt;
    final worked = (checkIn != null && checkOut != null) ? checkOut.difference(checkIn) : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppDimensions.pagePadding, 24, AppDimensions.pagePadding, 20),
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                        color: AppColors.successBackground, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 52, color: AppColors.success),
                  ),
                  const SizedBox(height: 20),
                  Text(isCheckIn ? 'Checked in' : 'Checked out',
                      style: AppTextStyles.headline, textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(
                    isCheckIn
                        ? 'Your attendance has been recorded. Have a productive day!'
                        : 'Your day is complete. See you tomorrow!',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  FlowCard(
                    child: Column(children: [
                      FlowInfoRow(
                          icon: Icons.calendar_today_rounded,
                          label: 'Date',
                          value: Formatters.dayLabel((checkIn ?? DateTime.now()))),
                      FlowInfoRow(
                          icon: Icons.login_rounded,
                          label: 'Check in',
                          value: Formatters.time12(checkIn)),
                      if (!isCheckIn)
                        FlowInfoRow(
                            icon: Icons.logout_rounded,
                            label: 'Check out',
                            value: Formatters.time12(checkOut)),
                      if (worked != null)
                        FlowInfoRow(
                            icon: Icons.timer_outlined,
                            label: 'Total hours',
                            value: Formatters.durationShort(worked)),
                      if (result?.distanceMeters != null)
                        FlowInfoRow(
                            icon: Icons.verified_rounded,
                            label: 'Distance from branch',
                            value: Formatters.distance(result!.distanceMeters!)),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Back to Home',
              icon: Icons.home_rounded,
              useGradient: true,
              onPressed: Get.back,
            ),
          ]),
        ),
      ),
    );
  }
}
