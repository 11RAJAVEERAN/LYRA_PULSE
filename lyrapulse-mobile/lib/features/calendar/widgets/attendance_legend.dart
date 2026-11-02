import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class AttendanceLegend extends StatelessWidget {
  const AttendanceLegend({super.key});

  static const items = <_LegendItem>[
    _LegendItem('Today', AppColors.primaryBlue, outlined: true),
    _LegendItem('Present', AppColors.success),
    _LegendItem('Absent', AppColors.error),
    _LegendItem('On Leave', AppColors.secondary),
    _LegendItem('Half Day', AppColors.warning),
    _LegendItem('Week Off', AppColors.textSecondary),
    _LegendItem('Holiday', AppColors.accent),
    _LegendItem('Late', AppColors.warning),
    _LegendItem('Punch Error', AppColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 9,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.outlined ? AppColors.surface : item.color,
                  shape: BoxShape.circle,
                  border: item.outlined
                      ? Border.all(color: item.color, width: 2)
                      : null,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                item.label,
                style:  GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  final bool outlined;

  const _LegendItem(
    this.label,
    this.color, {
    this.outlined = false,
  });
}
