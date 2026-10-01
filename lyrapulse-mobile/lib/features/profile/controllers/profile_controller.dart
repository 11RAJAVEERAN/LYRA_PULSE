import 'package:get/get.dart';

class ProfileController extends GetxController {
  final userName = 'User Name'.obs;
  final employeeId = 'EMP001'.obs;
  final designation = 'Staff'.obs;
  final phoneNumber = '+91 98765 43210'.obs;
  final department = 'Front Office'.obs;

  void editProfile() {
    // Profile edit will be connected later.
  }

  void logout() {
    // Logout API and navigation will be connected later.
  }
}