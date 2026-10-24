import 'package:flutter/material.dart';

class AttendanceLegend extends StatelessWidget {
  const AttendanceLegend({super.key});

  static const items = <_LegendItem>[
    _LegendItem('Today', Color(0xFF1684B8), outlined: true),
    _LegendItem('Present', Color(0xFF20A45A)),
    _LegendItem('Absent', Color(0xFFD93640)),
    _LegendItem('On Leave', Color(0xFF8956E8)),
    _LegendItem('Half Day', Color(0xFFE69A0A)),
    _LegendItem('Week Off', Color(0xFF66788A)),
    _LegendItem('Holiday', Color(0xFF168F9B)),
    _LegendItem('Late', Color(0xFFE69A0A)),
    _LegendItem('Punch Error', Color(0xFFE69A0A)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 9,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F5F8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: item.outlined ? Colors.transparent : item.color,
                  shape: BoxShape.circle,
                  border: item.outlined
                      ? Border.all(color: item.color, width: 2)
                      : null,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF5D6978),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  final bool outlined;

  const _LegendItem(
    this.label,
    this.color, {
    this.outlined = false,
  });
}
