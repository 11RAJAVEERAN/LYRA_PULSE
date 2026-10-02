import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class TodayProgressCard extends StatelessWidget {
  final double progress;
  final String workingHours;
  final String checkInTime;
  final String totalShiftHours;

  const TodayProgressCard({
    super.key,
    required this.progress,
    required this.workingHours,
    required this.checkInTime,
    required this.totalShiftHours,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        (progress * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        0,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Today's Progress",
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                '$percentage%',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor:
                  AppColors.accent.withValues(
                alpha: 0.12,
              ),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Text(
                workingHours,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' / $totalShiftHours',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                'Started $checkInTime',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}