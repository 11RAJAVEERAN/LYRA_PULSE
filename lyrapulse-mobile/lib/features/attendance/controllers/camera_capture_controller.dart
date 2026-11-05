import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/app_snackbar.dart';
import 'attendance_controller.dart';

/// Owns the camera device for the attendance photo. The captured file path is
/// handed to [AttendanceController]; the camera is camera-only (no gallery).
class CameraCaptureController extends GetxController with WidgetsBindingObserver {
  static const int _maxPhotoBytes = 5 * 1024 * 1024; // matches the backend limit

  final _attendance = Get.find<AttendanceController>();

  final camera = Rxn<CameraController>();
  final isReady = false.obs;
  final isCapturing = false.obs;
  final errorMessage = RxnString();

  bool _initializing = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    initCamera();
  }

  Future<void> initCamera() async {
    if (_initializing) return;
    _initializing = true;
    isReady.value = false;
    errorMessage.value = null;
    await _disposeCamera();
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage.value = 'No camera was found on this device.';
        return;
      }
      final selected = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (isClosed) {
        await controller.dispose();
        return;
      }
      camera.value = controller;
      isReady.value = true;
    } on CameraException catch (error) {
      errorMessage.value = _messageFor(error);
    } catch (_) {
      errorMessage.value = 'Unable to start the camera. Please try again.';
    } finally {
      _initializing = false;
    }
  }

  Future<void> capture() async {
    final controller = camera.value;
    if (controller == null || !controller.value.isInitialized || isCapturing.value || controller.value.isTakingPicture) {
      return;
    }
    isCapturing.value = true;
    try {
      final file = await controller.takePicture();
      if (await File(file.path).length() > _maxPhotoBytes) {
        await File(file.path).delete();
        AppSnackbar.show('The photo is too large. Please try again.');
        return;
      }
      _attendance.setPhoto(file.path);
      Get.toNamed(AppRoutes.attendanceConfirm);
    } on CameraException {
      AppSnackbar.show('Unable to capture your photo. Please try again.');
    } finally {
      isCapturing.value = false;
    }
  }

  Future<void> openSettings() => _attendance.openAppSettings();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_initializing || isClosed) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      isReady.value = false;
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && camera.value == null) {
      initCamera();
    }
  }

  Future<void> _disposeCamera() async {
    final controller = camera.value;
    camera.value = null;
    await controller?.dispose();
  }

  static String _messageFor(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
        return 'Camera permission is required to take your attendance photo.';
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
        return 'Camera access is blocked. Enable it for Lyra Pulse in the app settings.';
      default:
        return 'Unable to start the camera. Please try again.';
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.onClose();
  }
}
