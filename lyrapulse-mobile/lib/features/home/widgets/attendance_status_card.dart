import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class AttendanceStatusCard extends StatelessWidget {
  final String status;
  final String currentTime;
  final String currentDate;
  final String checkInTime;
  final String checkOutTime;
  final String workingHours;
  final bool isCheckedIn;

  const AttendanceStatusCard({
    super.key,
    required this.status,
    required this.currentTime,
    required this.currentDate,
    required this.checkInTime,
    required this.checkOutTime,
    required this.workingHours,
    required this.isCheckedIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        18,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TODAY',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    currentDate,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Present badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      status,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6FF0B2),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Current time
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              currentTime,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Attendance details
          Row(
            children: [
              Expanded(
                child: _AttendanceInfo(
                  title: 'CHECK IN',
                  value: checkInTime,
                ),
              ),

              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: 0.28),
              ),

              Expanded(
                child: _AttendanceInfo(
                  title: 'CHECK OUT',
                  value: checkOutTime,
                ),
              ),

              Container(
                width: 1,
                height: 48,
                color: Colors.white.withValues(alpha: 0.28),
              ),

              Expanded(
                child: _AttendanceInfo(
                  title: 'HOURS',
                  value: workingHours,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttendanceInfo extends StatelessWidget {
  final String title;
  final String value;

  const _AttendanceInfo({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}