import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color navy = Color(0xFF102B63);
  static const Color blue = Color(0xFF4779D9);
  static const Color purple = Color(0xFF6254E8);
  static const Color green = Color(0xFF0BA875);
  static const Color background = Color(0xFFF5F7FD);
  static const Color muted = Color(0xFF8491AA);

  final ImagePicker _imagePicker = ImagePicker();

  File? profileImage;

  String employeeId = 'LYRA001';
  String employeeName = 'Angel';
  String phoneNumber = '+91 98765 43210';
  String emailAddress = 'employee@lyratech.com';
  String officeLocation = 'Cuddalore';
  String designation = 'Software Developer';
  String department = 'Technology';

  static const String joiningDate = '10 January 2025';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: navy,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: IconButton(
              onPressed: _showEditProfileDialog,
              icon: const Icon(
                Icons.edit_outlined,
                color: navy,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileHeader(),

              const SizedBox(height: 22),

              _sectionTitle('Personal Information'),

              const SizedBox(height: 12),

              _infoCard(
                icon: Icons.badge_outlined,
                title: 'Employee ID',
                value: employeeId,
              ),

              const SizedBox(height: 10),

              _infoCard(
                icon: Icons.phone_outlined,
                title: 'Phone Number',
                value: phoneNumber,
              ),

              const SizedBox(height: 10),

              _infoCard(
                icon: Icons.email_outlined,
                title: 'Email Address',
                value: emailAddress,
              ),

              const SizedBox(height: 10),

              _infoCard(
                icon: Icons.location_city_outlined,
                title: 'Office Location',
                value: officeLocation,
              ),

              const SizedBox(height: 24),

              _sectionTitle('Work Information'),

              const SizedBox(height: 12),

              _infoCard(
                icon: Icons.work_outline_rounded,
                title: 'Designation',
                value: designation,
              ),

              const SizedBox(height: 10),

              _infoCard(
                icon: Icons.business_outlined,
                title: 'Department',
                value: department,
              ),

              const SizedBox(height: 10),

              _infoCard(
                icon: Icons.calendar_today_outlined,
                title: 'Joining Date',
                value: joiningDate,
              ),

              const SizedBox(height: 24),

              _sectionTitle('Account'),

              const SizedBox(height: 12),

              _actionCard(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your account password',
                onTap: _showChangePasswordDialog,
              ),

              const SizedBox(height: 10),

              _actionCard(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Manage your notification preferences',
                onTap: _showNotificationsDialog,
              ),

              const SizedBox(height: 10),

              _actionCard(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out from your account',
                iconColor: Colors.redAccent,
                titleColor: Colors.redAccent,
                onTap: _showLogoutDialog,
              ),

              const SizedBox(height: 25),

              const Center(
                child: Text(
                  'LYRA PULSE',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              const Center(
                child: Text(
                  'Powered by LYRATECH',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _profileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102B63),
            Color(0xFF4779D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: navy.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: profileImage != null
                  ? Image.file(
                      profileImage!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: Colors.white,
                    ),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employeeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  designation,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  employeeId,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'Active',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: navy,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8ECF5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: blue,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION CARD
  // ============================================================

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = purple,
    Color titleColor = navy,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8ECF5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE DIALOG
  // ============================================================

  void _showEditProfileDialog() {
    final employeeIdController =
        TextEditingController(text: employeeId);

    final nameController =
        TextEditingController(text: employeeName);

    final phoneController =
        TextEditingController(text: phoneNumber);

    final emailController =
        TextEditingController(text: emailAddress);

    final locationController =
        TextEditingController(text: officeLocation);

    final designationController =
        TextEditingController(text: designation);

    final departmentController =
        TextEditingController(text: department);

    File? selectedImage = profileImage;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ------------------------------------------------
                  // TITLE
                  // ------------------------------------------------

                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: blue,
                        ),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: navy,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: muted,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // PROFILE PICTURE
                  // ------------------------------------------------

                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF0F4FF),
                                border: Border.all(
                                  color: const Color(0xFFE0E7F5),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: selectedImage != null
                                    ? Image.file(
                                        selectedImage!,
                                        width: 92,
                                        height: 92,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: blue,
                                      ),
                              ),
                            ),

                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: () async {
                                  final XFile? pickedFile =
                                      await _imagePicker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 80,
                                  );

                                  if (pickedFile != null) {
                                    setDialogState(() {
                                      selectedImage =
                                          File(pickedFile.path);
                                    });
                                  }
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: navy,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        TextButton(
                          onPressed: () async {
                            final XFile? pickedFile =
                                await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );

                            if (pickedFile != null) {
                              setDialogState(() {
                                selectedImage =
                                    File(pickedFile.path);
                              });
                            }
                          },
                          child: const Text(
                            'Change Profile Picture',
                            style: TextStyle(
                              color: blue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ------------------------------------------------
                  // EMPLOYEE ID
                  // ------------------------------------------------

                  _editField(
                    controller: employeeIdController,
                    label: 'Employee ID',
                    icon: Icons.badge_outlined,
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // NAME
                  // ------------------------------------------------

                  _editField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline_rounded,
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // PHONE
                  // ------------------------------------------------

                  _editField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // EMAIL
                  // ------------------------------------------------

                  _editField(
                    controller: emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // OFFICE LOCATION
                  // ------------------------------------------------

                  _editField(
                    controller: locationController,
                    label: 'Office Location',
                    icon: Icons.location_city_outlined,
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // DESIGNATION
                  // ------------------------------------------------

                  _editField(
                    controller: designationController,
                    label: 'Designation',
                    icon: Icons.work_outline_rounded,
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // DEPARTMENT
                  // ------------------------------------------------

                  _editField(
                    controller: departmentController,
                    label: 'Department',
                    icon: Icons.business_outlined,
                  ),

                  const SizedBox(height: 22),

                  // ------------------------------------------------
                  // SAVE
                  // ------------------------------------------------

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        if (employeeIdController.text
                                .trim()
                                .isEmpty ||
                            nameController.text.trim().isEmpty ||
                            phoneController.text.trim().isEmpty ||
                            emailController.text.trim().isEmpty ||
                            locationController.text.trim().isEmpty ||
                            designationController.text
                                .trim()
                                .isEmpty ||
                            departmentController.text
                                .trim()
                                .isEmpty) {
                          Get.snackbar(
                            'Required Fields',
                            'Please fill all fields',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: navy,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 12,
                          );
                          return;
                        }

                        setState(() {
                          profileImage = selectedImage;

                          employeeId =
                              employeeIdController.text.trim();

                          employeeName =
                              nameController.text.trim();

                          phoneNumber =
                              phoneController.text.trim();

                          emailAddress =
                              emailController.text.trim();

                          officeLocation =
                              locationController.text.trim();

                          designation =
                              designationController.text.trim();

                          department =
                              departmentController.text.trim();
                        });

                        Get.back();

                        Get.snackbar(
                          'Profile Updated',
                          'Your profile has been updated successfully.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: green,
                          colorText: Colors.white,
                          margin: const EdgeInsets.all(16),
                          borderRadius: 12,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // EDIT FIELD
  // ============================================================

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: navy,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: muted,
          fontSize: 13,
        ),
        prefixIcon: Icon(
          icon,
          color: blue,
          size: 21,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F9FD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE8ECF5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFE8ECF5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: blue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Password',
                style: TextStyle(
                  color: navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      Get.snackbar(
                        'Password Error',
                        'New password and confirm password do not match.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.redAccent,
                        colorText: Colors.white,
                        margin: const EdgeInsets.all(16),
                      );
                      return;
                    }

                    Get.back();

                    Get.snackbar(
                      'Success',
                      'Password updated successfully.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: green,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Password',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  void _showNotificationsDialog() {
    bool notificationsEnabled = true;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Attendance and permission notifications',
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                    ),
                  ),
                ),
                Switch(
                  value: notificationsEnabled,
                  onChanged: (value) {
                    setDialogState(() {
                      notificationsEnabled = value;
                    });
                  },
                  activeColor: blue,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: Get.back,
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: muted,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.offAllNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}