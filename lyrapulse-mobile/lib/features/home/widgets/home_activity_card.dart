
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../../attendance/controllers/attendance_controller.dart';

class HomeActivityCard extends StatelessWidget {
  final AttendanceController attendanceController;
  final DateTime now;

  const HomeActivityCard({
    super.key,
    required this.attendanceController,
    required this.now,
  });

  String _time(DateTime? value) {
    if (value == null) return '--:-- --';

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final entries = <Widget>[];
    final sessions = attendanceController.today.value?.sessions ?? const [];
    for (final session in sessions) {
      final checkIn = session.checkInAt;
      final checkOut = session.checkOutAt;
      if (checkIn != null &&
          checkIn.year == now.year &&
          checkIn.month == now.month &&
          checkIn.day == now.day) {
        entries.add(_activityRow('Punch In', _time(checkIn), true));
      }
      if (checkOut != null &&
          checkOut.year == now.year &&
          checkOut.month == now.month &&
          checkOut.day == now.day) {
        entries.add(_activityRow('Punch Out', _time(checkOut), false));
      }
    }

    if (entries.isEmpty) {
      entries.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 35,
                color: AppColors.textSecondary.withValues(alpha: .6),
              ),
              const SizedBox(height: 10),
              Text(
                'No attendance yet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check in to start your day',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AppColors.border.withValues(alpha: .75),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 17),
            entries[i],
          ],
        ],
      ),
    );
  }

  Widget _buildBreakCard(Duration duration, bool isActive) {
    final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    final label = minutes > 0
        ? '$minutes ${minutes == 1 ? 'Min' : 'Mins'} Break'
        : '$remainingSeconds ${remainingSeconds == 1 ? 'Sec' : 'Secs'} Break';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 0.5,
              color: AppColors.border,
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.infoSurface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.border,
                width: 1.3,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.coffee_rounded,
                  size: 15,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    isActive ? '$label · Ongoing' : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              height: 1.3,
              color: AppColors.border,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityRow(
    String title,
    String subtitle,
    bool isPunchIn,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPunchIn
                ? AppColors.infoSurface
                : AppColors.infoSurface,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPunchIn
                ? Icons.login_rounded
                : Icons.logout_rounded,
            color: isPunchIn
                ? AppColors.surfaceMuted
                : AppColors.surfaceMuted,
            size: 20,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subtitle,
          textAlign: TextAlign.right,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
