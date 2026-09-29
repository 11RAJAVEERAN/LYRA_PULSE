import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    unawaited(_restoreAndNavigate());
  }

  Future<void> _restoreAndNavigate() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    final restored = await Get.find<AuthController>().restoreSession();
    Get.offAllNamed(restored ? AppRoutes.home : AppRoutes.login);
  }
}
