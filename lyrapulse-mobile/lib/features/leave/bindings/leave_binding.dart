import 'package:get/get.dart';

import '../controllers/leave_controller.dart';
import '../services/leave_service.dart';

class LeaveBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LeaveService>()) {
      Get.put<LeaveService>(
        LeaveService(),
        permanent: true,
      );
    }

    if (!Get.isRegistered<LeaveController>()) {
      Get.lazyPut<LeaveController>(
        () => LeaveController(),
        fenix: true,
      );
    }
  }
}