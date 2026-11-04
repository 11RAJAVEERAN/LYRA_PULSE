import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class LeaveEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const LeaveEmptyState({
    super.key,
    this.title = 'No Leave Applications',
    this.subtitle = 'Your leave requests will appear here.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: const BoxDecoration(
                color: AppColors.infoSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 65,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style:  GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style:  GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}