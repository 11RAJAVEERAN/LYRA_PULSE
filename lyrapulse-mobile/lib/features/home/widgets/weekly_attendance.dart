import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class WeeklyAttendance extends StatelessWidget {
  const WeeklyAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    final days = [
      ('M', AppColors.success, false),
      ('T', AppColors.success, false),
      ('W', AppColors.warning, false),
      ('T', AppColors.success, true),
      ('F', AppColors.error, false),
      ('S', AppColors.success, false),
      ('S', AppColors.border, false),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        4,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: List.generate(
          days.length,
          (index) {
            final day = days[index];

            return Column(
              children: [
                Text(
                  day.$1,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: day.$3
                        ? AppColors.primary
                            .withValues(alpha: 0.10)
                        : AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: day.$3
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: day.$2,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}