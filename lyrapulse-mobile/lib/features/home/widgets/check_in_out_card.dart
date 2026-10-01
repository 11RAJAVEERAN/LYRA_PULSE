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
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionCard(
              title: 'CHECK IN',
              subtitle: 'Start your shift',
              icon: Icons.login_rounded,
              isPrimary: !isCheckedIn,
              onTap: onCheckIn,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: _ActionCard(
              title: 'CHECK OUT',
              subtitle: 'End your shift',
              icon: Icons.logout_rounded,
              isPrimary: isCheckedIn,
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
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 196,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  )
                : null,
            color: isPrimary ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : AppColors.border,
            ),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 15,
                      offset: const Offset(0, 7),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.14)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(
                      icon,
                      color: isPrimary
                          ? Colors.white
                          : AppColors.primary,
                      size: 29,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.14)
                          : AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: isPrimary
                          ? Colors.white
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              Text(
                title,
                style: GoogleFonts.inter(
                  color: isPrimary
                      ? Colors.white
                      : AppColors.primaryDark,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: isPrimary
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Location',
                    style: GoogleFonts.inter(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '•',
                    style: GoogleFonts.inter(
                      color: isPrimary
                          ? Colors.white
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Photo',
                    style: GoogleFonts.inter(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.85)
                          : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}