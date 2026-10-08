import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import 'attendance_confirmation_screen.dart';
import '../controllers/home_controller.dart';
import 'checked_out_success_screen.dart';




class FaceVerificationScreen extends StatefulWidget {
   final bool isCheckOut;

  const FaceVerificationScreen({super.key,
    this.isCheckOut = false,
  });

  @override
  State<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
 extends State<FaceVerificationScreen> {

   bool get isCheckOut => widget.isCheckOut;

  CameraController? _cameraController;

  bool _isInitializing = true;
  bool _cameraReady = false;

  String _errorMessage = '';

  // Captured photo
  XFile? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // ------------------------------------------------------------
  // CAMERA INITIALIZATION
  // ------------------------------------------------------------

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _cameraReady = false;
        _errorMessage = '';
      });

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _cameraReady = false;
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      CameraDescription selectedCamera;

      final frontCameras = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );

      if (frontCameras.isNotEmpty) {
        selectedCamera = frontCameras.first;
      } else {
        selectedCamera = cameras.first;
      }

      await _cameraController?.dispose();

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
        _errorMessage = '';
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _cameraReady = false;
        _errorMessage = _cameraErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _cameraReady = false;
        _errorMessage = 'Unable to open camera. Please try again.';
      });
    }
  }

  String _cameraErrorMessage(CameraException exception) {
    switch (exception.code) {
      case 'CameraAccessDenied':
        return 'Camera permission was denied. Please allow camera access.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Camera permission is disabled. Please enable it from settings.';
      case 'CameraAccessRestricted':
        return 'Camera access is restricted on this device.';
      case 'AudioAccessDenied':
        return 'Camera opened, but audio permission was denied.';
      default:
        return 'Unable to access the camera. Please try again.';
    }
  }

  // ------------------------------------------------------------
  // TAKE PHOTO
  // ------------------------------------------------------------

  Future<void> _takePhoto() async {
    if (!_cameraReady || _cameraController == null) {
      return;
    }

    if (_cameraController!.value.isTakingPicture) {
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();

      if (!mounted) return;

      setState(() {
        _capturedImage = image;
      });
    } on CameraException catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'Camera Error',
        _cameraErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'Photo Error',
        'Unable to capture photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  // ------------------------------------------------------------
  // RETAKE PHOTO
  // ------------------------------------------------------------

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
    });
  }

  // ------------------------------------------------------------
  // CHECK IN
  // ------------------------------------------------------------
  void _checkIn() {
  final homeController = Get.find<HomeController>();

  if (isCheckOut) {
    final success = homeController.checkOut();

    if (!success) {
      return;
    }

    Get.off(
      () => const CheckedOutSuccessScreen(),
    );
    return;
  }

  Get.off(
    () => const AttendanceConfirmationScreen(),
  );
}
  
    
    
    

  //   ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          color: AppColors.textPrimary,
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Verify Your Face',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: SafeArea(
        child: Column(
          children: [
            // --------------------------------------------------
            // SCROLLABLE CONTENT
            // --------------------------------------------------

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  5,
                  20,
                  20,
                ),
                child: Column(
                  children: [
                    // ------------------------------------------
                    // CAMERA / CAPTURED PHOTO
                    // ------------------------------------------

                    _buildCameraPreview(),

                    const SizedBox(height: 18),

                    // // ------------------------------------------
                    // // GOOD LIGHTING CARD
                    // // ------------------------------------------

                    // _buildLightingCard(),

                    // const SizedBox(height: 18),

                    // // ------------------------------------------
                    // // PRIVACY TEXT
                    // // ------------------------------------------

                    // _buildPrivacyText(),

                    // const SizedBox(height: 10),
                  ],
                ),
              ),
            ),

            // --------------------------------------------------
            // BOTTOM ACTION BUTTONS
            // --------------------------------------------------

            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CAMERA PREVIEW
  // ==========================================================

  Widget _buildCameraPreview() {
    return Container(
      width: double.infinity,
      height: 610,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildCameraContent(),
    );
  }

  Widget _buildCameraContent() {
    // --------------------------------------------------------
    // CAPTURED IMAGE
    // --------------------------------------------------------

    if (_capturedImage != null) {
      return Stack(
        fit: StackFit.expand,
          children: [
          Transform(
              alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
             child: Image.file(
                 File(_capturedImage!.path),
                    fit: BoxFit.cover,
                     ),
              ),

          // Dark gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),

          // Captured label
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PHOTO CAPTURED',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // --------------------------------------------------------
    // INITIALIZING
    // --------------------------------------------------------

    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.5,
        ),
      );
    }

    // --------------------------------------------------------
    // CAMERA ERROR
    // --------------------------------------------------------

    if (!_cameraReady) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.no_photography_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Camera Unavailable',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage.isEmpty
                    ? 'Unable to access the camera.'
                    : _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _initializeCamera,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(
                    color: Colors.white54,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // --------------------------------------------------------
    // LIVE CAMERA
    // --------------------------------------------------------

    return Stack(
      fit: StackFit.expand,
      children: [
              Transform(
              alignment: Alignment.center,
               transform: Matrix4.rotationY(math.pi),
  child: CameraPreview(_cameraController!),
        ),

        // Dark overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.18),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.25),
              ],
            ),
          ),
        ),

        // LIVE CAMERA label
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE CAMERA',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Face frame
        Center(
          child: CustomPaint(
            size: const Size(250, 310),
            painter: _FaceFramePainter(),
          ),
        ),

        // Bottom camera hint
        Positioned(
          left: 20,
          right: 20,
          bottom: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.face_retouching_natural_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                // const SizedBox(width: 9),
                // Expanded(
                //   child: Text(
                //     'Position your face inside the frame',
                //     style: GoogleFonts.inter(
                //       fontSize: 12,
                //       fontWeight: FontWeight.w500,
                //       color: Colors.white,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // // GOOD LIGHTING CARD
  // // ==========================================================

  // Widget _buildLightingCard() {
  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(18),
  //       border: Border.all(
  //         color: AppColors.border,
  //       ),
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Container(
  //           width: 42,
  //           height: 42,
  //           decoration: BoxDecoration(
  //             color: AppColors.warning.withValues(alpha: 0.12),
  //             shape: BoxShape.circle,
  //           ),
  //           child: const Icon(
  //             Icons.wb_sunny_outlined,
  //             color: AppColors.warning,
  //             size: 22,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Good Lighting',
  //                 style: GoogleFonts.inter(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w700,
  //                   color: AppColors.textPrimary,
  //                 ),
  //               ),
  //               const SizedBox(height: 4),
  //               Text(
  //                 'Make sure your face is clearly visible before taking the photo.',
  //                 style: GoogleFonts.inter(
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w400,
  //                   color: AppColors.textSecondary,
  //                   height: 1.45,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ==========================================================
  // PRIVACY TEXT
  // ==========================================================

  // Widget _buildPrivacyText() {
  //   return Row(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       const Icon(
  //         Icons.lock_outline_rounded,
  //         size: 15,
  //         color: AppColors.textSecondary,
  //       ),
  //       const SizedBox(width: 6),
  //       Flexible(
  //         child: Text(
  //           'Your photo is used only for attendance verification.',
  //           textAlign: TextAlign.center,
  //           style: GoogleFonts.inter(
  //             fontSize: 11,
  //             fontWeight: FontWeight.w400,
  //             color: AppColors.textSecondary,
  //             height: 1.4,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // ==========================================================
  // BOTTOM ACTIONS
  // ==========================================================

  Widget _buildBottomActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        16,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: _capturedImage == null
          ? _buildTakePhotoButton()
          : _buildPhotoActionButtons(),
    );
  }

  // ==========================================================
  // TAKE PHOTO BUTTON
  // ==========================================================

  Widget _buildTakePhotoButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _cameraReady ? _takePhoto : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          foregroundColor: Colors.white,
          disabledForegroundColor: AppColors.textSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_rounded,
              size: 21,
            ),
            const SizedBox(width: 9),
            Text(
              'Take Photo',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // RETAKE + CHECK IN BUTTONS
  // ==========================================================

  Widget _buildPhotoActionButtons() {
    return Row(
      children: [
        // ------------------------------------------------------
        // RETAKE
        // ------------------------------------------------------

        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: _retakePhoto,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: AppColors.primary,
                  width: 1.3,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Retake',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // ------------------------------------------------------
        // CHECK IN
        // ------------------------------------------------------

        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _capturedImage != null ? _checkIn : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isCheckOut ? 'Check Out' : 'Check In',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FACE FRAME PAINTER
// ============================================================

class _FaceFramePainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final ovalRect = Rect.fromCenter(
      center: center,
      width: 185,
      height: 255,
    );

    final ovalPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    canvas.drawOval(
      ovalRect,
      ovalPaint,
    );

    // Corner indicators
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 22.0;

    // Top left
    canvas.drawLine(
      Offset(
        ovalRect.left + 8,
        ovalRect.top,
      ),
      Offset(
        ovalRect.left + cornerLength,
        ovalRect.top,
      ),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(
        ovalRect.left,
        ovalRect.top + 8,
      ),
      Offset(
        ovalRect.left,
        ovalRect.top + cornerLength,
      ),
      cornerPaint,
    );

    // Top right
    canvas.drawLine(
      Offset(
        ovalRect.right - 8,
        ovalRect.top,
      ),
      Offset(
        ovalRect.right - cornerLength,
        ovalRect.top,
      ),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(
        ovalRect.right,
        ovalRect.top + 8,
      ),
      Offset(
        ovalRect.right,
        ovalRect.top + cornerLength,
      ),
      cornerPaint,
    );

    // Bottom left
    canvas.drawLine(
      Offset(
        ovalRect.left + 8,
        ovalRect.bottom,
      ),
      Offset(
        ovalRect.left + cornerLength,
        ovalRect.bottom,
      ),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(
        ovalRect.left,
        ovalRect.bottom - 8,
      ),
      Offset(
        ovalRect.left,
        ovalRect.bottom - cornerLength,
      ),
      cornerPaint,
    );

    // Bottom right
    canvas.drawLine(
      Offset(
        ovalRect.right - 8,
        ovalRect.bottom,
      ),
      Offset(
        ovalRect.right - cornerLength,
        ovalRect.bottom,
      ),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(
        ovalRect.right,
        ovalRect.bottom - 8,
      ),
      Offset(
        ovalRect.right,
        ovalRect.bottom - cornerLength,
      ),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}