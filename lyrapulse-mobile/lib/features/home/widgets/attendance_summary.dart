import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class AttendanceSummary extends StatelessWidget {
  final int present;
  final int absent;
  final int late;
  final int leave;

  const AttendanceSummary({
    super.key,
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        24,
        16,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'August Summary',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ],
          ),

          const SizedBox(height:5),

          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  value: present,
                  label: 'Present',
                  color: AppColors.success,
                  background:
                      const Color(0xFFEAF9F2),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _SummaryItem(
                  value: absent,
                  label: 'Absent',
                  color: AppColors.error,
                  background:
                      const Color(0xFFFFEEEE),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _SummaryItem(
                  value: late,
                  label: 'Late',
                  color: AppColors.warning,
                  background:
                      const Color(0xFFFFF6E2),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _SummaryItem(
                  value: leave,
                  label: 'Leave',
                  color: AppColors.secondary,
                  background:
                      const Color(0xFFF1EDFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final Color background;

  const _SummaryItem({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}