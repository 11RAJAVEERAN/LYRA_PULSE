import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/controllers/home_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
