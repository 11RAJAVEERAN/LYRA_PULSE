import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  int selectedTab = 0;

  final List<Map<String, dynamic>> leaveRequests = [
    {
      'type': 'Casual Leave',
      'date': '05 Oct 2026',
      'days': '1 Day',
      'reason': 'Personal work',
      'status': 'Approved',
    },
    {
      'type': 'Sick Leave',
      'date': '18 Sep 2026',
      'days': '2 Days',
      'reason': 'Not feeling well',
      'status': 'Approved',
    },
    {
      'type': 'Casual Leave',
      'date': '12 Sep 2026',
      'days': '1 Day',
      'reason': 'Family function',
      'status': 'Pending',
    },
  ];

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

            // =========================================================
            // CONTENT
            // =========================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                35,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =====================================================
                  // HEADER
                  // =====================================================

                  Row(
                    children: [
                      _backButton(),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Text(
                          'Leave',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      Container(
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
                          Icons.calendar_month_rounded,
                          color: Color(0xFF25DDF7),
                          size: 21,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =====================================================
                  // LEAVE BALANCE
                  // =====================================================

                  Text(
                    'LEAVE BALANCE',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF718AA0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0A2941),
                          Color(0xFF071A2D),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFF16435F),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D9FF)
                              .withOpacity(0.06),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0A3550),
                            border: Border.all(
                              color: const Color(0xFF20DDF7),
                            ),
                          ),
                          child: const Icon(
                            Icons.event_available_rounded,
                            color: Color(0xFF25DDF7),
                            size: 28,
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Leave',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF8CA4B7),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '12 Days',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2136),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF16435F),
                            ),
                          ),
                          child: Text(
                            '2026',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF25DDF7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =====================================================
                  // SMALL BALANCE CARDS
                  // =====================================================

                  Row(
                    children: [
                      Expanded(
                        child: _balanceCard(
                          title: 'Casual',
                          value: '06',
                          icon: Icons.beach_access_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _balanceCard(
                          title: 'Sick',
                          value: '04',
                          icon: Icons.local_hospital_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _balanceCard(
                          title: 'Other',
                          value: '02',
                          icon: Icons.more_horiz_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =====================================================
                  // APPLY LEAVE BUTTON
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
                                .withOpacity(0.20),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _showApplyLeaveSheet,
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
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Apply Leave',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =====================================================
                  // LEAVE REQUESTS
                  // =====================================================

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'LEAVE REQUESTS',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF718AA0),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      Text(
                        '${leaveRequests.length} Requests',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF25DDF7),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // =====================================================
                  // FILTER TABS
                  // =====================================================

                  Container(
                    height: 42,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071C2E),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: const Color(0xFF16435F),
                      ),
                    ),
                    child: Row(
                      children: [
                        _filterTab(
                          title: 'All',
                          index: 0,
                        ),
                        _filterTab(
                          title: 'Pending',
                          index: 1,
                        ),
                        _filterTab(
                          title: 'Approved',
                          index: 2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // =====================================================
                  // REQUEST LIST
                  // =====================================================

                  ..._filteredRequests().map(
                    (request) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: 10,
                      ),
                      child: _leaveRequestCard(request),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =====================================================
                  // FOOTER
                  // =====================================================

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
  // FILTERED REQUESTS
  // ===============================================================

  List<Map<String, dynamic>> _filteredRequests() {
    if (selectedTab == 0) {
      return leaveRequests;
    }

    if (selectedTab == 1) {
      return leaveRequests
          .where((item) => item['status'] == 'Pending')
          .toList();
    }

    return leaveRequests
        .where((item) => item['status'] == 'Approved')
        .toList();
  }

  // ===============================================================
  // FILTER TAB
  // ===============================================================

  Widget _filterTab({
    required String title,
    required int index,
  }) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF0A3855)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              color: selected
                  ? const Color(0xFF25DDF7)
                  : const Color(0xFF718AA0),
              fontSize: 9,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // LEAVE REQUEST CARD
  // ===============================================================

  Widget _leaveRequestCard(
    Map<String, dynamic> request,
  ) {
    final status = request['status'] as String;

    final Color statusColor = status == 'Approved'
        ? const Color(0xFF25DDF7)
        : const Color(0xFFFFC857);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCC071A2D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF16435F),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A2941),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: Color(0xFF25DDF7),
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['type'],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request['date'],
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF7892A7),
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
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: statusColor.withOpacity(0.28),
                  ),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(
            color: Color(0xFF16384F),
            height: 1,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _requestInfo(
                  icon: Icons.timelapse_rounded,
                  title: 'Duration',
                  value: request['days'],
                ),
              ),
              Expanded(
                child: _requestInfo(
                  icon: Icons.description_outlined,
                  title: 'Reason',
                  value: request['reason'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // REQUEST INFO
  // ===============================================================

  Widget _requestInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF25DDF7),
          size: 17,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF718AA0),
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: const Color(0xFFC4D1DC),
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

  // ===============================================================
  // BALANCE CARD
  // ===============================================================

  Widget _balanceCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF071C2E),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF16435F),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF25DDF7),
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFF718AA0),
              fontSize: 8,
            ),
          ),
        ],
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
  // APPLY LEAVE BOTTOM SHEET
  // ===============================================================

  void _showApplyLeaveSheet() {
    String selectedLeave = 'Casual Leave';

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              30,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF071A2D),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: Color(0xFF16435F),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF35566D),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Apply Leave',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Submit your leave request',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF7892A7),
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'LEAVE TYPE',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF718AA0),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2136),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF16435F),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedLeave,
                      dropdownColor:
                          const Color(0xFF0A2136),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF25DDF7),
                      ),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Casual Leave',
                          child: Text('Casual Leave'),
                        ),
                        DropdownMenuItem(
                          value: 'Sick Leave',
                          child: Text('Sick Leave'),
                        ),
                        DropdownMenuItem(
                          value: 'Other Leave',
                          child: Text('Other Leave'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;

                        setSheetState(() {
                          selectedLeave = value;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();

                      Get.snackbar(
                        'Leave Request',
                        'Your leave request has been submitted.',
                        snackPosition:
                            SnackPosition.BOTTOM,
                        backgroundColor:
                            const Color(0xFF102A40),
                        colorText: Colors.white,
                        margin:
                            const EdgeInsets.all(16),
                        borderRadius: 14,
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF25DDF7),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF087BFF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Submit Request',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
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
            color.withOpacity(0.11),
            color.withOpacity(0.025),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}