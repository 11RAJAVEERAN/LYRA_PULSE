import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/profile_controller.dart';

class ProfileAvatar extends GetView<ProfileController> {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final path = controller.selectedImagePath.value;

      return Stack(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundColor: AppColors.surface,
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.secondarySoft,
              backgroundImage: path.isNotEmpty ? FileImage(File(path)) : null,
              child: path.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 58,
                      color: AppColors.primaryDark,
                    )
                  : null,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: controller.pickProfileImage,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 12,
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}