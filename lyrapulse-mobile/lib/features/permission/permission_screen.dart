import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'views/permission_submitted_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  String selectedType = 'Personal';

  final TextEditingController reasonController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  TimeOfDay? startTime;
  TimeOfDay? returnTime;

  @override
  void dispose() {
    reasonController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        startTime = picked;
      });
    }
  }

  Future<void> _selectReturnTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        returnTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return 'Select time';
    }

    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  void _submitPermission() {
    if (reasonController.text.trim().isEmpty) {
      Get.snackbar(
        'Reason Required',
        'Please enter the reason for your permission.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF172B4D),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    if (startTime == null) {
      Get.snackbar(
        'Start Time Required',
        'Please select your permission start time.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF172B4D),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    if (returnTime == null) {
      Get.snackbar(
        'Return Time Required',
        'Please select your expected return time.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: const Color(0xFF172B4D),
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    Get.to(
      () => const PermissionSubmittedScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFE),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAFE),
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF172B4D),
            size: 20,
          ),
        ),

        title: const Text(
          'Request Permission',
          style: TextStyle(
            color: Color(0xFF172B4D),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.directions_walk_rounded,
                        color: Color(0xFF1687D9),
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Office Permission',
                            style: TextStyle(
                              color: Color(0xFF172B4D),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Request permission before leaving the office.',
                            style: TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Permission Type
              const Text(
                'Permission Type',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      title: 'Personal',
                      icon: Icons.person_outline_rounded,
                      selected: selectedType == 'Personal',
                      onTap: () {
                        setState(() {
                          selectedType = 'Personal';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeButton(
                      title: 'Official',
                      icon: Icons.business_center_outlined,
                      selected: selectedType == 'Official Work',
                      onTap: () {
                        setState(() {
                          selectedType = 'Official Work';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeButton(
                      title: 'Emergency',
                      icon: Icons.warning_amber_rounded,
                      selected: selectedType == 'Emergency',
                      onTap: () {
                        setState(() {
                          selectedType = 'Emergency';
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Reason
              const Text(
                'Reason',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              _InputBox(
                controller: reasonController,
                hint: 'Why are you leaving the office?',
                icon: Icons.edit_note_rounded,
                maxLines: 4,
              ),

              const SizedBox(height: 24),

              // Start Time
              const Text(
                'Permission Start Time',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              _TimeBox(
                value: _formatTime(startTime),
                icon: Icons.login_rounded,
                onTap: _selectStartTime,
              ),

              const SizedBox(height: 24),

              // Return Time
              const Text(
                'Expected Return Time',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              _TimeBox(
                value: _formatTime(returnTime),
                icon: Icons.logout_rounded,
                onTap: _selectReturnTime,
              ),

              const SizedBox(height: 24),

              // Optional Note
              const Text(
                'Additional Note',
                style: TextStyle(
                  color: Color(0xFF172B4D),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              _InputBox(
                controller: noteController,
                hint: 'Add any additional information (optional)',
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9F4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF22A06B),
                      size: 21,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your permission request will be sent for approval. '
                        'Please return to the office within the approved time.',
                        style: TextStyle(
                          color: Color(0xFF246B4A),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _submitPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1687D9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Submit Permission',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Permission Type Button
// ------------------------------------------------------------

class _TypeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8F5FF)
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? const Color(0xFF1687D9)
                : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF1687D9)
                  : const Color(0xFF718096),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF1687D9)
                    : const Color(0xFF4A5568),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Input Box
// ------------------------------------------------------------

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _InputBox({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          color: Color(0xFF172B4D),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFA0AEC0),
            fontSize: 13,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(
              left: 14,
              right: 10,
              top: 12,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8A98A9),
              size: 21,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 45,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Time Box
// ------------------------------------------------------------

class _TimeBox extends StatelessWidget {
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeBox({
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value != 'Select time';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF1687D9),
              size: 21,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF172B4D)
                      : const Color(0xFFA0AEC0),
                  fontSize: 14,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            const Icon(
              Icons.access_time_rounded,
              color: Color(0xFF8A98A9),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}