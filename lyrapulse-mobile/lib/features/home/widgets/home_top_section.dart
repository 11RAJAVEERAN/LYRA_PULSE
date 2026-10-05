import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class HomeTopSection extends StatelessWidget {
  final String employeeName;
  final String designation;
  final String employeeId;

  final String status;
  final String currentTime;
  final String currentDate;
  final String checkInTime;
  final String checkOutTime;
  final String workingHours;

  const HomeTopSection({
    super.key,
    required this.employeeName,
    required this.designation,
    required this.employeeId,
    required this.status,
    required this.currentTime,
    required this.currentDate,
    required this.checkInTime,
    required this.checkOutTime,
    required this.workingHours,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.secondary,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // ==============================
          // EMPLOYEE HEADER
          // ==============================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primary,
                  size: 27,
                ),
              ),

              const SizedBox(width: 10),

              // Employee details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      employeeId,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Notification
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),

                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5C5C),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==============================
          // ATTENDANCE CARD
          // ==============================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // TODAY + PRESENT
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TODAY',
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            currentDate,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),


// present container


                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),

                          const SizedBox(width: 5),

                          Text(
                            status,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // CURRENT TIME
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    currentTime,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.3,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.13),
                ),

                const SizedBox(height: 10),

                // ATTENDANCE VALUES
                Row(
                  children: [
                    Expanded(
                      child: _AttendanceValue(
                        icon: Icons.login_rounded,
                        title: 'CHECK IN',
                        value: checkInTime,
                      ),
                    ),

                    const _Divider(),

                    Expanded(
                      child: _AttendanceValue(
                        icon: Icons.logout_rounded,
                        title: 'CHECK OUT',
                        value: checkOutTime,
                      ),
                    ),

                    const _Divider(),

                    Expanded(
                      child: _AttendanceValue(
                        icon: Icons.access_time_rounded,
                        title: 'HOURS',
                        value: workingHours,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ATTENDANCE VALUE
// ==========================================

class _AttendanceValue extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _AttendanceValue({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.65),
          size: 16,
        ),

        const SizedBox(height: 5),

        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// DIVIDER
// ==========================================

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 38,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}