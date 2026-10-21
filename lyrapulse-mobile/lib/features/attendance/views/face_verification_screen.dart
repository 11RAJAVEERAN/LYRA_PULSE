
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  String? _cameraError;

  static const Color primary = Color(0xFF2878E5);
  static const Color navy = Color(0xFF172B4D);
  static const Color secondary = Color(0xFF71829B);
  static const Color background = Color(0xFFF8FAFD);
  static const Color borderColor = Color(0xFFE5EBF3);

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
        setState(() {
          _cameraError = 'No camera found on this device.';
        });
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
        ResolutionPreset.high,
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
        _cameraError = null;
      });
    } catch (e, stackTrace) {
      debugPrint('Camera initialization error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (controller != null) {
        await controller.dispose();
      }

      if (!mounted) return;

      setState(() {
        _isCameraReady = false;
        _cameraError =
            'Unable to open camera. Please check camera permission.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _cameraError = null;
    });

    try {
      // Capture selfie from the live front camera.
      final XFile photo = await controller.takePicture();

      final file = File(photo.path);

      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Captured photo is empty.');
      }

      if (!mounted) return;

      // Stop the camera before navigating to the preview screen.
      _cameraController = null;
      _isCameraReady = false;

      await controller.dispose();

      if (!mounted) return;

      // Pass the exact captured image path to the next screen.
      // Do not open the camera again on the confirmation screen.
      await Get.to(
        () => AttendanceConfirmationScreen(
          isCheckOut: widget.isCheckOut,
          photoPath: photo.path,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );

      if (!mounted) return;

      // Reopen camera when user returns to this screen.
      setState(() {
        _isCapturing = false;
      });

      await _initializeCamera();
    } catch (e, stackTrace) {
      debugPrint('Selfie capture error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isCapturing = false;
        _cameraError = 'Photo capture failed. Please try again.';
      });

      if (_cameraController == null) {
        await _initializeCamera();
      }
    }
  }

  @override
  void dispose() {
    final controller = _cameraController;
    _cameraController = null;
    controller?.dispose();
    super.dispose();
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController;

    if (!_isCameraReady ||
        controller == null ||
        !controller.value.isInitialized) {
      return Center(
        child: _cameraError != null
            ? const Icon(
                Icons.no_photography_outlined,
                size: 42,
                color: secondary,
              )
            : const CircularProgressIndicator(
                color: primary,
                strokeWidth: 2.5,
              ),
      );
    }

    final previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.sizeOf(context).height;

    final double cameraHeight =
        (screenHeight * 0.43).clamp(250.0, 390.0).toDouble();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: navy,
          ),
        ),
        title: const Text(
          'Lyra Pulse',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: navy,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(
              Icons.verified_user_outlined,
              color: primary,
              size: 23,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Face verification',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Position your face inside the frame and capture a clear photo.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: secondary,
                ),
              ),
              const SizedBox(height: 20),

              // Live selfie camera preview.
              Container(
                height: cameraHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF5),
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCameraPreview(),

                    if (_isCameraReady)
                      Center(
                        child: IgnorePointer(
                          child: SizedBox(
                            width: 175,
                            height: 215,
                            child: CustomPaint(
                              painter: FaceFramePainter(),
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      top: 14,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isCameraReady
                                    ? const Color(0xFF22A06B)
                                    : Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _isCameraReady
                                  ? 'Camera ready'
                                  : 'Starting camera',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Guidance card.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF3FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.wb_sunny_outlined,
                        color: primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep your face steady',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: navy,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Ensure good lighting and keep your face clearly visible.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (_cameraError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _cameraError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _cameraError = null;
                      _isCameraReady = false;
                    });
                    await _initializeCamera();
                  },
                  child: const Text('Try camera again'),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isCameraReady && !_isCapturing
                      ? _capturePhoto
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFB8C8DE),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: _isCapturing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 20),
                            SizedBox(width: 9),
                            Text(
                              'Capture & Continue',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'LYRA PULSE  •  EMPLOYEE ATTENDANCE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF96A3B5),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FaceFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF82BDFF)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double length = 30;
    const double radius = 25;

    canvas.drawPath(
      Path()
        ..moveTo(0, length)
        ..lineTo(0, radius)
        ..quadraticBezierTo(0, 0, radius, 0)
        ..lineTo(length, 0),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - length, 0)
        ..lineTo(size.width - radius, 0)
        ..quadraticBezierTo(size.width, 0, size.width, radius)
        ..lineTo(size.width, length),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - length)
        ..lineTo(0, size.height - radius)
        ..quadraticBezierTo(0, size.height, radius, size.height)
        ..lineTo(length, size.height),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(size.width - length, size.height)
        ..lineTo(size.width - radius, size.height)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width,
          size.height - radius,
        )
        ..lineTo(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant FaceFramePainter oldDelegate) => false;
}
