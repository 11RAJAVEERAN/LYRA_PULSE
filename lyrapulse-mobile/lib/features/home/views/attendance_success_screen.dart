import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/home_controller.dart';

class AttendanceSuccessScreen extends GetView<HomeController> {
  const AttendanceSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  20,
                  35,
                  20,
                  20,
                ),
                child: Column(
                  children: [
                    // ----------------------------------------
                    // SUCCESS ICON
                    // ----------------------------------------

                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(
                          alpha: 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 43,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ----------------------------------------
                    // TITLE
                    // ----------------------------------------

                    Text(
                      'Attendance Marked!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Your check-in has been recorded successfully.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ----------------------------------------
                    // EMPLOYEE CARD
                    // ----------------------------------------

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
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(
                                alpha: 0.10,
                              ),
                              borderRadius:
                                  BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.primary,
                              size: 25,
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
                                    fontSize: 14,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'Employee ID: ${controller.employeeId.value}',
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

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withValues(alpha: 0.10),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PRESENT',
                              style: GoogleFonts.inter(
                                color: AppColors.success,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ----------------------------------------
                    // CHECK-IN DETAILS
                    // ----------------------------------------

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
                          _DetailRow(
                            icon: Icons.access_time_rounded,
                            title: 'Check-in Time',
                            value:
                                controller.checkInTime.value,
                            iconColor: AppColors.primary,
                          ),

                          const _DetailDivider(),

                          _DetailRow(
                            icon: Icons.location_on_rounded,
                            title: 'Location Verified',
                            value: 'Yes',
                            iconColor: AppColors.success,
                            valueColor:
                                AppColors.success,
                          ),

                          const _DetailDivider(),

                          _DetailRow(
                            icon: Icons.face_rounded,
                            title: 'Face Verified',
                            value: 'Yes',
                            iconColor: AppColors.success,
                            valueColor:
                                AppColors.success,
                          ),

                          const _DetailDivider(),

                          _DetailRow(
                            icon: Icons.near_me_rounded,
                            title: 'Distance',
                            value:
                                controller.locationDistance
                                    .value,
                            iconColor: AppColors.primary,
                          ),

                          const _DetailDivider(),

                          _DetailRow(
                            icon: Icons.business_rounded,
                            title: 'Workplace',
                            value:
                                controller.locationName.value,
                            iconColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ----------------------------------------
                    // VERIFIED MESSAGE
                    // ----------------------------------------

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius:
                            BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.success
                              .withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.success,
                            size: 21,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'Attendance successfully verified using location and face verification.',
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 9.5,
                                height: 1.4,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ----------------------------------------
            // DONE BUTTON
            // ----------------------------------------

            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                20,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Get.offAllNamed('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                        Icons.home_rounded,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Done',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------
// DETAIL ROW
// ------------------------------------------------------

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 17,
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

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: valueColor ?? AppColors.textPrimary,
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

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

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