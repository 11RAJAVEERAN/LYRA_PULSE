import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../attendance/controllers/attendance_controller.dart';

class HomeWorkingCard extends StatelessWidget {
  final AttendanceController attendanceController;

  const HomeWorkingCard({
    super.key,
    required this.attendanceController,
  });

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: AppColors.surface,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.surface,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              color: AppColors.surface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            AppColors.secondaryDark,
            AppColors.secondaryDark,
            AppColors.secondaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -45,
            top: -85,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface.withValues(alpha: .09),
                  width: 2,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WORKING HOURS',
                style: GoogleFonts.inter(
                  color: AppColors.surface.withValues(alpha: .84),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 7),
              Obx(() {
                final workingTime =
                    attendanceController.formattedWorkingDuration;

                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: workingTime.length >= 5
                              ? workingTime.substring(0, 5)
                              : workingTime,
                          style: GoogleFonts.inter(
                            color: AppColors.surface,
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                        ),
                        if (workingTime.length >= 8) ...[
                          TextSpan(
                            text: ':',
                            style: GoogleFonts.inter(
                              color: AppColors.surface,
                              fontSize: 30,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                          TextSpan(
                            text: workingTime.substring(6, 8),
                            style: GoogleFonts.inter(
                              color: AppColors.surface,
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.surface.withValues(alpha: .9),
                    size: 17,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'Hours worked today',
                    style: GoogleFonts.inter(
                      color: AppColors.surface.withValues(alpha: .85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Obx(
                () => _infoRow(
                  Icons.coffee_rounded,
                  'Total Break Time',
                  attendanceController.breakTimeLabel,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Divider(
                  color: AppColors.surface.withValues(alpha: .25),
                  height: 1,
                ),
              ),
              Obx(
                () => _infoRow(
                  Icons.access_time_rounded,
                  'Shift Timing',
                  attendanceController.shiftTimingLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
