import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/routes/app_routes.dart';

class PermissionStartScreen extends StatefulWidget {
  const PermissionStartScreen({super.key});

  @override
  State<PermissionStartScreen> createState() =>
      _PermissionStartScreenState();
}

class _PermissionStartScreenState extends State<PermissionStartScreen> {
  String selectedType = 'Personal Work';
  TimeOfDay? selectedReturnTime;

  final TextEditingController reasonController =
      TextEditingController();

  final List<String> permissionTypes = [
    'Personal Work',
    'Official Work',
    'Emergency',
    'Other',
  ];

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  // ===============================================================
  // SUBMIT PERMISSION
  // ===============================================================

  void _submitPermission() {
    final reason = reasonController.text.trim();

    if (reason.isEmpty) {
      Get.snackbar(
        'Reason Required',
        'Please enter the reason for your permission.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF102A40),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(
          Icons.info_outline_rounded,
          color: Color(0xFF20DFFF),
        ),
      );
      return;
    }

    if (selectedReturnTime == null) {
      Get.snackbar(
        'Return Time Required',
        'Please select your expected return time.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF102A40),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(
          Icons.access_time_rounded,
          color: Color(0xFF20DFFF),
        ),
      );
      return;
    }

    Get.toNamed(AppRoutes.permissionSubmitted);
  }

  // ===============================================================
  // RETURN TIME
  // ===============================================================

  Future<void> _selectReturnTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF20DFFF),
              surface: Color(0xFF071C2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        selectedReturnTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),
      body: SafeArea(
        child: Stack(
          children: [
            // =========================================================
            // BACKGROUND GLOW
            // =========================================================

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

            // =========================================================
            // CONTENT
            // =========================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                22,
                22,
                22,
                35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =====================================================
                  // TOP BAR
                  // =====================================================

                  Row(
                    children: [
                      _backButton(),
                      const Spacer(),
                      _secureBadge(),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // =====================================================
                  // HEADER
                  // =====================================================

                  Center(
                    child: _permissionIcon(),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'REQUEST',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFF20DFFF),
                            Color(0xFF24E5C0),
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        'PERMISSION',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      'Submit your permission request before leaving the office.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF7F96AB),
                        fontSize: 10.5,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // =====================================================
                  // EMPLOYEE CARD
                  // =====================================================

                  _employeeCard(),

                  const SizedBox(height: 20),

                  // =====================================================
                  // PERMISSION TYPE
                  // =====================================================

                  _sectionTitle('PERMISSION TYPE'),

                  const SizedBox(height: 9),

                  _permissionTypeDropdown(),

                  const SizedBox(height: 20),

                  // =====================================================
                  // REASON
                  // =====================================================

                  _sectionTitle('REASON FOR LEAVING'),

                  const SizedBox(height: 9),

                  _reasonField(),

                  const SizedBox(height: 20),

                  // =====================================================
                  // RETURN TIME
                  // =====================================================

                  _sectionTitle('EXPECTED RETURN'),

                  const SizedBox(height: 9),

                  _returnTimeField(),

                  const SizedBox(height: 20),

                  // =====================================================
                  // LOCATION
                  // =====================================================

                  _locationCard(),

                  const SizedBox(height: 26),

                  // =====================================================
                  // SUBMIT
                  // =====================================================

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF176DFF),
                            Color(0xFF18D5EF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00CFFF)
                                .withOpacity(0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submitPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.send_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Request Permission',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =====================================================
                  // SECURITY
                  // =====================================================

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: Color(0xFF536D83),
                          size: 14,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Your permission request is securely recorded',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF536D83),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =====================================================
                  // POWERED BY
                  // =====================================================

                  Center(
                    child: Text(
                      'LYRA PULSE',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF38566D),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.4,
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
  // EMPLOYEE CARD
  // ===============================================================

  Widget _employeeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF081D31),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFF16435F),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A3047),
              border: Border.all(
                color: const Color(0xFF20DFFF),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF20DFFF),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Employee',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Employee ID: EMP001',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF718CA1),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF24E5C0),
            size: 21,
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // SECTION TITLE
  // ===============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: const Color(0xFF718AA0),
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }

  // ===============================================================
  // PERMISSION TYPE DROPDOWN
  // ===============================================================

  Widget _permissionTypeDropdown() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF071C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF16435F),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          isExpanded: true,
          dropdownColor: const Color(0xFF071C2E),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF20DFFF),
          ),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          items: permissionTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedType = value;
            });
          },
        ),
      ),
    );
  }

  // ===============================================================
  // REASON FIELD
  // ===============================================================

  Widget _reasonField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF071C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF16435F),
        ),
      ),
      child: TextField(
        controller: reasonController,
        maxLines: 4,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 11,
        ),
        cursorColor: const Color(0xFF20DFFF),
        decoration: InputDecoration(
          hintText: 'Example: Need to visit bank...',
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF536D83),
            fontSize: 10,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(
              left: 14,
              right: 5,
              top: 14,
            ),
            child: Icon(
              Icons.edit_note_rounded,
              color: Color(0xFF20DFFF),
              size: 21,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  // ===============================================================
  // RETURN TIME
  // ===============================================================

  Widget _returnTimeField() {
    final value = selectedReturnTime == null
        ? 'Select expected return time'
        : selectedReturnTime!.format(context);

    return InkWell(
      onTap: _selectReturnTime,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF071C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF16435F),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF20DFFF),
              size: 20,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  color: selectedReturnTime == null
                      ? const Color(0xFF536D83)
                      : Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF718CA1),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // LOCATION CARD
  // ===============================================================

  Widget _locationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF082A28),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF176055),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF0B403B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF24E5C0),
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Office location will be verified',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF7FA99F),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF24E5C0),
            size: 20,
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // BACK BUTTON
  // ===============================================================

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

  // ===============================================================
  // SECURE BADGE
  // ===============================================================

  Widget _secureBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2136),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1D4564),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF24E5C0),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'SECURE',
            style: GoogleFonts.poppins(
              color: const Color(0xFF91AABD),
              fontSize: 8,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // PERMISSION ICON
  // ===============================================================

  Widget _permissionIcon() {
    return Container(
      width: 96,
      height: 96,
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
            blurRadius: 30,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0B3049),
          border: Border.all(
            color: const Color(0xFF20DFFF).withOpacity(0.35),
          ),
        ),
        child: const Icon(
          Icons.assignment_outlined,
          color: Color(0xFF20DFFF),
          size: 40,
        ),
      ),
    );
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
            color.withOpacity(0.12),
            color.withOpacity(0.03),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}