import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'attendance_confirmation_screen.dart';


class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
    extends State<FaceVerificationScreen> {
  CameraController? _cameraController;

  bool _isInitializing = true;
  bool _cameraReady = false;
  bool _cameraError = false;

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _cameraError = true;
          _errorMessage = 'No camera found on this device.';
        });

        return;
      }

      CameraDescription selectedCamera;

      final frontCameras = cameras.where(
        (camera) =>
            camera.lensDirection ==
            CameraLensDirection.front,
      );

      if (frontCameras.isNotEmpty) {
        selectedCamera = frontCameras.first;
      } else {
        selectedCamera = cameras.first;
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraController = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _cameraReady = true;
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _cameraError = true;
        _errorMessage =
            _cameraErrorMessage(e.code);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _cameraError = true;
        _errorMessage =
            'Unable to access camera.';
      });
    }
  }

  String _cameraErrorMessage(String code) {
    switch (code) {
      case 'CameraAccessDenied':
        return 'Camera permission was denied.';

      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera permission is disabled. Please enable it from Settings.';

      case 'CameraAccessRestricted':
        return 'Camera access is restricted.';

      default:
        return 'Unable to access camera.';
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Verify Your Face',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),










      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            5,
            20,
            25,
          ),
          child: Column(
            children: [
              // ------------------------------------------
              // TITLE
              // ------------------------------------------

              // Text(
              //   'Look at the camera and keep your face inside the frame',
              //   textAlign: TextAlign.center,
              //   style: GoogleFonts.inter(
              //     color: AppColors.textSecondary,
              //     fontSize: 11,
              //     height: 1.5,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),

              const SizedBox(height: 0),

              // ------------------------------------------
              // CAMERA AREA
              // ------------------------------------------

              Container(
                width: double.infinity,
                height: 410,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.12,
                      ),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // CAMERA PREVIEW
                    if (_cameraReady &&
                        _cameraController != null)
                      CameraPreview(
                        _cameraController!,
                      )
                    else
                      Container(
                        color: const Color(0xFF10131A),
                        child: Center(
                          child: _isInitializing
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                )
                              : Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons
                                          .no_photography_rounded,
                                      color: Colors.white70,
                                      size: 45,
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 30,
                                      ),
                                      child: Text(
                                        _errorMessage,
                                        textAlign:
                                            TextAlign.center,
                                        style:
                                            GoogleFonts.inter(
                                          color:
                                              Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                    // DARK OVERLAY
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),

                    // FACE FRAME
                    Center(
                      child: SizedBox(
                        width: 230,
                        height: 300,
                        child: CustomPaint(
                          painter: _FaceFramePainter(
                            color: _cameraReady
                                ? AppColors.success
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),

                    // TOP CAMERA LABEL
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black
                                  .withValues(alpha: 0.35),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize:
                                  MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'LIVE CAMERA',
                                  style:
                                      GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BOTTOM CAMERA MESSAGE
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 18,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: 0.38),
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        // child: Text(
                        //   'Keep your face centered and look at the camera',
                        //   textAlign: TextAlign.center,
                        //   style: GoogleFonts.inter(
                        //     color: Colors.white,
                        //     fontSize: 10,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ------------------------------------------
              // GOOD LIGHTING
              // ------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColors.success.withValues(
                      alpha: 0.20,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(
                          alpha: 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Text(
                          //   'Good lighting',
                          //   style: GoogleFonts.inter(
                          //     color: AppColors.textPrimary,
                          //     fontSize: 11,
                          //     fontWeight: FontWeight.w800,
                          //   ),
                          // ),
                          // const SizedBox(height: 2),
                          Text(
                            'Make sure your face is clearly visible',
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 52),

              // ------------------------------------------
              // CONTINUE
              // ------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _cameraReady
                      ? _continueToConfirmation
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor:
                        AppColors.border,
                    disabledForegroundColor:
                        AppColors.textSecondary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.face_retouching_natural_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Continue',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Your face image will be used only for attendance verification.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 8.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }













  // ------------------------------------------
  // NEXT STEP
  // ------------------------------------------

  void _continueToConfirmation() {
    Get.to(
      () => const AttendanceConfirmationScreen(),
    );
  }
    // Next:
    // Attendance Confirmation Screen
  
}

// ------------------------------------------------------
// FACE FRAME PAINTER
// ------------------------------------------------------

class _FaceFramePainter extends CustomPainter {
  final Color color;

  _FaceFramePainter({
    required this.color,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rect = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height / 2,
      ),
      width: size.width * 0.78,
      height: size.height * 0.82,
    );

    canvas.drawOval(
      rect,
      paint,
    );

    // Small corner indicators
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Top left
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Top right
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Bottom left
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(rect.right, rect.bottom - cornerLength),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _FaceFramePainter oldDelegate,
  ) {
    return oldDelegate.color != color;
  }
}