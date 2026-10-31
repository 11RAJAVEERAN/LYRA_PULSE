import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class ProfileController extends GetxController {
  // Profile details - API ready ஆகும் வரை local data.
  final fullName = 'Madhavan'.obs;
  final phoneNumber = 'Not Available'.obs;
  final address = 'Not Available'.obs;

  final employeeId = '118'.obs;
  final organization = 'Lyra Tech'.obs;
  final designation = 'Not Available'.obs;

  final selectedTab = 0.obs;
  final selectedImagePath = ''.obs;

  final isSaving = false.obs;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  void changeTab(int index) {
    selectedTab.value = index;
  }

  Future<void> pickProfileImage() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (image != null) {
        selectedImagePath.value = image.path;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unable to select image',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void openEditProfile() {
    nameController.text = fullName.value;
    phoneController.text =
        phoneNumber.value == 'Not Available' ? '' : phoneNumber.value;
    addressController.text =
        address.value == 'Not Available' ? '' : address.value;

    Get.bottomSheet(
      _editSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _editSheet() {
    return Container(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 24,
        bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172B3A),
              ),
            ),
            const SizedBox(height: 22),
            _editField('Full Name', nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _editField('Phone Number', phoneController, Icons.phone_outlined),
            const SizedBox(height: 16),
            _editField('Address', addressController, Icons.location_on_outlined),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Obx(
                () => ElevatedButton(
                  onPressed: isSaving.value ? null : saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF172554),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSaving.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF5F7FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  void saveProfile() {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Validation', 'Name is required');
      return;
    }

    fullName.value = nameController.text.trim();

    phoneNumber.value = phoneController.text.trim().isEmpty
        ? 'Not Available'
        : phoneController.text.trim();

    address.value = addressController.text.trim().isEmpty
        ? 'Not Available'
        : addressController.text.trim();

    Get.back();

    Get.snackbar(
      'Success',
      'Profile updated successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }
}