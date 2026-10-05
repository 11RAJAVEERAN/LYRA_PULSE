import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class LocationStatusCard extends StatelessWidget {
  final bool isVerified;
  final String locationName;
  final String distance;

  const LocationStatusCard({
    super.key,
    required this.isVerified,
    required this.locationName,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLoading =
        locationName == 'Checking location...';

    final bool hasError =
        locationName == 'GPS Disabled' ||
        locationName == 'Permission Required' ||
        locationName == 'Location unavailable';

    final Color statusColor = isLoading
        ? AppColors.warning
        : isVerified
            ? AppColors.success
            : AppColors.error;

    final IconData statusIcon = isLoading
        ? Icons.gps_fixed_rounded
        : isVerified
            ? Icons.location_on_rounded
            : Icons.location_off_rounded;

    final String statusText = isLoading
        ? 'Checking GPS...'
        : isVerified
            ? 'GPS Verified'
            : hasError
                ? 'Location unavailable'
                : 'Outside Location';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        8,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // LOCATION ICON
            AnimatedContainer(
              duration: const Duration(
                milliseconds: 300,
              ),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),

            const SizedBox(width: 13),

            // LOCATION DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORKPLACE LOCATION',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    locationName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    distance,
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // STATUS
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
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
}