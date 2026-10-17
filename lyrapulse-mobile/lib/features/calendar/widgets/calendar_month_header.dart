
import 'package:flutter/material.dart';
import '../controllers/calendar_controller.dart';

class CalendarMonthHeader extends StatelessWidget {
  final CalendarController controller;

  const CalendarMonthHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _arrowButton(
          icon: Icons.chevron_left_rounded,
          onTap: controller.previousMonth,
        ),
        Expanded(
          child: Center(
            child: Text(
              controller.monthTitle,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: Color(0xFF182638),
              ),
            ),
          ),
        ),
        _arrowButton(
          icon: Icons.chevron_right_rounded,
          onTap: controller.nextMonth,
        ),
      ],
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF0F8FC),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: const Color(0xFF1684B8),
            size: 29,
          ),
        ),
      ),
    );
  }
}
