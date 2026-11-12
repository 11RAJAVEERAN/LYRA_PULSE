import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../controllers/attendance_controller.dart';

class BreakTrackingPanel extends StatefulWidget {
  const BreakTrackingPanel({super.key});

  @override
  State<BreakTrackingPanel> createState() => _BreakTrackingPanelState();
}

class _BreakTrackingPanelState extends State<BreakTrackingPanel> {
  final AttendanceController controller = Get.find<AttendanceController>();

  String selectedBreakType = 'Lunch';
  bool isExpanded = false;
  bool isProcessing = false;

  final List<String> breakTypes = [
    'Lunch',
    'Tea',
    'Personal',
  ];

  Future<void> _handleBreakCheckOut() async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final message = await controller.startBreak(selectedBreakType);

      if (!mounted) return;

      Get.snackbar(
        message == null ? 'Break Check Out' : 'Break Error',
        message ?? '$selectedBreakType break timer started.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor:
            message == null ? AppColors.successBackground : AppColors.errorBackground,
        colorText: AppColors.primaryDark,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'Break Error',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorBackground,
        colorText: AppColors.primaryDark,
      );
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> _handleBreakCheckIn() async {
    if (isProcessing) return;

    setState(() => isProcessing = true);

    try {
      final message = await controller.endBreak();

      if (!mounted) return;

      Get.snackbar(
        message == null ? 'Break Check In' : 'Break Error',
        message ?? 'Break ended. Return time and location saved.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor:
            message == null ? AppColors.successBackground : AppColors.errorBackground,
        colorText: AppColors.primaryDark,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'Break Error',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.errorBackground,
        colorText: AppColors.primaryDark,
      );
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeBreak = controller.activeBreak;

      // Read this reactive getter inside Obx.
      // It subscribes this panel to the one-second timer tick.
      final activeDuration = controller.activeBreakDuration;

      final sessions = controller.breakSessions.reversed.toList();

      return Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.border),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() => isExpanded = !isExpanded);
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.infoBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.coffee_rounded,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Break Tracking',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage your break check-in and check-out',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activeBreak != null)
                      const Icon(
                        Icons.circle,
                        size: 10,
                        color: AppColors.warning,
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller.isBreakLoading.value)
                      const Center(
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      if (activeBreak != null) ...[
                        Text(
                          '${activeBreak.type} Break in Progress',
                          style:  GoogleFonts.inter(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Break Check Out: '
                          '${controller.formatTime(activeBreak.startTime)}',
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.warningBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Break Duration',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                controller.formatElapsedDuration(
                                  activeDuration,
                                ),
                                style:  GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        DropdownButtonFormField<String>(
                          initialValue: selectedBreakType,
                          decoration: const InputDecoration(
                            labelText: 'Break Type',
                            border: OutlineInputBorder(),
                          ),
                          items: breakTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: isProcessing
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedBreakType = value;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isProcessing || activeBreak == null
                                  ? null
                                  : _handleBreakCheckIn,
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Break Check In'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isProcessing || activeBreak != null
                                  ? null
                                  : _handleBreakCheckOut,
                              icon: isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.logout_rounded),
                              label: const Text('Break Check Out'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Break History',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (sessions.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No breaks recorded today.',
                            style: GoogleFonts.inter(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        ...sessions.map((session) {
                          final isActive = session.isActive;

                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.infoBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        session.type,
                                        style:  GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      isActive ? 'In Progress' : 'Completed',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isActive
                                            ? AppColors.warningDark
                                            : AppColors.successDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Break Check Out: '
                                  '${controller.formatTime(session.startTime)}',
                                ),
                                Text(
                                  'Break Check In: '
                                  '${controller.formatTime(session.endTime)}',
                                ),
                                Text(
                                  'Duration: '
                                  '${controller.formatDuration(session.durationAt(DateTime.now()))}',
                                ),
                                if (!isActive) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Return Location',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  if (session.endAddress != null &&
                                      session.endAddress!.isNotEmpty)
                                    Text(session.endAddress!)
                                  else if (session.endLatitude != null &&
                                      session.endLongitude != null)
                                    Text(
                                      'Lat: ${session.endLatitude!.toStringAsFixed(6)}\n'
                                      'Lng: ${session.endLongitude!.toStringAsFixed(6)}',
                                    )
                                  else
                                    Text(
                                      'Location not available',
                                      style: GoogleFonts.inter(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          );
                        }),
                    ],
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Total break time: '
                      '${controller.formattedBreakDuration}',
                      style:  GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
