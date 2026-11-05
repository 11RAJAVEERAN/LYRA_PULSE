import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';

abstract final class AppSnackbar {
  static void show(String message) {
    Get.snackbar(
      'Lyra Pulse',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      backgroundColor: AppColors.primaryDark,
      colorText: Colors.white,
      icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
    );
  }
}
