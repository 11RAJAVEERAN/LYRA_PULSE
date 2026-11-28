
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/profile_controller.dart';
import 'profile_info_card.dart';

class ProfileContent extends GetView<ProfileController> {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.selectedTab.value == 0) {
        return ProfileInfoCard(
          items: [
            ProfileInfoItem(
              icon: Icons.person_outline,
              title: 'Full Name',
              value: controller.fullName.value,
            ),
            ProfileInfoItem(
              icon: Icons.phone_outlined,
              title: 'Phone Number',
              value: controller.phoneNumber.value,
            ),
            ProfileInfoItem(
              icon: Icons.email_outlined,
              title: 'Email Address',
              value: controller.email.value,
            ),
            ProfileInfoItem(
              icon: Icons.location_on_outlined,
              title: 'Address',
              value: controller.address.value,
            ),
            ProfileInfoItem(
              icon: Icons.cake_outlined,
              title: 'Date of Birth',
              value: controller.dateOfBirth.value,
            ),
            ProfileInfoItem(
              icon: Icons.person_pin_outlined,
              title: 'Gender',
              value: controller.gender.value,
            ),
          ],
        );
      }

      return ProfileInfoCard(
        items: [
          ProfileInfoItem(
            icon: Icons.badge_outlined,
            title: 'Employee ID',
            value: controller.employeeId.value,
          ),
          ProfileInfoItem(
            icon: Icons.apartment_outlined,
            title: 'Branch',
            value: controller.branch.value,
          ),
          ProfileInfoItem(
            icon: Icons.groups_outlined,
            title: 'Department',
            value: controller.department.value,
          ),
          ProfileInfoItem(
            icon: Icons.work_outline,
            title: 'Designation',
            value: controller.designation.value,
          ),
          ProfileInfoItem(
            icon: Icons.event_outlined,
            title: 'Date of Joining',
            value: controller.joiningDate.value,
          ),
        ],
      );
    });
  }
}
