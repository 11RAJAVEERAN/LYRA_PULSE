
import 'package:flutter/material.dart';

import 'profile_info_row.dart';

class ProfileInfoCard extends StatelessWidget {
  final List<ProfileInfoItem> items;

  const ProfileInfoCard({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 22,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];

          return Column(
            children: [
              ProfileInfoRow(
                icon: item.icon,
                title: item.title,
                value: item.value,
              ),
              if (index != items.length - 1)
                const Divider(
                  height: 1,
                  indent: 55,
                  color: Color(0xFFE9EDF0),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class ProfileInfoItem {
  final IconData icon;
  final String title;
  final String value;

  const ProfileInfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });
}
