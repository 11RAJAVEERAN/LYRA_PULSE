
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import 'face_verification_screen.dart';

class LocationVerificationScreen extends StatefulWidget {
  final bool isCheckOut;

  const LocationVerificationScreen({
    super.key,
    required this.isCheckOut,
  });

  @override
  State<LocationVerificationScreen> createState() =>
      _LocationVerificationScreenState();
}

class _LocationVerificationScreenState
    extends State<LocationVerificationScreen> {
  // IMPORTANT:
  // Intha sample coordinates-ai unga actual office coordinates-oda replace pannunga.
  static const double officeLatitude = 11.7364;
  static const double officeLongitude = 79.7627;

  static const double allowedRadius = 100.0;

  Position? currentPosition;
  String locationText = 'Checking your location...';
  double? distanceInMeters;

  bool isLoading = false;
  bool locationVerified = false;
  bool isOutsideOffice = false;
  bool isOpeningCamera = false;

  @override
  void initState() {
    super.initState();
    _verifyLocation();
  }

  Future<void> _verifyLocation() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      locationVerified = false;
      isOutsideOffice = false;
      locationText = 'Getting your current location...';
      distanceInMeters = null;
    });

    try {
      // 1. Location service ON-a irukka check pannum.
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            locationText = 'Location service is turned off.';
          });

          await _showLocationSettingsDialog();
        }
        return;
      }

      // 2. Location permission check pannum.
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            locationText =
                'Location permission is required for attendance.';
          });
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            locationText =
                'Location permission is permanently denied.';
          });

          await _showPermissionSettingsDialog();
        }
        return;
      }

      // 3. Current GPS location get pannum.
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 25),
        ),
      );

      if (!mounted) return;

      // 4. Office location-lendhu distance calculate pannum.
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        officeLatitude,
        officeLongitude,
      );

      final isInside = distance <= allowedRadius;

      String address = 'Current location detected';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final parts = [
            place.name,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].whereType<String>()
           .map((value) => value.trim())
           .where((value) => value.isNotEmpty)
           .toSet()
           .toList();

          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {
        // Address lookup fail aanaalum GPS distance check continue aagum.
      }

      if (!mounted) return;

      setState(() {
        currentPosition = position;
        distanceInMeters = distance;
        locationText = address;
        locationVerified = isInside;
        isOutsideOffice = !isInside;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        locationText =
            'Unable to get your location. Please try again.';
        locationVerified = false;
      });

      Get.snackbar(
        'Location Error',
        'Please enable GPS and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade900,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _showLocationSettingsDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Location is turned off'),
          content: const Text(
            'Please turn on your device location to continue attendance.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Get.back();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Geolocator.openLocationSettings();
              },
              child: const Text('Turn On Location'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPermissionSettingsDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Please allow location permission in app settings to mark attendance.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Get.back();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _continueToCamera() {
    if (!locationVerified ||
        isLoading ||
        isOpeningCamera ||
        currentPosition == null) {
      return;
    }

    setState(() {
      isOpeningCamera = true;
    });

    Get.to(
      () => FaceVerificationScreen(
        isCheckOut: widget.isCheckOut,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    )?.then((_) {
      if (mounted) {
        setState(() {
          isOpeningCamera = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Location Verification',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 18),

              Center(
                child: Container(
                  height: 112,
                  width: 112,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isLoading
                        ? Icons.location_searching_rounded
                        : locationVerified
                            ? Icons.location_on_rounded
                            : Icons.location_off_rounded,
                    size: 56,
                    color: isOutsideOffice
                        ? Colors.red
                        : primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Verify Your Location',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                   color: AppColors.textPrimary,
                 
                ),
              ),

              const SizedBox(height: 10),

              Text(
                widget.isCheckOut
                    ? 'Verify your location before checking out.'
                    : 'Verify your location before checking in.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 28),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          color: primary,
                          size: 23,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Office Location Check',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    _infoRow(
                      Icons.radar_rounded,
                      'Allowed radius',
                      '100 metres',
                    ),

                    const SizedBox(height: 14),

                    _infoRow(
                      Icons.my_location_rounded,
                      'Your distance',
                      isLoading
                          ? 'Checking...'
                          : distanceInMeters != null
                              ? '${distanceInMeters!.round()} metres'
                              : 'Not available',
                    ),

                    const SizedBox(height: 14),

                    _infoRow(
                      Icons.location_on_outlined,
                      'Current address',
                      locationText,
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isLoading
                            ? primary.withValues(alpha: 0.07)
                            : locationVerified
                                ? Colors.green.withValues(alpha: 0.08)
                                : isOutsideOffice
                                    ? Colors.red.withValues(alpha: 0.07)
                                    : Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading)
                            SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: primary,
                              ),
                            )
                          else
                            Icon(
                              locationVerified
                                  ? Icons.check_circle_rounded
                                  : Icons.info_rounded,
                              color: locationVerified
                                  ? Colors.green
                                  : isOutsideOffice
                                      ? Colors.red
                                      : Colors.orange,
                            ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              isLoading
                                  ? 'Verifying your GPS location...'
                                  : locationVerified
                                      ? 'Location verified. You are within the office radius.'
                                      : isOutsideOffice
                                          ? 'You are outside the allowed 100-metre office radius.'
                                          : locationText,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: locationVerified &&
                          !isLoading &&
                          !isOpeningCamera
                      ? _continueToCamera
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isOpeningCamera
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_rounded),
                            const SizedBox(width: 10),
                            Text(
                              locationVerified
                                  ? 'Continue to Camera'
                                  : 'Verify Location to Continue',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: isLoading ? null : _verifyLocation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(
                    color: primary.withValues(alpha: 0.35),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh Location'),
              ),

              const SizedBox(height: 14),

              Text(
                'Attendance can continue only when your detected location is within 100 metres of the configured office coordinates.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,

           color: AppColors.textPrimary,
          
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                   color: AppColors.secondary
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
