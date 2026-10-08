import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'face_verification_screen.dart';

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

  static const Color background = Color(0xFFF7FAFE);
  static const Color navy = Color(0xFF102B63);
  static const Color blue = Color(0xFF3978E8);
  static const Color green = Color(0xFF0BA875);
  static const Color grey = Color(0xFF6B7280);

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

    final badge = widget.isCheckOut
        ? 'CHECK-OUT LOCATION'
        : 'CHECK-IN LOCATION';

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
          style: GoogleFonts.poppins(
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
                              ? Colors.orange.withOpacity(.10)
                              : blue.withOpacity(.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 42,
                          color: widget.isCheckOut
                              ? Colors.orange
                              : blue,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        badge,
                        style: GoogleFonts.poppins(
                          color: widget.isCheckOut
                              ? Colors.orange
                              : blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFE6EBF3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.04),
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
                                    color: green.withOpacity(.10),
                                    borderRadius:
                                        BorderRadius.circular(14),
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
                                            : Colors.redAccent,
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
                                        style: GoogleFonts.poppins(
                                          color: navy,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        locationText,
                                        style: GoogleFonts.poppins(
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
                              color: const Color(0xFFECEFF4),
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
                                    style: GoogleFonts.poppins(
                                      color: locationVerified
                                          ? green
                                          : grey,
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
                            color: blue.withOpacity(.06),
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
                                style: GoogleFonts.poppins(
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
                  onPressed: locationVerified
                      ? _continueToFaceVerification
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isCheckOut
                        ? const Color.fromARGB(255, 0, 119, 255)
                        : blue,
                    disabledBackgroundColor:
                        const Color(0xFFD9DEE7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.isCheckOut
                        ? 'Continue to Check Out'
                        : 'Continue to Check In',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
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
                  style: GoogleFonts.poppins(
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