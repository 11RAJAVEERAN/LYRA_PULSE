import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
  late AnimationController _animationController;

  bool isLoading = true;
  bool isRefreshing = false;

  String locationName = 'Detecting your location...';
  String locationAddress = 'Please wait';

  Position? currentPosition;

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

  // ===============================================================
  // GET CURRENT LOCATION
  // ===============================================================

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      isRefreshing = true;
      locationName = 'Detecting your location...';
      locationAddress = 'Please wait';
      currentPosition = null;
    });

    try {
      // -----------------------------------------------------------
      // LOCATION SERVICE
      // -----------------------------------------------------------

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isRefreshing = false;
          locationName = 'Location is disabled';
          locationAddress =
              'Please enable location services';
        });

        return;
      }

      // -----------------------------------------------------------
      // LOCATION PERMISSION
      // -----------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isRefreshing = false;
          locationName = 'Location permission denied';
          locationAddress =
              'Allow location permission to continue';
        });

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isRefreshing = false;
          locationName = 'Location permission blocked';
          locationAddress =
              'Enable location permission from settings';
        });

        return;
      }

      // -----------------------------------------------------------
      // GET CURRENT POSITION
      // -----------------------------------------------------------

      final position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition = position;

      // -----------------------------------------------------------
      // REVERSE GEOCODING
      // -----------------------------------------------------------

      try {
        final placemarks =
            await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          final city = _firstAvailable([
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
          ]);

          final state = place.administrativeArea;
          final country = place.country;

          if (!mounted) return;

          setState(() {
            locationName = city.isNotEmpty
                ? city
                : 'Current Location';

            locationAddress = [
              if (state != null &&
                  state.trim().isNotEmpty)
                state.trim(),
              if (country != null &&
                  country.trim().isNotEmpty)
                country.trim(),
            ].join(', ');

            isLoading = false;
            isRefreshing = false;
          });

          return;
        }
      } catch (_) {
        // Reverse geocoding failed.
        // Coordinates will still be shown.
      }

      // -----------------------------------------------------------
      // FALLBACK COORDINATES
      // -----------------------------------------------------------

      if (!mounted) return;

      setState(() {
        locationName = 'Current Location';

        locationAddress =
            '${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)}';

        isLoading = false;
        isRefreshing = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        locationName = 'Unable to detect location';
        locationAddress =
            'Please refresh and try again';
      });
    }
  }

  // ===============================================================
  // FIRST AVAILABLE LOCATION VALUE
  // ===============================================================

  String _firstAvailable(List<String?> values) {
    for (final value in values) {
      if (value != null &&
          value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return '';
  }

  // ===============================================================
  // CONTINUE → FACE VERIFICATION
  // ===============================================================

  void _continue() {
    if (currentPosition == null) {
      Get.snackbar(
        'Location Required',
        'Please wait until your current location is detected.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF102A40),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
        icon: const Icon(
          Icons.location_on_outlined,
          color: Color(0xFF20DDF7),
        ),
      );

      return;
    }

    // ===========================================================
    // LOCATION VERIFIED
    // DIRECTLY OPEN FACE VERIFICATION
    // ===========================================================

    Get.to(
      () => const FaceVerificationScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );
  }

  // ===============================================================
  // BUILD
  // ===============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04111F),

      body: SafeArea(
        child: Stack(
          children: [
            // =====================================================
            // BACKGROUND GLOW
            // =====================================================

            Positioned(
              top: -170,
              right: -150,
              child: _glow(
                380,
                const Color(0xFF087BFF),
              ),
            ),

            Positioned(
              bottom: -190,
              left: -150,
              child: _glow(
                390,
                const Color(0xFF00D9FF),
              ),
            ),

            // =====================================================
            // CONTENT
            // =====================================================

            SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                22,
                20,
                22,
                35,
              ),

              child: Column(
                children: [
                  // =================================================
                  // BACK BUTTON
                  // =================================================

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF0A2136),
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              const Color(0xFF194663),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Get.back();
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // LOCATION ANIMATION
                  // =================================================

                  SizedBox(
                    width: 150,
                    height: 150,
                    child: AnimatedBuilder(
                      animation:
                          _animationController,

                      builder:
                          (context, child) {
                        return CustomPaint(
                          painter:
                              _LocationPainter(
                            progress:
                                _animationController
                                    .value,
                          ),
                          child: child,
                        );
                      },

                      child: const Center(
                        child: Icon(
                          Icons.location_on_rounded,
                          color:
                              Color(0xFF27DDF7),
                          size: 52,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // TITLE
                  // =================================================

                  Text(
                    'VERIFY',
                    style:
                        GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight:
                          FontWeight.w800,
                      letterSpacing: 6,
                      height: 1,
                    ),
                  ),

                  const SizedBox(height: 5),

                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [
                          Color(0xFF19E4FF),
                          Color(0xFF287EFF),
                        ],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'YOUR LOCATION',
                      style:
                          GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Verify your current location before checking in',
                    textAlign: TextAlign.center,
                    style:
                        GoogleFonts.poppins(
                      color:
                          const Color(0xFF7F96AB),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // =================================================
                  // LOCATION CARD
                  // =================================================

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color:
                          const Color(0xCC071A2D),

                      borderRadius:
                          BorderRadius.circular(24),

                      border: Border.all(
                        color:
                            const Color(0xFF17425E),
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.25),
                          blurRadius: 30,
                          offset:
                              const Offset(0, 14),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        // -----------------------------------------
                        // LOCATION HEADER
                        // -----------------------------------------

                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration:
                                  BoxDecoration(
                                color:
                                    const Color(
                                  0xFF0B2C44,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(14),
                              ),
                              child: const Icon(
                                Icons
                                    .location_on_rounded,
                                color:
                                    Color(0xFF26DDF7),
                                size: 24,
                              ),
                            ),

                            const SizedBox(width: 13),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    'CURRENT LOCATION',
                                    style:
                                        GoogleFonts
                                            .poppins(
                                      color:
                                          const Color(
                                        0xFF718AA0,
                                      ),
                                      fontSize: 9,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                      letterSpacing: 1.5,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  Text(
                                    locationName,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,
                                    style:
                                        GoogleFonts
                                            .poppins(
                                      color:
                                          Colors.white,
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (!isLoading)
                              Container(
                                width: 10,
                                height: 10,
                                decoration:
                                    const BoxDecoration(
                                  shape:
                                      BoxShape.circle,
                                  color:
                                      Color(0xFF20E0A8),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // -----------------------------------------
                        // ADDRESS
                        // -----------------------------------------

                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                const Color(0xFF061727),
                            borderRadius:
                                BorderRadius.circular(
                              13,
                            ),
                          ),

                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .near_me_outlined,
                                color:
                                    Color(0xFF25DDF7),
                                size: 18,
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Text(
                                  locationAddress,
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow
                                          .ellipsis,
                                  style:
                                      GoogleFonts
                                          .poppins(
                                    color:
                                        const Color(
                                      0xFF9EB2C2,
                                    ),
                                    fontSize: 10,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // -----------------------------------------
                        // REFRESH
                        // -----------------------------------------

                        SizedBox(
                          width: double.infinity,
                          height: 43,

                          child: OutlinedButton(
                            onPressed:
                                isRefreshing
                                    ? null
                                    : _getCurrentLocation,

                            style:
                                OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(
                                0xFF25DDF7,
                              ),

                              side:
                                  const BorderSide(
                                color:
                                    Color(0xFF1A536D),
                              ),

                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  13,
                                ),
                              ),
                            ),

                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,

                              children: [
                                if (isRefreshing)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Color(
                                        0xFF25DDF7,
                                      ),
                                    ),
                                  )
                                else
                                  const Icon(
                                    Icons
                                        .refresh_rounded,
                                    size: 18,
                                  ),

                                const SizedBox(
                                  width: 8,
                                ),

                                Text(
                                  isRefreshing
                                      ? 'Updating location...'
                                      : 'Refresh Location',

                                  style:
                                      GoogleFonts
                                          .poppins(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // CONTINUE
                  // =================================================

                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(0xFF176DFF),
                            Color(0xFF18D5EF),
                          ],
                        ),

                        borderRadius:
                            BorderRadius.circular(16),

                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(
                              0xFF00CFFF,
                            ).withOpacity(0.22),
                            blurRadius: 22,
                            offset:
                                const Offset(0, 8),
                          ),
                        ],
                      ),

                      child: ElevatedButton(
                        onPressed:
                            isLoading
                                ? null
                                : _continue,

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.transparent,

                          disabledBackgroundColor:
                              Colors.transparent,

                          foregroundColor:
                              Colors.white,

                          shadowColor:
                              Colors.transparent,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),

                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [
                            Text(
                              'Continue',
                              style:
                                  GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),

                            const SizedBox(width: 10),

                            const Icon(
                              Icons
                                  .arrow_forward_rounded,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // =================================================
                  // POWERED BY
                  // =================================================

                  Text(
                    'POWERED BY LYRATECH',
                    style:
                        GoogleFonts.poppins(
                      color:
                          const Color(0xFF38566D),
                      fontSize: 8,
                      fontWeight:
                          FontWeight.w600,
                      letterSpacing: 2.2,
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

  // ===============================================================
  // GLOW
  // ===============================================================

  Widget _glow(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.11),
            color.withOpacity(0.025),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// LOCATION ANIMATION
// ===================================================================

class _LocationPainter extends CustomPainter {
  const _LocationPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    for (int i = 0; i < 2; i++) {
      final radius =
          45 + ((progress + i * 0.5) % 1) * 30;

      final opacity =
          (1 - ((progress + i * 0.5) % 1)) * 0.35;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF20DFFF)
            .withOpacity(opacity);

      canvas.drawCircle(
        center,
        radius,
        paint,
      );
    }

    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color =
          const Color(0xFF087BFF).withOpacity(0.10);

    canvas.drawCircle(
      center,
      45,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _LocationPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
