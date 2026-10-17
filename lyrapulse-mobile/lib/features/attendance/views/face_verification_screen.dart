
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import 'attendance_confirmation_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  final bool isCheckOut;

  const FaceVerificationScreen({
    super.key,
    this.isCheckOut = false,
  });

  @override
  State<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
    extends State<FaceVerificationScreen> {
  CameraController? _cameraController;

  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool _cameraError = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    CameraController? controller;

    try {
      final cameras = await availableCameras();

      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() => _cameraError = true);
        return;
      }

      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;

      setState(() {
        _isCameraReady = true;
        _cameraError = false;
      });
    } catch (e) {
      await controller?.dispose();

      if (!mounted) return;

      setState(() => _cameraError = true);

      Get.snackbar(
        'Camera Error',
        'Unable to open camera. Please check camera permission.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
      );
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      await controller.takePicture();

      if (!mounted) return;

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      if (!mounted) return;

      Get.off(
        () => AttendanceConfirmationScreen(
          isCheckOut: widget.isCheckOut,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 350),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isCapturing = false);

      Get.snackbar(
        'Capture Failed',
        'Unable to capture your photo. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = AppColors.background;
    final navy = AppColors.primary;
    final blue = AppColors.primary;
    final green = AppColors.success;
    final grey = AppColors.textSecondary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                10,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.textPrimary
                                .withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.isCheckOut
                          ? 'CHECK-OUT FACE VERIFICATION'
                          : 'FACE VERIFICATION',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // TITLE
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Column(
                children: [
                  Text(
                    widget.isCheckOut
                        ? 'Verify your face to check out'
                        : 'Verify your face',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Position your face inside the frame and capture a clear photo.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.5,
                      color: grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // CAMERA PREVIEW
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary
                            .withOpacity(0.10),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildCameraPreview(),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // BOTTOM ACTIONS
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                24,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCameraReady
                              ? green
                              : _cameraError
                                  ? AppColors.error
                                  : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _isCameraReady
                            ? 'Camera ready'
                            : _cameraError
                                ? 'Camera unavailable'
                                : 'Opening camera...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          _isCameraReady && !_isCapturing
                              ? _capturePhoto
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue,
                        disabledBackgroundColor:
                            AppColors.border,
                        foregroundColor: Colors.white,
                        disabledForegroundColor:
                            AppColors.textSecondary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(17),
                        ),
                      ),
                      child: _isCapturing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Capture & Continue',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 9),

                  Text(
                    'Make sure your face is clearly visible.',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: grey,
                      fontWeight: FontWeight.w500,
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

  Widget _buildCameraPreview() {
    if (_cameraError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_outlined,
                size: 44,
                color: AppColors.surface,
              ),
              const SizedBox(height: 12),
              Text(
                'Camera is unavailable',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.surface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Please check camera permission and try again.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.surface.withOpacity(0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraReady || _cameraController == null) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.surface,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),

        Center(
          child: Container(
            width: 220,
            height: 290,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(120),
              border: Border.all(
                color: AppColors.surface,
                width: 3,
              ),
            ),
          ),
        ),

        Positioned(
          top: 18,
          left: 18,
          right: 18,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withOpacity(0.65),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              widget.isCheckOut
                  ? 'Check-out verification'
                  : 'Check-in verification',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.surface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
