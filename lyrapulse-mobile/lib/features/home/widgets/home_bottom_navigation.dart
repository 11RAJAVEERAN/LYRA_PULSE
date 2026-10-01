import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/app_colors.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 8,
            bottom: 5,
          ),
          child: Row(
            children: [
              Expanded(
                child: _BottomItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  selected: true,
                  onTap: () {},
                ),
              ),

              Expanded(
                child: _BottomItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Attendance',
                  onTap: () {
                    // Attendance route later
                  },
                ),
              ),

              Expanded(
                child: _BottomItem(
                  icon: Icons.assignment_outlined,
                  label: 'Reports',
                  onTap: () {
                    // Reports route later
                  },
                ),
              ),

              Expanded(
                child: _BottomItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () {
                    // Settings route later
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomItem({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 27,
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 11,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),

          const SizedBox(height: 5),

          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 48 : 0,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}