
import 'package:flutter/material.dart';

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 45,
            child: Icon(
              icon,
              size: 27,
              color: const Color(0xFF596D7B),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF98A2AA),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172B3A),
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
