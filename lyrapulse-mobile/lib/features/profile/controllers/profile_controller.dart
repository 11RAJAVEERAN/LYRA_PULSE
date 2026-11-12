import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../data/models/employee_model.dart';
import '../../../core/widgets/app_snackbar.dart';

class ProfileController extends GetxController {
  final _authController = Get.find<AuthController>();

  final isRefreshing = false.obs;
  final refreshError = RxnString();
  final selectedTab = 0.obs;
  final selectedImagePath = ''.obs;
  final isSaving = false.obs;

  final fullName = 'Not available'.obs;
  final phoneNumber = 'Not available'.obs;
  final address = 'Not available'.obs;
  final employeeId = 'Not available'.obs;
  final organization = 'Not available'.obs;
  final designation = 'Not available'.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  Worker? _employeeWorker;

  EmployeeModel? get employee => _authController.employee.value;
  RxBool get isLoggingOut => _authController.isLoggingOut;

  @override
  void onInit() {
    super.onInit();
    _syncEmployee();
    _employeeWorker = ever<EmployeeModel?>(
      _authController.employee,
      (_) => _syncEmployee(),
    );
  }

  void _syncEmployee() {
    final value = employee;
    fullName.value = value?.name.isNotEmpty == true
        ? value!.name
        : 'Not available';
    phoneNumber.value = value?.phoneNumber.isNotEmpty == true
        ? value!.phoneNumber
        : 'Not available';
    address.value = value?.address.isNotEmpty == true
        ? value!.address
        : 'Not available';
    employeeId.value = value?.employeeCode.isNotEmpty == true
        ? value!.employeeCode
        : 'Not available';
    designation.value = value?.designation?.isNotEmpty == true
        ? value!.designation!
        : 'Not available';
    // The current employee profile contract contains no organization field.
    organization.value = 'Not available';
  }

  void changeTab(int index) => selectedTab.value = index;

  Future<void> pickProfileImage() async {
    AppSnackbar.show('Profile photo upload is not available in Project A.');
  }

  void openEditProfile() {
    AppSnackbar.show('Profile editing is not available in Project A.');
  }

  void saveProfile() {
    AppSnackbar.show('Profile editing is not available in Project A.');
  }

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

  @override
  void onClose() {
    _employeeWorker?.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }
}
