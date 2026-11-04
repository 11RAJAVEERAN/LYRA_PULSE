import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/splash/controllers/splash_controller.dart';

// Leave imports
import '../../features/leave/controllers/leave_controller.dart';
import '../../features/leave/services/leave_service.dart';

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

    // Leave Service
    if (!Get.isRegistered<LeaveService>()) {
      Get.put<LeaveService>(
        LeaveService(),
        permanent: true,
      );
    }

    // Leave Controller
    if (!Get.isRegistered<LeaveController>()) {
      Get.lazyPut<LeaveController>(
        () => LeaveController(),
        fenix: true,
      );
    }
  }
}