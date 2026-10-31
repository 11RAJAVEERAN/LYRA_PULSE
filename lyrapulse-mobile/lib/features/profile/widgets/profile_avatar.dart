
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/profile_controller.dart';

class ProfileAvatar extends GetView<ProfileController> {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      color: const Color(0xFFE3F2FD),
      child: Center(
        child: Obx(() {
          final localPath = controller.selectedImagePath.value;

          ImageProvider? imageProvider;

          if (localPath.isNotEmpty) {
            imageProvider = FileImage(File(localPath));
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueGrey.shade300,
                  border: Border.all(
                    color: AppColors.accent,
                    width: 4,
                  ),
                  image: imageProvider != null
                      ? DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageProvider == null
                    ? const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 100,
                      )
                    : null,
              ),
              Positioned(
                right: -5,
                bottom: -5,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: IconButton(
                    onPressed: controller.pickProfileImage,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
