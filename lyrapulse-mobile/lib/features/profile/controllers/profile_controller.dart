import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/employee_model.dart';

class ProfileController extends GetxController {
  final _authController = Get.find<AuthController>();

  final isRefreshing = false.obs;
  final refreshError = RxnString();

  EmployeeModel? get employee => _authController.employee.value;
  RxBool get isLoggingOut => _authController.isLoggingOut;

  Future<void> refreshProfile() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;
    refreshError.value = null;
    try {
      await _authController.reloadEmployeeProfile();
    } catch (error) {
      refreshError.value = _authController.errorMessage(error);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> logout() => _authController.logout();
}
