import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceRecordsScreen extends StatelessWidget {
  const AttendanceRecordsScreen({super.key});

  static const Color navy = Color(0xFF19356C);
  static const Color blue = Color(0xFF3978E8);
  static const Color green = Color(0xFF18A66A);
  static const Color orange = Color(0xFFF39A35);
  static const Color red = Color(0xFFE94B60);
  static const Color purple = Color(0xFF6254E8);

  static const Color background = Color(0xFFF7FAFE);
  static const Color border = Color(0xFFE3EAF3);
  static const Color primaryText = Color(0xFF172B4D);
  static const Color secondaryText = Color(0xFF65758B);
  static const Color lightText = Color(0xFF8A99AA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: navy,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          'Attendance Records',
          style: GoogleFonts.poppins(
            color: navy,
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
                statusColor: green,
                statusBackground: const Color(0xFFE5F8F0),
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
                statusColor: orange,
                statusBackground: const Color(0xFFFFF1DF),
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
                statusColor: red,
                statusBackground: const Color(0xFFFFE9ED),
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
                statusColor: green,
                statusBackground: const Color(0xFFE5F8F0),
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
      style: GoogleFonts.poppins(
        color: secondaryText,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.035),
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
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: blue,
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
                      style: GoogleFonts.poppins(
                        color: primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Monthly attendance summary',
                      style: GoogleFonts.poppins(
                        color: lightText,
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
                  color: const Color(0xFFF0F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '88%',
                  style: GoogleFonts.poppins(
                    color: purple,
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
            color: Color(0xFFEDF0F5),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _summaryItem(
                  value: '22',
                  label: 'Present',
                  color: green,
                ),
              ),

              _verticalDivider(),

              Expanded(
                child: _summaryItem(
                  value: '2',
                  label: 'Absent',
                  color: red,
                ),
              ),

              _verticalDivider(),

              Expanded(
                child: _summaryItem(
                  value: '3',
                  label: 'Late',
                  color: orange,
                ),
              ),

              _verticalDivider(),

              Expanded(
                child: _summaryItem(
                  value: '1',
                  label: 'Leave',
                  color: purple,
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
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: secondaryText,
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
      color: const Color(0xFFE9EDF4),
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
                style: GoogleFonts.poppins(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Your daily attendance records',
                style: GoogleFonts.poppins(
                  color: lightText,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: border,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.filter_list_rounded,
                color: blue,
                size: 17,
              ),
              const SizedBox(width: 5),
              Text(
                'Filter',
                style: GoogleFonts.poppins(
                  color: navy,
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
      color: Colors.white,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: border,
            ),
            boxShadow: [
              BoxShadow(
                color: navy.withValues(alpha: 0.025),
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
                      color: const Color(0xFFF1F4FA),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          date,
                          style: GoogleFonts.poppins(
                            color: navy,
                            fontSize: 19,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'OCT',
                          style: GoogleFonts.poppins(
                            color: lightText,
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
                          style: GoogleFonts.poppins(
                            color: primaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 2),

                        Text(
                          month,
                          style: GoogleFonts.poppins(
                            color: lightText,
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
                          style: GoogleFonts.poppins(
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
                color: Color(0xFFEDF0F5),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _timeItem(
                      icon: Icons.login_rounded,
                      label: 'Check In',
                      value: checkIn,
                      color: blue,
                    ),
                  ),

                  Container(
                    height: 40,
                    width: 1,
                    color: const Color(0xFFE9EDF4),
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
                        color: purple,
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
                    color: green,
                    size: 16,
                  ),

                  const SizedBox(width: 6),

                  Text(
                    'Working Hours',
                    style: GoogleFonts.poppins(
                      color: secondaryText,
                      fontSize: 9,
                    ),
                  ),

                  const Spacer(),

                  Text(
                    workingHours,
                    style: GoogleFonts.poppins(
                      color: primaryText,
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
                        color: green,
                      ),

                    if (locationVerified && faceVerified)
                      const SizedBox(width: 7),

                    if (faceVerified)
                      _verificationBadge(
                        icon: Icons.face_rounded,
                        label: 'Face Verified',
                        color: blue,
                      ),

                    const Spacer(),

                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: lightText,
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
                style: GoogleFonts.poppins(
                  color: lightText,
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: primaryText,
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
            style: GoogleFonts.poppins(
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
          color: Colors.white,
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
                  color: const Color(0xFFDDE3EC),
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
                      color: const Color(0xFFF1F4FA),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        date,
                        style: GoogleFonts.poppins(
                          color: navy,
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
                          style: GoogleFonts.poppins(
                            color: navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          month,
                          style: GoogleFonts.poppins(
                            color: secondaryText,
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
                      style: GoogleFonts.poppins(
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
                color: blue,
              ),

              const SizedBox(height: 12),

              _detailRow(
                icon: Icons.logout_rounded,
                title: 'Check Out',
                value: checkOut,
                color: purple,
              ),

              const SizedBox(height: 12),

              _detailRow(
                icon: Icons.schedule_rounded,
                title: 'Working Hours',
                value: workingHours,
                color: green,
              ),

              const SizedBox(height: 12),

              _detailRow(
                icon: Icons.location_on_rounded,
                title: 'Location Verification',
                value: locationVerified
                    ? 'Verified'
                    : 'Not Available',
                color: locationVerified ? green : red,
              ),

              const SizedBox(height: 12),

              _detailRow(
                icon: Icons.face_rounded,
                title: 'Face Verification',
                value: faceVerified
                    ? 'Verified'
                    : 'Not Available',
                color: faceVerified ? green : red,
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
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
        color: const Color(0xFFF8FAFD),
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
              style: GoogleFonts.poppins(
                color: secondaryText,
                fontSize: 10,
              ),
            ),
          ),

          Text(
            value,
            style: GoogleFonts.poppins(
              color: primaryText,
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
        color: const Color(0xFFEEF5FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFDCE9FF),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: blue,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Attendance records are securely maintained and can be verified using location and face verification.',
              style: GoogleFonts.poppins(
                color: secondaryText,
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
        style: GoogleFonts.poppins(
          color: lightText,
          fontSize: 8,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}