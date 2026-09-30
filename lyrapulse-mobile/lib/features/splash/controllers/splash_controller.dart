import 'dart:async';
import 'package:get/get.dart';

class SplashController extends GetxController {
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();

    _timer = Timer(const Duration(seconds: 3), () {
      Get.offNamed('/login');
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}