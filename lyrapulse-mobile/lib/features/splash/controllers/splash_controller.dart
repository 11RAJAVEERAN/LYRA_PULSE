import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(
      const Duration(seconds: 6),
    );

    Get.offNamed(AppRoutes.login);
  }
}