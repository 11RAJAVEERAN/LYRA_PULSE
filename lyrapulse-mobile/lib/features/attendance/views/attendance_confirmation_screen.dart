import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'check_in_success_screen.dart';
import 'check_out_success_screen.dart';
import '../controllers/attendance_controller.dart';

class AttendanceConfirmationScreen extends StatelessWidget {
  final bool isCheckOut;

  const AttendanceConfirmationScreen({
    super.key,
    this.isCheckOut = false,
  });

  static const Color background = Color(0xFFF7FAFE);
  static const Color navy = Color(0xFF19356C);
  static const Color blue = Color(0xFF3978E8);
  static const Color green = Color(0xFF18A66A);
  static const Color textDark = Color(0xFF172B4D);
  static const Color textGrey = Color(0xFF718096);

  // ================================================================
  // CONFIRM ATTENDANCE
  // ================================================================

  void _confirmAttendance() {
    final attendanceController =
        Get.put(AttendanceController(), permanent: true);

    if (isCheckOut) {
      // ------------------------------------------------------------
      // CHECK OUT
      // ------------------------------------------------------------

      if (attendanceController.checkInTime.value == null) {
        Get.snackbar(
          'Check In Required',
          'Please complete your check in before checking out.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: navy,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      attendanceController.checkOutNow();

      Get.to(
        () => const CheckOutSuccessScreen(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 350),
      );
    } else {
      // ------------------------------------------------------------
      // CHECK IN
      // ------------------------------------------------------------

      attendanceController.checkInNow();

      Get.to(
        () => const CheckInSuccessScreen(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 350),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // ==========================================================
              // TOP BAR
              // ==========================================================

              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Get.back();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: navy,
                      ),
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Text(
                        isCheckOut
                            ? 'Check Out Confirmation'
                            : 'Attendance Confirmation',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: navy,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 44),
                ],
              ),

              const SizedBox(height: 30),

              // ==========================================================
              // STATUS ICON
              // ==========================================================

              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: blue.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: blue.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCheckOut
                        ? Icons.logout_rounded
                        : Icons.login_rounded,
                    color: blue,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // ==========================================================
              // TITLE
              // ==========================================================

              Text(
                isCheckOut ? 'CHECK OUT READY' : 'CHECK IN READY',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: textDark,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                isCheckOut
                    ? 'Please review your details before\nconfirming your check out.'
                    : 'Please review your details before\nconfirming your attendance.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: textGrey,
                ),
              ),

              const SizedBox(height: 28),

              // ==========================================================
              // EMPLOYEE DETAILS
              // ==========================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.045),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Employee Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const _DetailRow(
                      icon: Icons.person_rounded,
                      title: 'Employee Name',
                      value: 'Employee',
                    ),

                    const SizedBox(height: 16),

                    const _DetailRow(
                      icon: Icons.badge_rounded,
                      title: 'Employee ID',
                      value: 'LYRA001',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================================
              // ATTENDANCE DETAILS
              // ==========================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.045),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCheckOut
                          ? 'Check Out Details'
                          : 'Attendance Details',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _DetailRow(
                      icon: isCheckOut
                          ? Icons.logout_rounded
                          : Icons.login_rounded,
                      title: isCheckOut
                          ? 'Check Out Time'
                          : 'Check In Time',
                      value: 'Current time',
                    ),

                    const SizedBox(height: 16),

                    const _DetailRow(
                      icon: Icons.location_on_rounded,
                      title: 'Location',
                      value: '125 m',
                    ),

                    const SizedBox(height: 16),

                    const _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      title: 'Date',
                      value: 'Today',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================================
              // VERIFICATION STATUS
              // ==========================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: green.withOpacity(0.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verification Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),

                    const SizedBox(height: 17),

                    const _VerificationRow(
                      title: 'Location Verified',
                    ),

                    const SizedBox(height: 13),

                    const _VerificationRow(
                      title: 'Face Verified',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ==========================================================
              // CONFIRM BUTTON
              // ==========================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _confirmAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCheckOut
                            ? Icons.logout_rounded
                            : Icons.login_rounded,
                        size: 19,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        isCheckOut
                            ? 'Confirm Check Out'
                            : 'Confirm Check In',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // CANCEL
              // ==========================================================

              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textGrey,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================================
              // SECURITY MESSAGE
              // ==========================================================

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Your attendance data is securely verified',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==========================================================
              // FOOTER
              // ==========================================================

              const Text(
                'LYRA PULSE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: navy,
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// DETAIL ROW
// ==========================================================================

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 19,
            color: const Color(0xFF3978E8),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF718096),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF19356C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ==========================================================================
// VERIFICATION ROW
// ==========================================================================

class _VerificationRow extends StatelessWidget {
  final String title;

  const _VerificationRow({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF18A66A),
          size: 21,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF19356C),
          ),
        ),
        const Spacer(),
        const Text(
          'Verified',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF18A66A),
          ),
        ),
      ],
    );
  }
}