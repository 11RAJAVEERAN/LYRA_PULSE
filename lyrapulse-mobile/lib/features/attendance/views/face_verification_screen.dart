
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'attendance_confirmation_screen.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> {
  CameraController? _cameraController;

  bool _cameraReady = false;
  bool _isCapturing = false;
  bool _faceCaptured = false;
  String _message = 'Look at the camera and keep your face inside the frame.';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found on this device.');
      }

      final frontCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _message = 'Look at the camera and keep your face inside the frame.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Unable to open camera. Please check camera permission.';
      });
    }
  }

  Future<void> _captureFace() async {
    final controller = _cameraController;

    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _message = 'Capturing your photo...';
    });

    try {
      await controller.stopImageStreamIfNeeded();

      final image = await controller.takePicture();

      if (!mounted) return;

      // This captures a photo only. Actual face detection and identity
      // verification must be performed separately.
      setState(() {
        _faceCaptured = true;
        _message = 'Photo captured successfully.';
      });

      Get.snackbar(
        'Photo Captured',
        'Your photo has been captured.',
        backgroundColor: const Color(0xFFE8F8EF),
        colorText: const Color(0xFF16794B),
        margin: const EdgeInsets.all(16),
      );

      debugPrint('Captured image path: ${image.path}');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Could not capture photo. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _retakePhoto() async {
    if (!mounted) return;

    setState(() {
      _faceCaptured = false;
      _message = 'Look at the camera and keep your face inside the frame.';
    });
  }

  void _continue() {
    if (!_faceCaptured) return;

    Get.to(
      () => const AttendanceConfirmationScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF19356C);
    const green = Color(0xFF18A66A);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFEFF),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 19,
                        color: navy,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Verify Your Face',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF536783),
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CAMERA PREVIEW
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFE8EDF3),
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.center,
                      children: [
                        if (_cameraReady &&
                            _cameraController != null)
                          CameraPreview(_cameraController!)
                        else
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Color(0xFF3978E8),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Opening camera...',
                                  style: GoogleFonts.poppins(
                                    color: navy,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // FACE ALIGNMENT GUIDE
                        IgnorePointer(
                          child: Center(
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 250),
                              width: 218,
                              height: 280,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _faceCaptured
                                      ? green
                                      : const Color(0xFF21AD78),
                                  width: 2,
                                ),
                                borderRadius:
                                    BorderRadius.circular(115),
                              ),
                            ),
                          ),
                        ),

                        if (_faceCaptured)
                          const Positioned(
                            top: 14,
                            right: 14,
                            child: CircleAvatar(
                              radius: 17,
                              backgroundColor: green,
                              child: Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // LIGHTING STATUS
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _faceCaptured
                        ? Icons.check_circle
                        : Icons.info,
                    color: green,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _faceCaptured
                        ? 'Photo captured'
                        : 'Keep your face clearly visible',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF536783),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // ACTION BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: !_cameraReady || _isCapturing
                      ? null
                      : _faceCaptured
                          ? _continue
                          : _captureFace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    disabledBackgroundColor:
                        const Color(0xFF9CA8BC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    _isCapturing
                        ? 'Capturing...'
                        : _faceCaptured
                            ? 'Continue'
                            : 'Capture Face',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            if (_faceCaptured)
              TextButton(
                onPressed: _retakePhoto,
                child: Text(
                  'Retake Photo',
                  style: GoogleFonts.poppins(
                    color: navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const SizedBox(height: 48),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

extension on CameraController {
  Future<void> stopImageStreamIfNeeded() async {
    if (value.isStreamingImages) {
      await stopImageStream();
    }
  }
}