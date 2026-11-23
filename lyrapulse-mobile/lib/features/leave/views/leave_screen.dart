import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../app/theme/app_colors.dart';
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
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Leave',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: Obx(() {
              final isPending = controller.selectedTab.value == 0;

              final leaves = isPending
                  ? controller.pendingLeaves
                  : controller.historyLeaves;

              if (leaves.isEmpty) {
                return LeaveEmptyState(
                  title: isPending ? 'No Pending Leaves' : 'No Leave History',
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
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
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

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Obx(
          () => Row(
            children: [
              _tab('Pending', 0),
              _tab('History', 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String title, int index) {
    final selected = controller.selectedTab.value == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () => controller.changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.surface : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}