import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../controllers/leave_controller.dart';
import '../widgets/leave_card.dart';
import '../widgets/leave_empty_state.dart';
import '../widgets/withdraw_bottom_sheet.dart';

class LeaveScreen extends GetView<LeaveController> {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Leave Management',
          style: GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(
            child: Obx(() {
              final isPending = controller.selectedTab.value == 0;

              final leaves = isPending
                  ? controller.pendingLeaves
                  : controller.historyLeaves;

              if (leaves.isEmpty) {
                return LeaveEmptyState(
                  title: isPending
                      ? 'No Pending Leaves'
                      : 'No Leave History',
                  subtitle: isPending
                      ? 'You currently have no pending leave applications.'
                      : 'Your approved, rejected and withdrawn leaves will appear here.',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  controller.loadLeaves();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
                  itemCount: leaves.length,
                  itemBuilder: (context, index) {
                    final leave = leaves[index];

                    return LeaveCard(
                      leave: leave,
                      onWithdraw: isPending
                          ? () {
                              Get.bottomSheet(
                                WithdrawBottomSheet(leave: leave),
                                isScrollControlled: true,
                                backgroundColor: AppColors.surface,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.surface,
        elevation: 5,
        onPressed: () {
          controller.clearForm();
          Get.toNamed(AppRoutes.applyLeave);
        },
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      color: AppColors.surface,
      child: Obx(
        () => Row(
          children: [
            Expanded(
              child: _summary(
                'Pending',
                controller.pendingLeaves.length.toString(),
                AppColors.warningBackground,
                AppColors.warningDark,
                Icons.pending_actions,
              ),
            ),
            const SizedBox( width: 12),
            Expanded(
              child: _summary(
                'History',
                controller.historyLeaves.length.toString(),
                AppColors.infoSurface,
                AppColors.primaryBlue,
                Icons.history,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary(
    String title,
    String count,
    Color background,
    Color foreground,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: foreground,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Obx(
        () => Row(
          children: [
            _tab('Pending', 0),
            _tab('History', 1),
          ],
        ),
      ),
    );
  }

  Widget _tab(String title, int index) {
    final selected = controller.selectedTab.value == index;

    return Expanded(
      child: InkWell(
        onTap: () => controller.changeTab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? AppColors.primaryBlue
                    : AppColors.surface,
                width: 2.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? AppColors.primaryBlue
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}