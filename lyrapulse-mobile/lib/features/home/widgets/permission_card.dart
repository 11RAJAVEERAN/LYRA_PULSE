import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    this.isRequested = false,
    this.onPressed,
  });

  final bool isRequested;
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
                  Icons.assignment_outlined,
                  color: Color(0xFF25DDF7),
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PERMISSION',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      isRequested
                          ? 'Permission request submitted'
                          : 'Request attendance permission',
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
                  color: isRequested
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
                        color: isRequested
                            ? const Color(0xFF24E5C0)
                            : const Color(0xFF25DDF7),
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      isRequested ? 'SENT' : 'AVAILABLE',
                      style: GoogleFonts.poppins(
                        color: isRequested
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
          // INFORMATION
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
                  Icons.info_outline_rounded,
                  color: Color(0xFF25DDF7),
                  size: 18,
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: Text(
                    isRequested
                        ? 'Your permission request is waiting for approval.'
                        : 'Need permission? Submit a request to your manager.',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8EA6B8),
                      fontSize: 9,
                      height: 1.45,
                    ),
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
              onPressed: isRequested ? null : onPressed,
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
                    isRequested
                        ? Icons.check_circle_rounded
                        : Icons.send_rounded,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    isRequested
                        ? 'Request Submitted'
                        : 'Request Permission',
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