
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'face_verification_screen.dart';

class LocationVerificationScreen extends StatefulWidget {
  const LocationVerificationScreen({super.key});

  @override
  State<LocationVerificationScreen> createState() =>
      _LocationVerificationScreenState();
}

class _LocationVerificationScreenState
    extends State<LocationVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const Color background = Color(0xFF06111F);
  static const Color cardColor = Color(0xFF101F31);
  static const Color cyan = Color(0xFF27D5EA);
  static const Color blue = Color(0xFF347DFF);
  static const Color muted = Color(0xFF91A5BD);
  static const Color green = Color(0xFF35D6A0);

  Position? currentPosition;
  String locationName = 'Current Location';
  String locationAddress = 'Waiting for GPS coordinates...';
  String errorMessage = '';
  bool isLoading = true;
  bool isRefreshing = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      isLoading = currentPosition == null;
      isRefreshing = currentPosition != null;
      errorMessage = '';
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Please enable location services on your device.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is permanently denied. '
          'Please enable it in Settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      String name = 'Current Location';
      String address =
          '${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)}';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final parts = [
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].whereType<String>().where((e) => e.trim().isNotEmpty);

          final formatted = parts.toSet().join(', ');

          if (formatted.isNotEmpty) {
            name = place.locality?.isNotEmpty == true
                ? place.locality!
                : 'Current Location';
            address = formatted;
          }
        }
      } catch (_) {
        // GPS coordinates are still usable if reverse geocoding fails.
      }

      if (!mounted) return;

      setState(() {
        currentPosition = position;
        locationName = name;
        locationAddress = address;
        isLoading = false;
        isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  void _continue() {
    if (currentPosition == null) {
      Get.snackbar(
        'Location Required',
        'Please get your current GPS location before continuing.',
        backgroundColor: cardColor,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    Get.to(
      () => const FaceVerificationScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 34),
                    _buildGpsAnimation(),
                    const SizedBox(height: 25),
                    _buildHeading(),
                    const SizedBox(height: 30),
                    _buildLocationCard(),
                    const SizedBox(height: 17),
                    _buildInformationBanner(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: _buildContinueButton(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'S E C U R E   A T T E N D A N C E   •   L Y R A T E C H',
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  letterSpacing: 1.1,
                  color: const Color(0xFF52677F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Material(
          color: const Color(0xFFF0F5FF),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Get.back(),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_rounded,
                color: background,
                size: 23,
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF102A35),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: const Color(0xFF15505C),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: cyan,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                'LOCATION CHECK',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFB9DDE4),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGpsAnimation() {
    return SizedBox(
      width: 150,
      height: 150,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final progress = _animationController.value;

          return Stack(
            alignment: Alignment.center,
            children: [
              _circle(144, 0.08),
              _circle(118, 0.12),
              Transform.scale(
                scale: 0.88 + progress * 0.12,
                child: _circle(94, 0.17),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2268C8),
                      Color(0xFF10417F),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF4A9CFF),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withValues(alpha: 0.20),
                      blurRadius: 25,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 43,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF1381A4).withValues(alpha: opacity + 0.12),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      children: [
        Text(
          'Verify your location',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We need your current GPS location before\n'
          'continuing to face verification.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: muted,
            fontSize: 12,
            height: 1.8,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    final position = currentPosition;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF263D55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A334B),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: cyan,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR CURRENT LOCATION',
                      style: GoogleFonts.poppins(
                        color: muted,
                        fontSize: 8,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                position != null
                    ? Icons.check_circle
                    : Icons.location_searching_rounded,
                color: position != null ? green : muted,
                size: 21,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF081625),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.navigation_rounded,
                  color: cyan,
                  size: 17,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    position == null
                        ? (isLoading ? 'Detecting your location...' : 'GPS unavailable')
                        : '${position.latitude.toStringAsFixed(6)}, '
                          '${position.longitude.toStringAsFixed(6)}',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFC1CFDF),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _coordinateBox(
                  'LATITUDE',
                  position?.latitude.toStringAsFixed(6) ?? '--',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _coordinateBox(
                  'LONGITUDE',
                  position?.longitude.toStringAsFixed(6) ?? '--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Icon(
                position != null
                    ? Icons.verified_rounded
                    : Icons.info_outline_rounded,
                color: position != null ? green : muted,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  position != null
                      ? 'GPS coordinates received'
                      : isLoading
                          ? 'Getting your GPS coordinates...'
                          : 'Location not verified',
                  style: GoogleFonts.poppins(
                    color: position != null ? green : muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (errorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage,
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF8D9A),
                fontSize: 10,
              ),
            ),
          ],
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: isRefreshing || isLoading
                  ? null
                  : _getCurrentLocation,
              style: OutlinedButton.styleFrom(
                foregroundColor: cyan,
                disabledForegroundColor: muted,
                side: const BorderSide(
                  color: Color(0xFF28516B),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isRefreshing || isLoading)
                    const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cyan,
                      ),
                    )
                  else
                    const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                    ),
                  const SizedBox(width: 9),
                  Text(
                    isLoading
                        ? 'Getting Location...'
                        : isRefreshing
                            ? 'Refreshing Location...'
                            : 'Refresh Location',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coordinateBox(String label, String value) {
    return Container(
      height: 59,
      padding: const EdgeInsets.fromLTRB(13, 10, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF8BA1BD),
              fontSize: 8,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF172C45),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationBanner() {
    final hasError = errorMessage.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: hasError
            ? const Color(0xFF301C29)
            : const Color(0xFF182536),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError
              ? const Color(0xFF71404B)
              : const Color(0xFF334052),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasError ? Icons.warning_amber_rounded : Icons.info_outline,
            color: hasError ? const Color(0xFFFFA0A8) : blue,
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasError
                  ? errorMessage
                  : 'Make sure location access is enabled. Your device must '
                    'provide a GPS position to continue.',
              style: GoogleFonts.poppins(
                color: const Color(0xFF9CB0C7),
                fontSize: 10,
                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3979FF),
              Color(0xFF24C9DE),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cyan.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _continue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continue to Face Verification',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}