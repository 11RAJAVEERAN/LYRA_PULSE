import 'package:flutter/material.dart';

class LeaveContent extends StatelessWidget {
  final int totalLeave;
  final int usedLeave;
  final int remainingLeave;
  final String selectedLeaveType;
  final List<String> leaveTypes;
  final ValueChanged<String> onLeaveTypeChanged;

  const LeaveContent({
    super.key,
    required this.totalLeave,
    required this.usedLeave,
    required this.remainingLeave,
    required this.selectedLeaveType,
    required this.leaveTypes,
    required this.onLeaveTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leave',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B1B1B),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Manage your leave requests',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 20),

          // Leave balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leave Balance',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B1B1B),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _BalanceItem(
                        value: totalLeave.toString(),
                        label: 'Total',
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFF1565C0),
                        backgroundColor: const Color(0xFFE3F2FD),
                      ),
                    ),
                    Expanded(
                      child: _BalanceItem(
                        value: usedLeave.toString(),
                        label: 'Used',
                        icon: Icons.event_busy_rounded,
                        color: const Color(0xFFE65100),
                        backgroundColor: const Color(0xFFFFF3E0),
                      ),
                    ),
                    Expanded(
                      child: _BalanceItem(
                        value: remainingLeave.toString(),
                        label: 'Remaining',
                        icon: Icons.event_available_rounded,
                        color: const Color(0xFF2E7D32),
                        backgroundColor: const Color(0xFFE8F5E9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Apply Leave',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B1B1B),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leave Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: selectedLeaveType,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                  ),
                  items: leaveTypes.map(
                    (type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    },
                  ).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onLeaveTypeChanged(value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                const Text(
                  'From Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 8),

                _DateField(
                  hint: 'Select start date',
                  icon: Icons.calendar_today_rounded,
                  onTap: () {},
                ),

                const SizedBox(height: 14),

                const Text(
                  'To Date',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 8),

                _DateField(
                  hint: 'Select end date',
                  icon: Icons.calendar_today_rounded,
                  onTap: () {},
                ),

                const SizedBox(height: 14),

                const Text(
                  'Reason',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Enter reason for leave',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text(
                      'Submit Leave Request',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _BalanceItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final VoidCallback onTap;

  const _DateField({
    required this.hint,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 19,
              color: Color(0xFF777777),
            ),
            const SizedBox(width: 10),
            Text(
              hint,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}