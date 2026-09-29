import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/splash/controllers/splash_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(
      SplashController(),
      permanent: true,
    );

    Get.put<AuthController>(
      AuthController(),
      permanent: true,
    );

    Get.put<HomeController>(
      HomeController(),
      permanent: true,
    );
  }
}