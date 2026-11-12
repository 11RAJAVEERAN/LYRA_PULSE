import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class AttendanceRecordsScreen extends StatelessWidget {
  const AttendanceRecordsScreen({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceMuted,
        elevation: 0,
        surfaceTintColor: AppColors.surface,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          'Attendance Records',
          style: GoogleFonts.inter(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubtitle(),
              const SizedBox(height: 18),
              _buildMonthlySummary(),
              const SizedBox(height: 22),
              _buildFilterHeader(),
              const SizedBox(height: 14),
              _buildAttendanceCard(
                date: '06',
                day: 'Monday',
                month: 'October 2026',
                status: 'Present',
                statusColor: AppColors.success,
                statusBackground: AppColors.successBackground,
                checkIn: '09:28 AM',
                checkOut: '06:12 PM',
                workingHours: '08h 44m',
                locationVerified: true,
                faceVerified: true,
              ),
              const SizedBox(height: 13),
              _buildAttendanceCard(
                date: '03',
                day: 'Friday',
                month: 'October 2026',
                status: 'Late',
                statusColor: AppColors.warning,
                statusBackground: AppColors.warningBackground,
                checkIn: '09:47 AM',
                checkOut: '06:15 PM',
                workingHours: '08h 28m',
                locationVerified: true,
                faceVerified: true,
              ),
              const SizedBox(height: 13),
              _buildAttendanceCard(
                date: '02',
                day: 'Thursday',
                month: 'October 2026',
                status: 'Absent',
                statusColor: AppColors.error,
                statusBackground: AppColors.errorBackground,
                checkIn: '--:--',
                checkOut: '--:--',
                workingHours: '--',
                locationVerified: false,
                faceVerified: false,
              ),
              const SizedBox(height: 13),
              _buildAttendanceCard(
                date: '01',
                day: 'Wednesday',
                month: 'October 2026',
                status: 'Present',
                statusColor: AppColors.success,
                statusBackground: AppColors.successBackground,
                checkIn: '09:31 AM',
                checkOut: '06:05 PM',
                workingHours: '08h 34m',
                locationVerified: true,
                faceVerified: true,
              ),
              const SizedBox(height: 24),
              _buildInfoMessage(),
              const SizedBox(height: 22),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // SUBTITLE
  // ==========================================================

  Widget _buildSubtitle() {
    return Text(
      'View your complete attendance history',
      style: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // ==========================================================
  // MONTHLY SUMMARY
  // ==========================================================

  Widget _buildMonthlySummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primaryBlue,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'October 2026',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Monthly attendance summary',
                      style: GoogleFonts.inter(
                        color: AppColors.borderStrong,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '88%',
                  style: GoogleFonts.inter(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(
            height: 1,
            color: AppColors.border,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  value: '22',
                  label: 'Present',
                  color: AppColors.success,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _summaryItem(
                  value: '2',
                  label: 'Absent',
                  color: AppColors.error,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _summaryItem(
                  value: '3',
                  label: 'Late',
                  color: AppColors.warning,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _summaryItem(
                  value: '1',
                  label: 'Leave',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SUMMARY ITEM
  // ==========================================================

  Widget _summaryItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // VERTICAL DIVIDER
  // ==========================================================

  Widget _verticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: AppColors.border,
    );
  }

  // ==========================================================
  // FILTER HEADER
  // ==========================================================

  Widget _buildFilterHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance History',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Your daily attendance records',
                style: GoogleFonts.inter(
                  color: AppColors.borderStrong,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                color: AppColors.primaryBlue,
                size: 17,
              ),
              const SizedBox(width: 5),
              Text(
                'Filter',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // ATTENDANCE CARD
  // ==========================================================

  Widget _buildAttendanceCard({
    required String date,
    required String day,
    required String month,
    required String status,
    required Color statusColor,
    required Color statusBackground,
    required String checkIn,
    required String checkOut,
    required String workingHours,
    required bool locationVerified,
    required bool faceVerified,
  }) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          _showAttendanceDetails(
            date: date,
            day: day,
            month: month,
            status: status,
            statusColor: statusColor,
            checkIn: checkIn,
            checkOut: checkOut,
            workingHours: workingHours,
            locationVerified: locationVerified,
            faceVerified: faceVerified,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.025),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // DATE
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: AppColors.hover,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date,
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 19,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'OCT',
                          style: GoogleFonts.inter(
                            color: AppColors.borderStrong,
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          month,
                          style: GoogleFonts.inter(
                            color: AppColors.borderStrong,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 6,
                          width: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          status,
                          style: GoogleFonts.inter(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Divider(
                height: 1,
                color: AppColors.border,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _timeItem(
                      icon: Icons.login_rounded,
                      label: 'Check In',
                      value: checkIn,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: AppColors.border,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 15,
                      ),
                      child: _timeItem(
                        icon: Icons.logout_rounded,
                        label: 'Check Out',
                        value: checkOut,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Working Hours',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    workingHours,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (locationVerified || faceVerified) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (locationVerified)
                      _verificationBadge(
                        icon: Icons.location_on_rounded,
                        label: 'Location Verified',
                        color: AppColors.success,
                      ),
                    if (locationVerified && faceVerified)
                      const SizedBox(width: 7),
                    if (faceVerified)
                      _verificationBadge(
                        icon: Icons.face_rounded,
                        label: 'Face Verified',
                        color: AppColors.primaryBlue,
                      ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.borderStrong,
                      size: 13,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // TIME ITEM
  // ==========================================================

  Widget _timeItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          height: 31,
          width: 31,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.borderStrong,
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // VERIFICATION BADGE
  // ==========================================================

  Widget _verificationBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ATTENDANCE DETAILS
  // ==========================================================

  void _showAttendanceDetails({
    required String date,
    required String day,
    required String month,
    required String status,
    required Color statusColor,
    required String checkIn,
    required String checkOut,
    required String workingHours,
    required bool locationVerified,
    required bool faceVerified,
  }) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          28,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: AppColors.hover,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        date,
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          month,
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(
                icon: Icons.login_rounded,
                title: 'Check In',
                value: checkIn,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 12),
              _detailRow(
                icon: Icons.logout_rounded,
                title: 'Check Out',
                value: checkOut,
                color: AppColors.secondary,
              ),
              const SizedBox(height: 12),
              _detailRow(
                icon: Icons.schedule_rounded,
                title: 'Working Hours',
                value: workingHours,
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              _detailRow(
                icon: Icons.location_on_rounded,
                title: 'Location Verification',
                value: locationVerified ? 'Verified' : 'Not Available',
                color: locationVerified ? AppColors.success : AppColors.error,
              ),
              const SizedBox(height: 12),
              _detailRow(
                icon: Icons.face_rounded,
                title: 'Face Verification',
                value: faceVerified ? 'Verified' : 'Not Available',
                color: faceVerified ? AppColors.success : AppColors.error,
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget _detailRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // INFO MESSAGE
  // ==========================================================

  Widget _buildInfoMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppColors.primaryBlue,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Attendance records are securely maintained and can be verified using location and face verification.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 9,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // FOOTER
  // ==========================================================

  Widget _buildFooter() {
    return Center(
      child: Text(
        'LYRA PULSE  •  CONNECT · TRACK · GROW',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: AppColors.borderStrong,
          fontSize: 8,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
