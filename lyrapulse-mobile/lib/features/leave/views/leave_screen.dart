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

  // ===============================================================
  // SAMPLE LEAVE DATA
  // ===============================================================

  final List<Map<String, String>> leaveHistory = [
    {
      'type': 'Casual Leave',
      'from': '12 Sep 2026',
      'to': '13 Sep 2026',
      'days': '2 Days',
      'reason': 'Personal work',
      'status': 'Approved',
    },
    {
      'type': 'Sick Leave',
      'from': '05 Sep 2026',
      'to': '05 Sep 2026',
      'days': '1 Day',
      'reason': 'Not feeling well',
      'status': 'Approved',
    },
    {
      'type': 'Casual Leave',
      'from': '28 Aug 2026',
      'to': '28 Aug 2026',
      'days': '1 Day',
      'reason': 'Family function',
      'status': 'Pending',
    },
  ];

  // ===============================================================
  // APPLY LEAVE
  // ===============================================================

  void _applyLeave() {
    Get.dialog(
      const _ApplyLeaveDialog(),
      barrierDismissible: false,
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),
      body: SafeArea(
        child: Stack(
          children: [
            // =======================================================
            // BACKGROUND GLOW
            // =======================================================

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

            // =======================================================
            // MAIN CONTENT
            // =======================================================

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
                  // =================================================
                  // HEADER
                  // =================================================

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
                          Icons.event_available_rounded,
                          color: Color(0xFF25DDF7),
                          size: 21,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // LEAVE BALANCE
                  // =================================================

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

                  Row(
                    children: [
                      Expanded(
                        child: _balanceCard(
                          icon: Icons.beach_access_rounded,
                          title: 'Casual',
                          value: '08',
                          subtitle: 'Days Left',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _balanceCard(
                          icon: Icons.medical_services_outlined,
                          title: 'Sick',
                          value: '06',
                          subtitle: 'Days Left',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _balanceCard(
                          icon: Icons.event_available_rounded,
                          title: 'Used',
                          value: '04',
                          subtitle: 'This Year',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // APPLY LEAVE BUTTON
                  // =================================================

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
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _applyLeave,
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
                              size: 23,
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

                  // =================================================
                  // TABS
                  // =================================================

                  Text(
                    'MY LEAVE',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF718AA0),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    height: 46,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071C2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF16435F),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _tabButton(
                            title: 'All',
                            index: 0,
                          ),
                        ),
                        Expanded(
                          child: _tabButton(
                            title: 'Approved',
                            index: 1,
                          ),
                        ),
                        Expanded(
                          child: _tabButton(
                            title: 'Pending',
                            index: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // LEAVE HISTORY
                  // =================================================

                  ..._filteredLeaves(),

                  const SizedBox(height: 30),

                  // =================================================
                  // FOOTER
                  // =================================================

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
  // FILTER LEAVES
  // ===============================================================

  List<Widget> _filteredLeaves() {
    List<Map<String, String>> filtered;

    if (selectedTab == 0) {
      filtered = leaveHistory;
    } else if (selectedTab == 1) {
      filtered = leaveHistory
          .where((leave) => leave['status'] == 'Approved')
          .toList();
    } else {
      filtered = leaveHistory
          .where((leave) => leave['status'] == 'Pending')
          .toList();
    }

    if (filtered.isEmpty) {
      return [
        _emptyState(),
      ];
    }

    return filtered.map((leave) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _leaveCard(leave),
      );
    }).toList();
  }

  // ===============================================================
  // LEAVE CARD
  // ===============================================================

  Widget _leaveCard(
    Map<String, String> leave,
  ) {
    final status = leave['status'] ?? '';

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
          // =========================================================
          // TOP
          // =========================================================

          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A2941),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  leave['type'] == 'Sick Leave'
                      ? Icons.medical_services_outlined
                      : Icons.beach_access_rounded,
                  color: const Color(0xFF25DDF7),
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave['type'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      leave['days'] ?? '',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF7892A7),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

              _statusBadge(
                status,
                statusColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(
            color: Color(0xFF16384F),
            height: 1,
          ),

          const SizedBox(height: 14),

          // =========================================================
          // DATE
          // =========================================================

          Row(
            children: [
              Expanded(
                child: _detailItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'From',
                  value: leave['from'] ?? '',
                ),
              ),
              Expanded(
                child: _detailItem(
                  icon: Icons.event_outlined,
                  title: 'To',
                  value: leave['to'] ?? '',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // =========================================================
          // REASON
          // =========================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.notes_rounded,
                color: Color(0xFF25DDF7),
                size: 17,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF718AA0),
                        fontSize: 8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      leave['reason'] ?? '',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFC4D1DC),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // BALANCE CARD
  // ===============================================================

  Widget _balanceCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      height: 116,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF071C2E),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFF16435F),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF25DDF7),
            size: 21,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: const Color(0xFFC1D0DC),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: const Color(0xFF718AA0),
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // TAB BUTTON
  // ===============================================================

  Widget _tabButton({
    required String title,
    required int index,
  }) {
    final selected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 200,
        ),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0C3855)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
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
    );
  }

  // ===============================================================
  // DETAIL ITEM
  // ===============================================================

  Widget _detailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF25DDF7),
          size: 16,
        ),
        const SizedBox(width: 7),
        Column(
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
              style: GoogleFonts.poppins(
                color: const Color(0xFFC4D1DC),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===============================================================
  // STATUS BADGE
  // ===============================================================

  Widget _statusBadge(
    String text,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: color.withOpacity(0.30),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ===============================================================
  // EMPTY STATE
  // ===============================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC071A2D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF16435F),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: Color(0xFF25DDF7),
            size: 35,
          ),
          const SizedBox(height: 12),
          Text(
            'No Leave Requests',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your leave requests will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: const Color(0xFF718AA0),
              fontSize: 10,
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

// ===================================================================
// APPLY LEAVE DIALOG
// ===================================================================

class _ApplyLeaveDialog extends StatefulWidget {
  const _ApplyLeaveDialog();

  @override
  State<_ApplyLeaveDialog> createState() =>
      _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState
    extends State<_ApplyLeaveDialog> {
  String selectedLeave = 'Casual Leave';

  final TextEditingController reasonController =
      TextEditingController();

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF071C2E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF16435F),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =======================================================
            // TITLE
            // =======================================================

            Row(
              children: [
                Expanded(
                  child: Text(
                    'Apply Leave',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: Get.back,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF7892A7),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =======================================================
            // LEAVE TYPE
            // =======================================================

            Text(
              'Leave Type',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9CB0C0),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 7),

            DropdownButtonFormField<String>(
              initialValue: selectedLeave,
              dropdownColor: const Color(0xFF0A2941),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF0A2136),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color(0xFF16435F),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color(0xFF16435F),
                  ),
                ),
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
                  value: 'Emergency Leave',
                  child: Text('Emergency Leave'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  selectedLeave = value;
                });
              },
            ),

            const SizedBox(height: 14),

            // =======================================================
            // REASON
            // =======================================================

            Text(
              'Reason',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9CB0C0),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 7),

            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 11,
              ),
              decoration: InputDecoration(
                hintText: 'Enter reason for leave',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF58758A),
                  fontSize: 10,
                ),
                filled: true,
                fillColor: const Color(0xFF0A2136),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color(0xFF16435F),
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                  borderSide: const BorderSide(
                    color: Color(0xFF16435F),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // =======================================================
            // SUBMIT
            // =======================================================

            SizedBox(
              width: double.infinity,
              height: 48,
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
                        BorderRadius.circular(14),
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
      ),
    );
  }
}