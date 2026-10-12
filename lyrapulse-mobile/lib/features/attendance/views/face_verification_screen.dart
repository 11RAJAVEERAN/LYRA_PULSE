import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  CameraController? _cameraController;
  XFile? _capturedPhoto;

  bool _isCameraReady = false;
  bool _isCapturing = false;

  static const Color _background = Color(0xFFF7FAFE);
  static const Color _navy = Color(0xFF19356C);
  static const Color _blue = Color(0xFF3978E8);
  static const Color _green = Color(0xFF18A66A);
  static const Color _grey = Color(0xFF7B879B);

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        if (mounted) {
          _showMessage(
            'Camera Unavailable',
            'No camera was found on this device.',
          );
        }
        return;
      }

      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraReady = true;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Camera Error',
        'Unable to open camera. Please check camera permission.',
      );
    }
  }

  // Capture photo and show its preview.
  // Do not navigate to the next screen here.
  Future<void> _capturePhoto() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        _capturedPhoto != null) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final photo = await controller.takePicture();

      if (!mounted) return;

      setState(() {
        _capturedPhoto = photo;
        _isCapturing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCapturing = false;
      });

      _showMessage(
        'Capture Failed',
        'Unable to capture your photo. Please try again.',
      );
    }
  }

  // Clear the captured photo so the user can take another one.
  Future<void> _retakePhoto() async {
    setState(() {
      _capturedPhoto = null;
    });

    final controller = _cameraController;

    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      if (controller.value.isPreviewPaused) {
        await controller.resumePreview();
      }
    } catch (_) {
      // Keep the screen available if the preview is already running.
    }
  }

  // Navigate only after the user taps Confirm.
  void _confirmPhoto() {
    if (_capturedPhoto == null) return;

    Get.off(
      () => AttendanceConfirmationScreen(
        isCheckOut: widget.isCheckOut,
      ),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      colorText: _navy,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasCapturedPhoto = _capturedPhoto != null;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            // Top navigation bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: _navy,
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
                        color: _navy,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Heading and instruction
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    hasCapturedPhoto
                        ? 'Is this photo clear?'
                        : widget.isCheckOut
                            ? 'Verify your face to check out'
                            : 'Verify your face',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    hasCapturedPhoto
                        ? 'Retake the photo if needed, or confirm to continue.'
                        : 'Position your face inside the frame and capture a clear photo.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      height: 1.5,
                      color: _grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Camera preview or captured photo preview
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildCameraPreview(hasCapturedPhoto),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Camera status and action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                          color: hasCapturedPhoto
                              ? _green
                              : _isCameraReady
                                  ? _green
                                  : _blue,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        hasCapturedPhoto
                            ? 'Photo captured successfully'
                            : _isCameraReady
                                ? 'Camera ready'
                                : 'Opening camera...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Show Retake and Confirm only after capturing.
                  if (hasCapturedPhoto)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _retakePhoto,
                              icon: const Icon(
                                Icons.refresh_rounded,
                              ),
                              label: Text(
                                'Retake',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _navy,
                                side: const BorderSide(
                                  color: _navy,
                                  width: 1.3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _confirmPhoto,
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                              ),
                              label: Text(
                                'Confirm',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _navy,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isCameraReady && !_isCapturing
                            ? _capturePhoto
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          disabledBackgroundColor: Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: _isCapturing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Capture Photo',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                  const SizedBox(height: 9),

                  Text(
                    hasCapturedPhoto
                        ? 'Your photo will be submitted after you confirm.'
                        : 'Make sure your face is clearly visible.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: _grey,
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

  Widget _buildCameraPreview(bool hasCapturedPhoto) {
    // Display the photo after Capture Photo is tapped.
    if (hasCapturedPhoto) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(_capturedPhoto!.path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              );
            },
          ),

          Center(
            child: Container(
              width: 220,
              height: 290,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(120),
                border: Border.all(
                  color: Colors.white,
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
                color: Colors.black.withOpacity(0.50),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Photo preview',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show the live camera preview before capturing.
    if (!_isCameraReady || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: Colors.white,
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
                color: Colors.white,
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
              color: Colors.black.withOpacity(0.45),
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
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 