import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';

class PermissionSubmittedScreen extends StatelessWidget {
  const PermissionSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -170,
              right: -140,
              child: _glow(
                390,
                const Color(0xFF087BFF),
              ),
            ),

            Positioned(
              bottom: -200,
              left: -160,
              child: _glow(
                420,
                const Color(0xFF00D9FF),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                22,
                22,
                22,
                30,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _backButton(),
                  ),

                  const SizedBox(height: 70),

                  _successIcon(),

                  const SizedBox(height: 30),

                  Text(
                    'REQUEST SUBMITTED',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'PERMISSION PENDING',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF20DFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Your permission request has been submitted successfully. Please wait for approval.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF8198AC),
                      fontSize: 11,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 35),

                  _infoCard(),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.offAllNamed(AppRoutes.home);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF176DFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'You will be notified when your request is approved.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF536D83),
                      fontSize: 9,
                    ),
                  ),

                  const SizedBox(height: 35),

                  Text(
                    'LYRA PULSE',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF38566D),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.5,
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

  Widget _successIcon() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF08253A),
        border: Border.all(
          color: const Color(0xFF20DFFF),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20DFFF).withOpacity(0.18),
            blurRadius: 35,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle_outline_rounded,
        color: Color(0xFF20DFFF),
        size: 58,
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xCC071A2D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF16435F),
        ),
      ),
      child: Column(
        children: [
          _row(
            Icons.verified_user_outlined,
            'Permission Status',
            'Pending Approval',
          ),
          const SizedBox(height: 16),
          _row(
            Icons.access_time_rounded,
            'Request Status',
            'Submitted',
          ),
          const SizedBox(height: 16),
          _row(
            Icons.security_rounded,
            'Verification',
            'Required on Return',
          ),
        ],
      ),
    );
  }

  Widget _row(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0A2941),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF25DDF7),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF8EA5B7),
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _backButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0A2136),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1D4564),
        ),
      ),
      child: IconButton(
        onPressed: Get.back,
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 21,
        ),
      ),
    );
  }

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
            color.withOpacity(0.12),
            color.withOpacity(0.03),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}