import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import '../widgets/profile_content.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      body: SafeArea(
        child: Obx(
          () => ProfileContent(
            userName: controller.userName.value,
            employeeId: controller.employeeId.value,
            designation: controller.designation.value,
            phoneNumber: controller.phoneNumber.value,
            department: controller.department.value,
            onEditProfile: controller.editProfile,
            onLogout: controller.logout,
          ),
        ),
      ),
    );
  }
}