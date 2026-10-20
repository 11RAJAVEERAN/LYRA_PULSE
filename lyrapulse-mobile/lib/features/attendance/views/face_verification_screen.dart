
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
          _cameraError = 'No camera was found on this device.';
        });
        return;
      }

      var selectedCamera = cameras.first;

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
        _cameraError = null;
      });
    } catch (e) {
      await controller?.dispose();

      if (!mounted) return;

      setState(() {
        _isCameraReady = false;
        _cameraError =
            'Unable to open camera. Check camera permission and try again.';
      });
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
      final XFile photo = await controller.takePicture();

      if (!mounted) return;

      debugPrint('Captured photo: ${photo.path}');

      Get.off(
        () => AttendanceConfirmationScreen(
          isCheckOut: widget.isCheckOut,
        ),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isCapturing = false);

      Get.snackbar(
        'Photo capture failed',
        'Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        colorText: navy,
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  TextStyle _style({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = navy,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    final cameraHeight =
        (screenHeight * 0.43).clamp(250.0, 390.0).toDouble();

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: navy,
          ),
        ),
        title: Text(
          'Lyra Pulse',
          style: _style(
            size: 19,
            weight: FontWeight.w700,
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isCheckOut
                    ? 'Check-out verification'
                    : 'Face verification',
                style: _style(
                  size: 25,
                  weight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Position your face inside the frame '
                'and capture a clear photo.',
                style: _style(
                  size: 14,
                  color: secondary,
                ).copyWith(height: 1.5),
              ),

              const SizedBox(height: 22),

              // Camera preview
              Container(
                height: cameraHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEF5),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: borderColor,
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCameraPreview(),

                    if (_isCameraReady)
                      const Center(
                        child: IgnorePointer(
                          child: SizedBox(
                            width: 205,
                            height: 255,
                            child: CustomPaint(
                              painter: FaceFramePainter(),
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _isCameraReady
                                    ? const Color(0xFF22A06B)
                                    : _cameraError != null
                                        ? Colors.redAccent
                                        : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              _isCameraReady
                                  ? 'Camera ready'
                                  : _cameraError != null
                                      ? 'Camera unavailable'
                                      : 'Starting camera',
                              style: _style(
                                size: 11,
                                weight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Simple professional instruction
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep your face steady',
                            style: _style(
                              size: 14,
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Ensure good lighting and keep '
                            'your face clearly visible.',
                            style: _style(
                              size: 12,
                              color: secondary,
                            ).copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isCameraReady && !_isCapturing
                          ? _capturePhoto
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor:
                        const Color(0xFFB8C8DE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isCapturing
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt_outlined,
                              size: 21,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Capture & Continue',
                              style: _style(
                                size: 14,
                                weight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              if (_cameraError != null) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _cameraError = null;
                      _isCameraReady = false;
                    });
                    _initializeCamera();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try camera again'),
                ),
              ],

              const SizedBox(height: 14),

              Text(
                'LYRA PULSE  •  EMPLOYEE ATTENDANCE',
                textAlign: TextAlign.center,
                style: _style(
                  size: 10,
                  weight: FontWeight.w600,
                  color: const Color(0xFF96A3B5),
                ).copyWith(letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraError != null) {
      return Container(
        color: const Color(0xFFF0F5FB),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                size: 42,
                color: secondary,
              ),
              const SizedBox(height: 12),
              Text(
                _cameraError!,
                textAlign: TextAlign.center,
                style: _style(
                  size: 13,
                  color: secondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isCameraReady || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: primary,
          strokeWidth: 2.5,
        ),
      );
    }

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize!.height,
            height: _cameraController!.value.previewSize!.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }
}

class FaceFramePainter extends CustomPainter {
  const FaceFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF82BDFF)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const cornerLength = 34.0;
    const radius = 28.0;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, radius)
        ..quadraticBezierTo(0, 0, radius, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - radius, 0)
        ..quadraticBezierTo(
          size.width,
          0,
          size.width,
          radius,
        )
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height - radius)
        ..quadraticBezierTo(
          0,
          size.height,
          radius,
          size.height,
        )
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width - radius, size.height)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width,
          size.height - radius,
        )
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant FaceFramePainter oldDelegate) => false;
}
