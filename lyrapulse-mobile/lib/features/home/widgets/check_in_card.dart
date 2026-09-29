import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        color: const Color(0xFF071A2D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF174663),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
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
                  color: const Color(0xFF0B3048),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.login_rounded,
                  color: Color(0xFF24DDF7),
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
                      style: GoogleFonts.poppins(
                        color: Colors.white,
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
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF718CA1),
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
                      ? const Color(0xFF0B3B36)
                      : const Color(0xFF0B2940),
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
                            ? const Color(0xFF24E5C0)
                            : const Color(0xFF25DDF7),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCheckedIn ? 'DONE' : 'READY',
                      style: GoogleFonts.poppins(
                        color: isCheckedIn
                            ? const Color(0xFF24E5C0)
                            : const Color(0xFF25DDF7),
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
              color: const Color(0xFF061727),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF25DDF7),
                  size: 18,
                ),

                const SizedBox(width: 9),

                Text(
                  'Check-in Time',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF718CA1),
                    fontSize: 9,
                  ),
                ),

                const Spacer(),

                Text(
                  checkInTime,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
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
                backgroundColor: const Color(0xFF176DFF),
                disabledBackgroundColor: const Color(0xFF123451),
                foregroundColor: Colors.white,
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
                    style: GoogleFonts.poppins(
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