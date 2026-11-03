import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  static const Color navy = Color(0xFF172554);
  static const Color background = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: navy,
            size: 20,
          ),
        ),
        title: Text(
          'My Profile',
          style: GoogleFonts.inter(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _profileHeader(),
            const SizedBox(height: 22),
            _profileTabs(),
            const SizedBox(height: 18),
            _profileDetails(),
            const SizedBox(height: 20),
            _editButton(),
            const SizedBox(height: 35),
          ],
        ),
      ),
    );
  }

  // PROFILE HEADER
  Widget _profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF101D49),
            Color(0xFF263D85),
            Color(0xFF4F46A5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Obx(
                () => CircleAvatar(
                  radius: 52,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFFE0E7FF),
                    backgroundImage: controller.selectedImagePath.value.isEmpty
                        ? null
                        : FileImage(
                            File(controller.selectedImagePath.value),
                          ),
                    child: controller.selectedImagePath.value.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 58,
                            color: Color(0xFF334A91),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                right: 2,
                bottom: 2,
                child: GestureDetector(
                  onTap: controller.pickProfileImage,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.fullName.value,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Obx(
            () => Text(
              'Employee ID: ${controller.employeeId.value}',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Obx(
              () => Text(
                controller.designation.value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PROFILE TABS
  Widget _profileTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(
        () => Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              _tabButton('Personal Info', 0),
              _tabButton('Professional Info', 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    final selected = controller.selectedTab.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? navy : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // PROFILE DETAILS
  Widget _profileDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(
        () {
          if (controller.selectedTab.value == 0) {
            return _infoCard(
              title: 'Personal Information',
              items: [
                _InfoItem(
                  icon: Icons.person_outline,
                  title: 'Full Name',
                  value: controller.fullName.value,
                ),
                _InfoItem(
                  icon: Icons.phone_outlined,
                  title: 'Phone Number',
                  value: controller.phoneNumber.value,
                ),
                _InfoItem(
                  icon: Icons.location_on_outlined,
                  title: 'Address',
                  value: controller.address.value,
                ),
              ],
            );
          }

          return _infoCard(
            title: 'Professional Information',
            items: [
              _InfoItem(
                icon: Icons.badge_outlined,
                title: 'Employee ID',
                value: controller.employeeId.value,
              ),
              _InfoItem(
                icon: Icons.apartment_outlined,
                title: 'Organization',
                value: controller.organization.value,
              ),
              _InfoItem(
                icon: Icons.work_outline,
                title: 'Designation',
                value: controller.designation.value,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required List<_InfoItem> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: navy,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(items.length, (index) {
            final item = items[index];

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: const Color(0xFF334A91),
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item.value,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF172B3A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index != items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: Colors.grey.shade100,
                      height: 1,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // EDIT BUTTON
  Widget _editButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: controller.openEditProfile,
          icon: const Icon(Icons.edit_outlined),
          label: Text(
            'Edit Profile',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String title;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });
}