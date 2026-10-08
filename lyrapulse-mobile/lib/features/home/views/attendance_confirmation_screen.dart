import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/home_controller.dart';
import 'attendance_success_screen.dart';

class AttendanceConfirmationScreen
    extends GetView<HomeController> {
  const AttendanceConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          'Attendance Confirmation',
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            25,
          ),
          child: Column(
            children: [
              // ------------------------------------------
              // SUCCESS HEADER
              // ------------------------------------------

              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Text(
                'Check In Ready!',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Please confirm your attendance details',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 25),

              // ------------------------------------------
              // EMPLOYEE CARD
              // ------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.employeeName.value,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Employee ID: '
                            '${controller.employeeId.value}',
                            style: GoogleFonts.inter(
                              color:
                                  AppColors.textSecondary,
                              fontSize: 9.5,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ------------------------------------------
              // ATTENDANCE DETAILS
              // ------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _ConfirmationRow(
                      icon: Icons.access_time_rounded,
                      title: 'Check In Time',
                      value:
                          controller.checkInTime.value,
                      iconColor: AppColors.primary,
                    ),

                    const _ConfirmationDivider(),

                    _ConfirmationRow(
                      icon: Icons.location_on_rounded,
                      title: 'Location Verified',
                      value: 'Yes',
                      iconColor: AppColors.success,
                      valueColor: AppColors.success,
                      showCheck: true,
                    ),

                    const _ConfirmationDivider(),

                    _ConfirmationRow(
                      icon: Icons.face_rounded,
                      title: 'Face Verified',
                      value: 'Yes',
                      iconColor: AppColors.success,
                      valueColor: AppColors.success,
                      showCheck: true,
                    ),

                    const _ConfirmationDivider(),

                    _ConfirmationRow(
                      icon: Icons.near_me_rounded,
                      title: 'Distance',
                      value:
                          controller.locationDistance.value,
                      iconColor: AppColors.primary,
                    ),

                    const _ConfirmationDivider(),

                    _ConfirmationRow(
                      icon: Icons.business_rounded,
                      title: 'Workplace',
                      value:
                          controller.locationName.value,
                      iconColor: AppColors.primary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ------------------------------------------
              // VERIFICATION STATUS
              // ------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(
                    alpha: 0.07,
                  ),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: AppColors.success.withValues(
                      alpha: 0.18,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    _VerificationItem(
                      icon: Icons.location_on_rounded,
                      text: 'Location verified',
                    ),
                    const SizedBox(height: 9),
                    _VerificationItem(
                      icon: Icons.face_rounded,
                      text: 'Face verified',
                    ),
                    const SizedBox(height: 9),
                    _VerificationItem(
                      icon: Icons.verified_user_rounded,
                      text: 'Ready to mark attendance',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ------------------------------------------
              // CONFIRM BUTTON
              // ------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _confirmCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm Check In',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ------------------------------------------
              // CANCEL
              // ------------------------------------------

              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------
  // CONFIRM CHECK IN
  // ------------------------------------------

  void _confirmCheckIn() {
    // Mark attendance as checked in.

controller.checkIn();

    Get.off(
      () => const AttendanceSuccessScreen(),
    );
  }
}

// ------------------------------------------------------
// CONFIRMATION ROW
// ------------------------------------------------------

class _ConfirmationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color? valueColor;
  final bool showCheck;

  const _ConfirmationRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    this.valueColor,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 8),

        if (showCheck)
          Container(
            width: 17,
            height: 17,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 11,
            ),
          ),

        if (showCheck) const SizedBox(width: 6),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color:
                  valueColor ?? AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------
// DIVIDER
// ------------------------------------------------------

class _ConfirmationDivider extends StatelessWidget {
  const _ConfirmationDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
      ),
      child: Container(
        height: 1,
        color: AppColors.border,
      ),
    );
  }
}

// ------------------------------------------------------
// VERIFICATION ITEM
// ------------------------------------------------------

class _VerificationItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _VerificationItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(
              alpha: 0.12,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.success,
            size: 14,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(
          Icons.check_rounded,
          color: AppColors.success,
          size: 17,
        ),
      ],
    );
  }
}