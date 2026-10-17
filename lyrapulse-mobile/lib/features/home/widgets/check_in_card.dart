import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class CheckInCard extends StatelessWidget {
  const CheckInCard({
    super.key,
    this.isCheckedIn = false,
    this.checkInTime = '--:--',
    this.onPressed,
  });

  final bool isCheckedIn;
  final String checkInTime;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.hexFF071A2D,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.hexFF174663,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================================================
          // HEADER
          // =========================================================

          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.hexFF0B3048,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.login_rounded,
                  color: AppColors.hexFF24DDF7,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHECK IN',
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      isCheckedIn
                          ? 'Attendance marked'
                          : 'Mark your attendance',
                      style: GoogleFonts.inter(
                        color: AppColors.hexFF718CA1,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? AppColors.hexFF0B3B36
                      : AppColors.hexFF0B2940,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCheckedIn
                            ? AppColors.hexFF24E5C0
                            : AppColors.hexFF25DDF7,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCheckedIn ? 'DONE' : 'READY',
                      style: GoogleFonts.inter(
                        color: isCheckedIn
                            ? AppColors.hexFF24E5C0
                            : AppColors.hexFF25DDF7,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // =========================================================
          // TIME
          // =========================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.hexFF061727,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: AppColors.hexFF25DDF7,
                  size: 18,
                ),

                const SizedBox(width: 9),

                Text(
                  'Check-in Time',
                  style: GoogleFonts.inter(
                    color: AppColors.hexFF718CA1,
                    fontSize: 9,
                  ),
                ),

                const Spacer(),

                Text(
                  checkInTime,
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // =========================================================
          // BUTTON
          // =========================================================

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isCheckedIn ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.hexFF176DFF,
                disabledBackgroundColor: AppColors.hexFF123451,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isCheckedIn
                        ? Icons.check_circle_rounded
                        : Icons.login_rounded,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    isCheckedIn
                        ? 'Checked In'
                        : 'Start Check In',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}