import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'face_verification_screen.dart';
import '../../../app/theme/app_colors.dart';

class LocationVerificationScreen extends StatefulWidget {
  final bool isCheckOut;

  const LocationVerificationScreen({
    super.key,
    this.isCheckOut = false,
  });

  @override
  State<LocationVerificationScreen> createState() =>
      _LocationVerificationScreenState();
}

class _LocationVerificationScreenState
    extends State<LocationVerificationScreen> {
  bool isLoading = true;
  bool locationVerified = false;

  String locationText = 'Detecting your location...';

  Position? currentPosition;

  static const Color background = AppColors.hexFFF7FAFE;
  static const Color navy = AppColors.hexFF102B63;
  static const Color blue = AppColors.hexFF3978E8;
  static const Color green = AppColors.hexFF0BA875;
  static const Color grey = AppColors.hexFF6B7280;

  @override
  void initState() {
    super.initState();
    _verifyLocation();
  }

  Future<void> _verifyLocation() async {
    setState(() {
      isLoading = true;
      locationVerified = false;
      locationText = 'Detecting your current location...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        setState(() {
          isLoading = false;
          locationText = 'Location service is turned off';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          isLoading = false;
          locationText = 'Location permission denied';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isLoading = false;
          locationText = 'Location permission permanently denied';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      currentPosition = position;

      String address = 'Current location detected';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final parts = <String>[
            if ((place.locality ?? '').isNotEmpty) place.locality!,
            if ((place.administrativeArea ?? '').isNotEmpty)
              place.administrativeArea!,
          ];

          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {
        address = 'Current location detected';
      }

      if (!mounted) return;

      setState(() {
        isLoading = false;
        locationVerified = true;
        locationText = address;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        locationVerified = false;
        locationText = 'Unable to detect your location';
      });
    }
  }

  void _continueToFaceVerification() {
    if (!locationVerified) return;

    Get.to(
      () => FaceVerificationScreen(
        isCheckOut: widget.isCheckOut,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isCheckOut
        ? 'Verify your location to check out'
        : 'Verify your location to check in';

    final badge =
        widget.isCheckOut ? 'CHECK-OUT LOCATION' : 'CHECK-IN LOCATION';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: navy,
            size: 20,
          ),
        ),
        title: Text(
          'Location Verification',
          style: GoogleFonts.inter(
            color: navy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: widget.isCheckOut
                              ? AppColors.orange.withValues(alpha: .10)
                              : blue.withValues(alpha: .10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 42,
                          color: widget.isCheckOut ? AppColors.orange : blue,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        badge,
                        style: GoogleFonts.inter(
                          color: widget.isCheckOut ? AppColors.orange : blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: navy,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'We need to verify that you are currently at the authorised office location.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: grey,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: AppColors.hexFFE6EBF3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: .04),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: green.withValues(alpha: .10),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    isLoading
                                        ? Icons.gps_fixed_rounded
                                        : locationVerified
                                            ? Icons.verified_rounded
                                            : Icons.location_off_rounded,
                                    color: isLoading
                                        ? blue
                                        : locationVerified
                                            ? green
                                            : AppColors.redAccent,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Location',
                                        style: GoogleFonts.inter(
                                          color: navy,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        locationText,
                                        style: GoogleFonts.inter(
                                          color: grey,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              height: 1,
                              color: AppColors.hexFFECEFF4,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Icon(
                                  Icons.security_rounded,
                                  size: 18,
                                  color: green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    locationVerified
                                        ? 'Location detected successfully'
                                        : 'Location verification required',
                                    style: GoogleFonts.inter(
                                      color: locationVerified ? green : grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (isLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: blue.withValues(alpha: .06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Getting your location...',
                                style: GoogleFonts.inter(
                                  color: blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:
                      locationVerified ? _continueToFaceVerification : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        widget.isCheckOut ? AppColors.hexFF0077FF : blue,
                    disabledBackgroundColor: AppColors.hexFFD9DEE7,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.isCheckOut
                        ? 'Continue to Check Out'
                        : 'Continue to Check In',
                    style: GoogleFonts.inter(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _verifyLocation,
                child: Text(
                  'Refresh Location',
                  style: GoogleFonts.inter(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
