import 'package:get/get.dart';

import '../../attendance/controllers/attendance_controller.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AttendanceController>()) {
      Get.put(
        AttendanceController(),
        permanent: true,
      );
    }

    Get.lazyPut<HomeController>(
      () => HomeController(),
    );
  }
}