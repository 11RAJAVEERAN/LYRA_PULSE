import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
  int selectedTab = 0;

  static const Color navy = AppColors.hexFF102B63;
  static const Color background = AppColors.hexFFF5F7FD;
  static const Color cardColor = AppColors.white;
  static const Color borderColor = AppColors.hexFFE5EAF2;
  static const Color mutedText = AppColors.hexFF7B8497;
  static const Color textColor = AppColors.hexFF18243A;
  static const Color green = AppColors.hexFF0BA875;
  static const Color orange = AppColors.warning;
  static const Color red = AppColors.hexFFEF4444;

  final List<Map<String, String>> leaveRequests = [
    {
      'type': 'Casual Leave',
      'date': '12 Sep - 13 Sep',
      'days': '2 Days',
      'status': 'Approved',
      'reason': 'Personal work',
    },
    {
      'type': 'Sick Leave',
      'date': '05 Sep',
      'days': '1 Day',
      'status': 'Approved',
      'reason': 'Health issue',
    },
    {
      'type': 'Casual Leave',
      'date': '28 Aug',
      'days': '1 Day',
      'status': 'Pending',
      'reason': 'Family function',
    },
  ];

  TextStyle textStyle({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = textColor,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  List<Map<String, String>> get filteredRequests {
    if (selectedTab == 1) {
      return leaveRequests
          .where((item) => item['status'] == 'Pending')
          .toList();
    }

    if (selectedTab == 2) {
      return leaveRequests
          .where((item) => item['status'] == 'Approved')
          .toList();
    }

    return leaveRequests;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: navy,
            size: 20,
          ),
        ),
        title: Text(
          'Leave Management',
          style: textStyle(
            size: 19,
            weight: FontWeight.w700,
            color: navy,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 26),
              _buildHistoryHeader(),
              const SizedBox(height: 18),
              _buildFilterTabs(),
              const SizedBox(height: 18),
              if (filteredRequests.isEmpty)
                _buildEmptyState()
              else
                ...filteredRequests.map(_buildLeaveCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.hexFF102B63,
            AppColors.hexFF244985,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Leave Balance',
                  style: textStyle(
                    size: 14,
                    weight: FontWeight.w500,
                    color: AppColors.white70,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.white,
                  size: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '12',
                style: textStyle(
                  size: 42,
                  weight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 9, bottom: 10),
                child: Text(
                  'days remaining',
                  style: textStyle(
                    size: 12,
                    color: AppColors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const LinearProgressIndicator(
              value: 0.6,
              minHeight: 7,
              backgroundColor: AppColors.hexFF536A96,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.white,
              ),
            ),
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used: 8 days',
                style: textStyle(
                  size: 11,
                  color: AppColors.white70,
                ),
              ),
              Text(
                'Total: 20 days',
                style: textStyle(
                  size: 11,
                  color: AppColors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Leave History',
            style: textStyle(
              size: 18,
              weight: FontWeight.w700,
              color: navy,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showApplyLeaveSheet,
          icon: const Icon(
            Icons.add_rounded,
            size: 19,
            color: AppColors.white,
          ),
          label: Text(
            'Apply Leave',
            style: textStyle(
              size: 12,
              weight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          style: ButtonStyle(
            backgroundColor:
                const WidgetStatePropertyAll<Color>(AppColors.hexFF102B63),
            foregroundColor:
                const WidgetStatePropertyAll<Color>(AppColors.white),
            overlayColor:
                const WidgetStatePropertyAll<Color>(AppColors.hexFF243F78),
            elevation: const WidgetStatePropertyAll<double>(0),
            shadowColor:
                const WidgetStatePropertyAll<Color>(AppColors.transparent),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            shape: WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    const tabs = ['All', 'Pending', 'Approved'];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.hexFFEDF1F8,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedTab = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white : AppColors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    tabs[index],
                    style: textStyle(
                      size: 12,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? navy : mutedText,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, String> leave) {
    final status = leave['status'] ?? 'Pending';
    final isApproved = status == 'Approved';
    final statusColor = isApproved ? green : orange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: navy.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: navy,
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
                      style: textStyle(
                        size: 14,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      leave['date'] ?? '',
                      style: textStyle(
                        size: 12,
                        color: mutedText,
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
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: textStyle(
                    size: 10,
                    weight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(color: borderColor, height: 1),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: mutedText,
              ),
              const SizedBox(width: 7),
              Text(
                leave['days'] ?? '',
                style: textStyle(
                  size: 12,
                  color: mutedText,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.notes_rounded,
                size: 16,
                color: mutedText,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  leave['reason'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle(
                    size: 12,
                    color: mutedText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            size: 42,
            color: mutedText,
          ),
          const SizedBox(height: 12),
          Text(
            'No leave requests found',
            style: textStyle(
              size: 14,
              weight: FontWeight.w600,
              color: navy,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your leave requests will appear here.',
            textAlign: TextAlign.center,
            style: textStyle(
              size: 12,
              color: mutedText,
            ),
          ),
        ],
      ),
    );
  }

  void _showApplyLeaveSheet() {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();

    String selectedLeaveType = 'Casual Leave';
    DateTime? fromDate;
    DateTime? toDate;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final totalDays = fromDate != null && toDate != null
                ? toDate!.difference(fromDate!).inDays + 1
                : 0;

            Future<void> chooseDate({required bool isFromDate}) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: isFromDate
                    ? fromDate ?? DateTime.now()
                    : toDate ?? fromDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(
                  const Duration(days: 365),
                ),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: navy,
                        onPrimary: AppColors.white,
                        surface: AppColors.white,
                        onSurface: textColor,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked == null) return;

              setSheetState(() {
                if (isFromDate) {
                  fromDate = picked;

                  if (toDate != null && toDate!.isBefore(picked)) {
                    toDate = picked;
                  }
                } else {
                  toDate = picked;
                }
              });
            }

            return Container(
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.hexFFDCE2EC,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Apply for Leave',
                              style: textStyle(
                                size: 20,
                                weight: FontWeight.w700,
                                color: navy,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _fieldLabel('Leave Type'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedLeaveType,
                        decoration: _inputDecoration(
                          hint: 'Select leave type',
                          icon: Icons.event_note_rounded,
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
                            value: 'Personal Leave',
                            child: Text('Personal Leave'),
                          ),
                          DropdownMenuItem(
                            value: 'Emergency Leave',
                            child: Text('Emergency Leave'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() {
                              selectedLeaveType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      _fieldLabel('Leave Dates'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _dateButton(
                              label: 'From Date',
                              date: fromDate,
                              onTap: () => chooseDate(isFromDate: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dateButton(
                              label: 'To Date',
                              date: toDate,
                              onTap: () => chooseDate(isFromDate: false),
                            ),
                          ),
                        ],
                      ),
                      if (totalDays > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Total leave: $totalDays day${totalDays > 1 ? 's' : ''}',
                            style: textStyle(
                              size: 12,
                              weight: FontWeight.w600,
                              color: navy,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _fieldLabel('Reason'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: reasonController,
                        maxLines: 3,
                        style: textStyle(size: 13),
                        decoration: _inputDecoration(
                          hint: 'Enter your reason for leave',
                          icon: Icons.edit_note_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a reason';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;

                            if (fromDate == null || toDate == null) {
                              Get.snackbar(
                                'Select Dates',
                                'Please select both leave dates.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: navy,
                                colorText: AppColors.white,
                                margin: const EdgeInsets.all(16),
                              );
                              return;
                            }

                            if (toDate!.isBefore(fromDate!)) {
                              Get.snackbar(
                                'Invalid Dates',
                                'To date cannot be before from date.',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            final newRequest = <String, String>{
                              'type': selectedLeaveType,
                              'date':
                                  '${_formatDate(fromDate!)} - ${_formatDate(toDate!)}',
                              'days':
                                  '$totalDays Day${totalDays > 1 ? 's' : ''}',
                              'status': 'Pending',
                              'reason': reasonController.text.trim(),
                            };

                            setState(() {
                              leaveRequests.insert(0, newRequest);
                              selectedTab = 0;
                            });

                            Navigator.pop(context);

                            Get.snackbar(
                              'Request Submitted',
                              'Your leave request has been submitted successfully.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: navy,
                              colorText: AppColors.white,
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 3),
                            );
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                const WidgetStatePropertyAll<Color>(
                              AppColors.hexFF102B63,
                            ),
                            foregroundColor:
                                const WidgetStatePropertyAll<Color>(
                              AppColors.white,
                            ),
                            overlayColor: const WidgetStatePropertyAll<Color>(
                              AppColors.hexFF243F78,
                            ),
                            elevation: const WidgetStatePropertyAll<double>(0),
                            shadowColor: const WidgetStatePropertyAll<Color>(
                              AppColors.transparent,
                            ),
                            shape: WidgetStatePropertyAll<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          child: Text(
                            'Submit Request',
                            style: textStyle(
                              size: 14,
                              weight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: textStyle(
        size: 13,
        weight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: textStyle(
        size: 12,
        color: mutedText,
      ),
      prefixIcon: Icon(
        icon,
        color: navy,
        size: 20,
      ),
      filled: true,
      fillColor: AppColors.hexFFF8FAFD,
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
          color: navy,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: red),
      ),
    );
  }

  Widget _dateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.hexFFF8FAFD,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 17,
              color: navy,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textStyle(
                      size: 10,
                      color: mutedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date == null ? 'Select date' : _formatDate(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle(
                      size: 11,
                      weight: FontWeight.w600,
                      color: date == null ? mutedText : navy,
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
