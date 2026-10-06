
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/employee_model.dart';

class ProfileController extends GetxController {
  final _authController = Get.find<AuthController>();

  EmployeeModel? get employee => _authController.employee.value;
  RxBool get isLoggingOut => _authController.isLoggingOut;

  Future<void> logout() => _authController.logout();
}