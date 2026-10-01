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
        22,
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
                  color: AppColors.primaryDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                'View All',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(width: 3),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  value: present,
                  label: 'Present',
                  icon: Icons.person_rounded,
                  color: AppColors.success,
                  background: const Color(0xFFE5F9F1),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _SummaryCard(
                  value: absent,
                  label: 'Absent',
                  icon: Icons.person_off_rounded,
                  color: AppColors.error,
                  background: const Color(0xFFFFE9E9),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _SummaryCard(
                  value: late,
                  label: 'Late',
                  icon: Icons.access_time_rounded,
                  color: AppColors.warning,
                  background: const Color(0xFFFFF5DC),
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _SummaryCard(
                  value: leave,
                  label: 'Leave',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.secondary,
                  background: const Color(0xFFF0EBFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 105,
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 15,
              ),

              const SizedBox(width: 3),

              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}