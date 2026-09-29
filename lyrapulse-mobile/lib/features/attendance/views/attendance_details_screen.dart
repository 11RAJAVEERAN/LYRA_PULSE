import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceDetailsScreen extends StatelessWidget {
  const AttendanceDetailsScreen({
    super.key,
    required this.date,
    required this.day,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    this.employeeName = 'Employee',
    this.imageUrl = '',
  });

  final String date;
  final String day;
  final String checkIn;
  final String checkOut;
  final String status;
  final String employeeName;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -180,
              right: -150,
              child: _glow(
                390,
                const Color(0xFF087BFF),
              ),
            ),

            Positioned(
              bottom: -220,
              left: -170,
              child: _glow(
                420,
                const Color(0xFF00D9FF),
              ),
            ),

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      _backButton(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Attendance Details',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // EMPLOYEE PHOTO
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 126,
                          height: 126,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF087BFF),
                                Color(0xFF20DDF7),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF20DDF7)
                                    .withOpacity(0.20),
                                blurRadius: 25,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return _defaultPhoto();
                                    },
                                  )
                                : _defaultPhoto(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Text(
                          employeeName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Employee',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF718AA0),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // DETAILS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xCC071A2D),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF16435F),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailLabel('DATE'),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            _detailIcon(
                              Icons.calendar_today_rounded,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _formattedDate(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Divider(
                          color: Color(0xFF16384F),
                          height: 1,
                        ),

                        const SizedBox(height: 24),

                        // CHECK IN / CHECK OUT
                        Row(
                          children: [
                            Expanded(
                              child: _timeDetail(
                                icon: Icons.login_rounded,
                                title: 'CHECK IN',
                                value: checkIn,
                              ),
                            ),

                            Container(
                              width: 1,
                              height: 65,
                              color: const Color(0xFF19425A),
                            ),

                            Expanded(
                              child: _timeDetail(
                                icon: Icons.logout_rounded,
                                title: 'CHECK OUT',
                                value: checkOut,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Divider(
                          color: Color(0xFF16384F),
                          height: 1,
                        ),

                        const SizedBox(height: 24),

                        // WORKING HOURS
                        _detailLabel(
                          'TOTAL WORKING HOURS',
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            _detailIcon(
                              Icons.timer_outlined,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _calculateWorkingHours(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Divider(
                          color: Color(0xFF16384F),
                          height: 1,
                        ),

                        const SizedBox(height: 24),

                        // STATUS
                        _detailLabel('STATUS'),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor()
                                .withOpacity(0.10),
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: _statusColor()
                                  .withOpacity(0.30),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _statusColor(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status,
                                style: GoogleFonts.poppins(
                                  color: _statusColor(),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: Text(
                      'LYRA PULSE',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF38566D),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // DEFAULT PHOTO
  // ===============================================================

  Widget _defaultPhoto() {
    return Container(
      color: const Color(0xFF0A2941),
      child: const Icon(
        Icons.person_rounded,
        color: Color(0xFF25DDF7),
        size: 55,
      ),
    );
  }

  // ===============================================================
  // BACK BUTTON
  // ===============================================================

  Widget _backButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: Get.back,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0A2136),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF194663),
            ),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // DETAIL LABEL
  // ===============================================================

  Widget _detailLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: const Color(0xFF718AA0),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }

  // ===============================================================
  // DETAIL ICON
  // ===============================================================

  Widget _detailIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF0A2941),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF25DDF7),
        size: 20,
      ),
    );
  }

  // ===============================================================
  // TIME DETAIL
  // ===============================================================

  Widget _timeDetail({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF25DDF7),
          size: 21,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            color: const Color(0xFF718AA0),
            fontSize: 8,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ===============================================================
  // DATE
  // ===============================================================

  String _formattedDate() {
    return '$date September 2026';
  }

  // ===============================================================
  // WORKING HOURS
  // ===============================================================

  String _calculateWorkingHours() {
    if (checkIn == '--:--' || checkOut == '--:--') {
      return '--h --m';
    }

    try {
      final inParts = checkIn
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim()
          .split(':');

      final outParts = checkOut
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim()
          .split(':');

      int inHour = int.parse(inParts[0]);
      int inMinute = int.parse(inParts[1]);

      int outHour = int.parse(outParts[0]);
      int outMinute = int.parse(outParts[1]);

      if (checkIn.contains('PM') && inHour != 12) {
        inHour += 12;
      }

      if (checkIn.contains('AM') && inHour == 12) {
        inHour = 0;
      }

      if (checkOut.contains('PM') && outHour != 12) {
        outHour += 12;
      }

      if (checkOut.contains('AM') && outHour == 12) {
        outHour = 0;
      }

      final startMinutes =
          (inHour * 60) + inMinute;

      final endMinutes =
          (outHour * 60) + outMinute;

      int difference =
          endMinutes - startMinutes;

      if (difference < 0) {
        difference += 24 * 60;
      }

      final hours = difference ~/ 60;
      final minutes = difference % 60;

      return '${hours.toString().padLeft(2, '0')}h '
          '${minutes.toString().padLeft(2, '0')}m';
    } catch (_) {
      return '--h --m';
    }
  }

  // ===============================================================
  // STATUS COLOR
  // ===============================================================

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'present':
        return const Color(0xFF25DDF7);

      case 'absent':
        return const Color(0xFFFF6B7A);

      case 'leave':
        return const Color(0xFFFFC857);

      default:
        return const Color(0xFF25DDF7);
    }
  }

  // ===============================================================
  // GLOW
  // ===============================================================

  Widget _glow(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.11),
            color.withOpacity(0.025),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}