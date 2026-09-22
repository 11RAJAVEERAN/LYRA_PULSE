import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    Future<void>.delayed(
        const Duration(seconds: 6), () => Get.offNamed(AppRoutes.login));
  }
}
