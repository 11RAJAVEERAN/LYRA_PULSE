import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class WeeklyAttendance extends StatelessWidget {
  const WeeklyAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    final days = [
      _DayData('M', AppColors.success, false),
      _DayData('T', AppColors.success, false),
      _DayData('W', AppColors.warning, false),
      _DayData('T', AppColors.success, true),
      _DayData('F', AppColors.error, false),
      _DayData('S', AppColors.success, false),
      _DayData('S', Colors.white, false),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        16,
        24,
        8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: days.map((day) {
          return Column(
            children: [
              Text(
                day.label,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 7),

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: day.isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: day.isSelected
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: day.color,
                      shape: BoxShape.circle,
                      border: day.color == Colors.white
                          ? Border.all(
                              color: AppColors.primary,
                              width: 3,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DayData {
  final String label;
  final Color color;
  final bool isSelected;

  const _DayData(
    this.label,
    this.color,
    this.isSelected,
  );
}