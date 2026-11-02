import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class LeaveStatusChip extends StatelessWidget {
  final String status;

  const LeaveStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color background;

    switch (status.toLowerCase()) {
      case 'approved':
        color = AppColors.successDark;
        background = AppColors.successBackground;
        break;
      case 'rejected':
        color = AppColors.error;
        background = AppColors.errorBackground;
        break;
      case 'withdrawn':
        color = AppColors.textSecondary;
        background = AppColors.surfaceMuted;
        break;
      default:
        color = AppColors.warningDark;
        background = AppColors.warningBackground;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}