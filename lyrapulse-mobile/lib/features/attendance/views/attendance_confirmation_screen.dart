import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/attendance_controller.dart';
import 'check_in_success_screen.dart';
import 'check_out_success_screen.dart';

class AttendanceConfirmationScreen extends StatefulWidget {
  final bool isCheckOut;
  final String photoPath;

  const AttendanceConfirmationScreen({
    super.key,
    this.isCheckOut = false,
    required this.photoPath,
  });

  @override
  State<AttendanceConfirmationScreen> createState() =>
      _AttendanceConfirmationScreenState();
}

class _AttendanceConfirmationScreenState
    extends State<AttendanceConfirmationScreen> {
  final ImagePicker _picker = ImagePicker();

  late XFile _capturedPhoto;

  bool _isCapturing = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const Color primary = Color(0xFF2196F3);
  static const Color background = Color(0xFFF4F8FC);

  @override
  void initState() {
    super.initState();
    _capturedPhoto = XFile(widget.photoPath);
  }

  Future<void> _takeSelfie() async {
    if (_isCapturing || _isSubmitting) return;

    setState(() {
      _isCapturing = true;
      _errorMessage = null;
    });

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (!mounted || photo == null) return;

      final file = File(photo.path);

      if (!await file.exists() || await file.length() == 0) {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'Photo not saved. Please retake.';
        });
        return;
      }

      if (!mounted) return;

      setState(() {
        _capturedPhoto = photo;
        _errorMessage = null;
      });
    } catch (e, stackTrace) {
      debugPrint('Selfie retake error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to open camera. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _confirmPhoto() async {
    if (_isCapturing || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final file = File(_capturedPhoto.path);

      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Photo is missing. Please retake your selfie.');
      }

      final AttendanceController controller =
          Get.isRegistered<AttendanceController>()
              ? Get.find<AttendanceController>()
              : Get.put(AttendanceController());

      if (widget.isCheckOut) {
        if (controller.checkInTime.value == null) {
          throw Exception('Please check in before checking out.');
        }

        await controller.checkOutNow();

        if (controller.checkOutTime.value == null) {
          throw Exception(
            'Check-out was not completed. Please try again.',
          );
        }

        if (!mounted) return;

        Get.off(() => const CheckOutSuccessScreen());
      } else {
        if (controller.checkInTime.value != null && controller.isCheckedIn) {
          throw Exception('You are already checked in.');
        }

        await controller.checkInNow();

        if (controller.checkInTime.value == null) {
          throw Exception('Check-in was not completed.');
        }

        if (!mounted) return;

        Get.off(() => const CheckInSuccessScreen());
      }
    } catch (e, stackTrace) {
      debugPrint('Confirm attendance error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildPhotoPreview() {
    return FutureBuilder<Uint8List>(
      key: ValueKey(_capturedPhoto.path),
      future: _capturedPhoto.readAsBytes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primary),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Unable to display photo. Please retake.'),
          );
        }

        return Image.memory(
          snapshot.data!,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) {
            return const Center(
              child: Text('Unable to display photo.'),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final action = widget.isCheckOut ? 'Check Out' : 'Check In';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text('$action Selfie'),
        backgroundColor: const Color(0xFF42A5F5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Verify Your Photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17365D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Make sure your face is clearly visible before continuing.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFD8E8F8),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _isCapturing
                      ? const Center(
                          child: CircularProgressIndicator(color: primary),
                        )
                      : _buildPhotoPreview(),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _isCapturing || _isSubmitting ? null : _takeSelfie,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: const BorderSide(color: primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed:
                      _isCapturing || _isSubmitting ? null : _confirmPhoto,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isSubmitting ? 'Please wait...' : 'Confirm Photo',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
