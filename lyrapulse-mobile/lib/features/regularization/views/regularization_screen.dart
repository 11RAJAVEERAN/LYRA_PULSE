import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class RegularizationScreen extends StatefulWidget {
  final DateTime selectedDate;

  const RegularizationScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<RegularizationScreen> createState() =>
      _RegularizationScreenState();
}

class _RegularizationScreenState
    extends State<RegularizationScreen> {
  static const Color primaryBlue = AppColors.hexFF1769D2;
  static const Color backgroundColor = AppColors.hexFFF7FAFD;
  static const Color textColor = AppColors.hexFF253858;

  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _issue = 'Missed Check In';
  TimeOfDay? _checkInTime;
  TimeOfDay? _checkOutTime;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Future<void> _selectTime(bool isCheckIn) async {
    final result = await showTimePicker(
      context: context,
      initialTime: isCheckIn
          ? const TimeOfDay(hour: 9, minute: 0)
          : const TimeOfDay(hour: 18, minute: 0),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (isCheckIn) {
        _checkInTime = result;
      } else {
        _checkOutTime = result;
      }
    });
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;

    if (_issue == 'Missed Check In' && _checkInTime == null) {
      _showMessage('Please select your check-in time.');
      return;
    }

    if (_issue == 'Missed Check Out' && _checkOutTime == null) {
      _showMessage('Please select your check-out time.');
      return;
    }

    if (_issue == 'Incorrect Attendance Time' &&
        (_checkInTime == null || _checkOutTime == null)) {
      _showMessage('Please select both attendance times.');
      return;
    }

    _showMessage(
      'Details validated. Backend API is required to submit and save this request.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _timeCard({
    required String title,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.hexFFE3EAF3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.hexFF8795A8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _formatTime(time),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              const Icon(
                Icons.access_time_rounded,
                color: primaryBlue,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Regularization',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Your Attendance',
                  style: GoogleFonts.inter(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select the attendance details you need to correct.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.hexFF8795A8,
                  ),
                ),
                const SizedBox(height: 22),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.hexFF1769D2,
                        AppColors.hexFF084A9B,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.white,
                        size: 26,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Selected Attendance Date',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.white70,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _formatDate(widget.selectedDate),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Attendance Issue',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: _issue,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Missed Check In',
                      child: Text('Missed Check In'),
                    ),
                    DropdownMenuItem(
                      value: 'Missed Check Out',
                      child: Text('Missed Check Out'),
                    ),
                    DropdownMenuItem(
                      value: 'Incorrect Attendance Time',
                      child: Text('Incorrect Attendance Time'),
                    ),
                    DropdownMenuItem(
                      value: 'Wrong Attendance Status',
                      child: Text('Wrong Attendance Status'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _issue = value);
                  },
                ),

                const SizedBox(height: 24),

                Text(
                  'Actual Attendance Time',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _timeCard(
                      title: 'Check In',
                      time: _checkInTime,
                      onTap: () => _selectTime(true),
                    ),
                    const SizedBox(width: 12),
                    _timeCard(
                      title: 'Check Out',
                      time: _checkOutTime,
                      onTap: () => _selectTime(false),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Text(
                  'Reason for Regularization',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _reasonController,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'Explain why attendance needs correction',
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 5) {
                      return 'Please enter a reason (at least 5 characters).';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submitRequest,
                    icon: const Icon(Icons.send_rounded),
                    label: Text(
                      'Submit Request',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}