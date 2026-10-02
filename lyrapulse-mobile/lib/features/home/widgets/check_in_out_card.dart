import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class CheckInOutCard extends StatelessWidget {
  final bool isCheckedIn;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const CheckInOutCard({
    super.key,
    required this.isCheckedIn,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              title: 'CHECK IN',
              subtitle: 'Start your shift',
              icon: Icons.login_rounded,
              active: !isCheckedIn,
              onTap: onCheckIn,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _ActionCard(
              title: 'CHECK OUT',
              subtitle: 'End your shift',
              icon: Icons.logout_rounded,
              active: isCheckedIn,
              onTap: onCheckOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: active ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(17),
        height: 168,
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                )
              : null,
          color: active ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active
                ? Colors.transparent
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: active ? 20 : 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: active
                        ? Colors.white
                        : AppColors.primary,
                    size: 26,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: active
                        ? Colors.white
                        : AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),

            const Spacer(),

            Text(
              title,
              style: GoogleFonts.inter(
                color: active
                    ? Colors.white
                    : AppColors.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: active
                    ? Colors.white.withValues(alpha: 0.75)
                    : AppColors.textSecondary,
                fontSize: 11.5,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: active
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Text(
                  'Location',
                  style: GoogleFonts.inter(
                    color: active
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: GoogleFonts.inter(
                    color: active
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppColors.border,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.camera_alt_outlined,
                  size: 14,
                  color: active
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Text(
                  'Photo',
                  style: GoogleFonts.inter(
                    color: active
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}