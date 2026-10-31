
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/profile_controller.dart';

class ProfileTabBar extends GetView<ProfileController> {
  const ProfileTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Row(
        children: [
          _tab('Personal Info', 0),
          _tab('Professional Info', 1),
        ],
      );
    });
  }

  Widget _tab(String title, int index) {
    final selected = controller.selectedTab.value == index;

    return Expanded(
      child: InkWell(
        onTap: () => controller.changeTab(index),
        child: Container(
          height: 65,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? AppColors.primaryBlue
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? AppColors.textPrimary
                    : Colors.blueGrey.shade300,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
