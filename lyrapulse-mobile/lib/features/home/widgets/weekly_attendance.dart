import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class WeeklyAttendance extends StatelessWidget {
  const WeeklyAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Monday = 1 ... Sunday = 7
    final currentDayIndex = now.weekday - 1;

    // Monday -> M
    // Tuesday -> T
    // Wednesday -> W
    // Thursday -> T
    // Friday -> F
    // Saturday -> S
    // Sunday -> S
    final days = [
      ('M', AppColors.success),
      ('T', AppColors.success),
      ('W', AppColors.warning),
      ('T', AppColors.success),
      ('F', AppColors.error),
      ('S', AppColors.success),
      ('S', AppColors.border),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          days.length,
          (index) {
            final day = days[index];

            // Current day automatically selected
            final isToday = index == currentDayIndex;

            return Column(
              children: [
                Text(
                  day.$1,
                  style: GoogleFonts.inter(
                    color: isToday
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isToday
                        ? AppColors.primary
                            .withValues(alpha: 0.10)
                        : AppColors.surface,
                    borderRadius:
                        BorderRadius.circular(13),
                    border: Border.all(
                      color: isToday
                          ? AppColors.primary
                          : AppColors.border,
                      width: isToday ? 1.5 : 1,
                    ),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: AppColors.primary
                                  .withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Container(
                      width: isToday ? 13 : 11,
                      height: isToday ? 13 : 11,
                      decoration: BoxDecoration(
                        color: day.$2,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // TODAY label
                if (isToday) ...[
                  const SizedBox(height: 4),
                  Text(
                    'TODAY',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}