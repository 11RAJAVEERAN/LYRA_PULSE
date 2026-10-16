
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

  static const Color primary = Color(0xFF1761C5);
  static const Color primaryDark = Color(0xFF0B4DA3);
  static const Color background = Color(0xFFF7FAFD);
  static const Color lightBlue = Color(0xFFEAF3FF);
  static const Color textPrimary = Color(0xFF18324B);
  static const Color textSecondary = Color(0xFF71839A);
  static const Color borderColor = Color(0xFFDCE7F5);

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

  void _openApplyLeave() {
    Get.dialog(
      const ApplyLeaveDialog(),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildBalanceTitle(),
              const SizedBox(height: 10),
              _buildBalanceCards(),
              const SizedBox(height: 28),
              _buildApplyButton(),
              const SizedBox(height: 28),
              _buildMyLeaveTitle(),
              const SizedBox(height: 10),
              _buildTabs(),
              const SizedBox(height: 16),
              ..._buildFilteredLeaves(),
              const SizedBox(height: 30),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER

  Widget _buildHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => Get.back(),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: textPrimary.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: textPrimary,
              size: 21,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Leave',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: lightBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: const Icon(
            Icons.event_available_rounded,
            color: primary,
            size: 21,
          ),
        ),
      ],
    );
  }

  // SECTION TITLES

  Widget _buildBalanceTitle() {
    return Text(
      'LEAVE BALANCE',
      style: GoogleFonts.poppins(
        color: textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildMyLeaveTitle() {
    return Text(
      'MY LEAVE',
      style: GoogleFonts.poppins(
        color: textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  // BALANCE CARDS

  Widget _buildBalanceCards() {
    return Row(
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
    );
  }

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
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: textPrimary.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primary, size: 19),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // APPLY LEAVE BUTTON

  Widget _buildApplyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primary, primaryDark],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _openApplyLeave,
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
              const Icon(Icons.add_rounded, size: 23),
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
    );
  }

  // TABS

  Widget _buildTabs() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _tabButton(title: 'All', index: 0)),
          Expanded(child: _tabButton(title: 'Approved', index: 1)),
          Expanded(child: _tabButton(title: 'Pending', index: 2)),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required int index,
  }) {
    final bool selected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? lightBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: selected ? primary : textSecondary,
            fontSize: 9,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // FILTER LEAVES

  List<Widget> _buildFilteredLeaves() {
    List<Map<String, String>> filteredLeaves;

    if (selectedTab == 0) {
      filteredLeaves = leaveHistory;
    } else if (selectedTab == 1) {
      filteredLeaves = leaveHistory
          .where((leave) => leave['status'] == 'Approved')
          .toList();
    } else {
      filteredLeaves = leaveHistory
          .where((leave) => leave['status'] == 'Pending')
          .toList();
    }

    if (filteredLeaves.isEmpty) {
      return [_emptyState()];
    }

    return filteredLeaves.map((leave) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _leaveCard(leave),
      );
    }).toList();
  }

  // LEAVE CARD

  Widget _leaveCard(Map<String, String> leave) {
    final bool approved = leave['status'] == 'Approved';

    final Color statusColor =
        approved ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: textPrimary.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  leave['type'] == 'Sick Leave'
                      ? Icons.medical_services_outlined
                      : Icons.beach_access_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave['type'] ?? '',
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      leave['days'] ?? '',
                      style: GoogleFonts.poppins(
                        color: textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(leave['status'] ?? '', statusColor),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: borderColor, height: 1),
          const SizedBox(height: 14),
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
          _detailItem(
            icon: Icons.notes_rounded,
            title: 'Reason',
            value: leave['reason'] ?? '',
          ),
        ],
      ),
    );
  }

  // DETAIL ITEM

  Widget _detailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: textSecondary,
                  fontSize: 8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  color: textPrimary,
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

  // STATUS BADGE

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
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

  // EMPTY STATE

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: primary,
            size: 35,
          ),
          const SizedBox(height: 12),
          Text(
            'No Leave Requests',
            style: GoogleFonts.poppins(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your leave requests will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // FOOTER

  Widget _buildFooter() {
    return Center(
      child: Text(
        'LYRA PULSE',
        style: GoogleFonts.poppins(
          color: const Color(0xFF9AAEC3),
          fontSize: 8,
          fontWeight: FontWeight.w600,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

// ============================================================
// APPLY LEAVE DIALOG
// ============================================================

class ApplyLeaveDialog extends StatefulWidget {
  const ApplyLeaveDialog({super.key});

  @override
  State<ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends State<ApplyLeaveDialog> {
  static const Color primary = Color(0xFF1761C5);
  static const Color primaryDark = Color(0xFF0B4DA3);
  static const Color lightBlue = Color(0xFFEAF3FF);
  static const Color textPrimary = Color(0xFF18324B);
  static const Color textSecondary = Color(0xFF71839A);
  static const Color borderColor = Color(0xFFDCE7F5);

  String selectedLeave = 'Casual Leave';

  DateTime? fromDate;
  DateTime? toDate;

  final TextEditingController reasonController = TextEditingController();

  int get totalDays {
    if (fromDate == null || toDate == null) {
      return 0;
    }

    return toDate!.difference(fromDate!).inDays + 1;
  }

  String _formatDate(DateTime date) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  // DATE PICKER THEME

  ThemeData _datePickerTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: textPrimary,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
    );
  }

  // SELECT FROM DATE

  Future<void> _selectFromDate() async {
    final DateTime today = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: fromDate ?? today,
      firstDate: today,
      lastDate: DateTime(2035),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: _datePickerTheme(context),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      fromDate = pickedDate;

      if (toDate != null && toDate!.isBefore(pickedDate)) {
        toDate = null;
      }
    });
  }

  // SELECT TO DATE

  Future<void> _selectToDate() async {
    if (fromDate == null) {
      _showMessage(
        'Select From Date',
        'Please select From Date first.',
      );
      return;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: toDate ?? fromDate!,
      firstDate: fromDate!,
      lastDate: DateTime(2035),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: _datePickerTheme(context),
          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      toDate = pickedDate;
    });
  }

  // MESSAGE

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: primaryDark,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }

  // SUBMIT LEAVE

  void _submitLeave() {
    if (fromDate == null) {
      _showMessage('From Date Required', 'Please select From Date.');
      return;
    }

    if (toDate == null) {
      _showMessage('To Date Required', 'Please select To Date.');
      return;
    }

    if (reasonController.text.trim().isEmpty) {
      _showMessage('Reason Required', 'Please enter your leave reason.');
      return;
    }

    final int days = totalDays;

    Get.back();

    Get.snackbar(
      'Leave Request Submitted',
      '$selectedLeave • $days ${days == 1 ? 'Day' : 'Days'}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: primaryDark,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      icon: const Icon(
        Icons.check_circle_outline_rounded,
        color: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  // DIALOG UI

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: textPrimary.withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Apply Leave',
                      style: GoogleFonts.poppins(
                        color: textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(
                        Icons.close_rounded,
                        color: textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // LEAVE TYPE

              _fieldLabel('Leave Type'),
              const SizedBox(height: 7),

              DropdownButtonFormField<String>(
                initialValue: selectedLeave,
                dropdownColor: Colors.white,
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: 11,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: textSecondary,
                ),
                decoration: _inputDecoration(),
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
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedLeave = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              // FROM DATE

              _fieldLabel('From Date'),
              const SizedBox(height: 7),

              _dateSelector(
                text: fromDate == null
                    ? 'Select starting date'
                    : _formatDate(fromDate!),
                onTap: _selectFromDate,
                selected: fromDate != null,
              ),

              const SizedBox(height: 15),

              // TO DATE

              _fieldLabel('To Date'),
              const SizedBox(height: 7),

              _dateSelector(
                text: toDate == null
                    ? 'Select ending date'
                    : _formatDate(toDate!),
                onTap: _selectToDate,
                selected: toDate != null,
              ),

              // TOTAL DAYS

              if (totalDays > 0) ...[
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timelapse_rounded,
                        color: primary,
                        size: 18,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        'Total Leave',
                        style: GoogleFonts.poppins(
                          color: textSecondary,
                          fontSize: 10,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$totalDays ${totalDays == 1 ? 'Day' : 'Days'}',
                        style: GoogleFonts.poppins(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 15),

              // REASON

              _fieldLabel('Reason'),
              const SizedBox(height: 7),

              TextField(
                controller: reasonController,
                maxLines: 3,
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontSize: 11,
                ),
                decoration: _inputDecoration(
                  hintText: 'Enter reason for leave',
                ),
              ),

              const SizedBox(height: 20),

              // SUBMIT BUTTON

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }

  // FIELD LABEL

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // DATE SELECTOR

  Widget _dateSelector({
    required String text,
    required VoidCallback onTap,
    required bool selected,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFD),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? primary : borderColor,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: primary,
              size: 19,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: selected ? textPrimary : textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: textSecondary,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  // INPUT DECORATION

  InputDecoration _inputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(
        color: textSecondary,
        fontSize: 10,
      ),
      filled: true,
      fillColor: const Color(0xFFF7FAFD),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: primary,
          width: 1.4,
        ),
      ),
    );
  }
}
