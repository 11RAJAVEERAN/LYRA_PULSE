import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_colors.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({
    super.key,
    required this.onHomeTap,
    required this.onProfileTap,
    required this.onNotificationTap,
    required this.onAttendanceHistoryTap,
    required this.onCalendarTap,
    required this.onPermissionTap,
    required this.onLeaveTap,
    this.employeeName = 'Employee Name',
    this.designation = 'Software Developer',
    this.employeeId,
    this.onLogoutTap,
  });

  final VoidCallback onHomeTap;
  final VoidCallback onProfileTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onAttendanceHistoryTap;
  final VoidCallback onCalendarTap;
  final VoidCallback onPermissionTap;
  final VoidCallback onLeaveTap;
  final String employeeName;
  final String designation;
  final String? employeeId;
  final VoidCallback? onLogoutTap;

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  String _selectedItem = 'Home';

  void _select(String title, VoidCallback callback) {
    setState(() => _selectedItem = title);
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82 > 330
          ? 330
          : MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MENU',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _menuItem(
                      title: 'Home',
                      subtitle: 'Dashboard overview',
                      icon: Icons.home_rounded,
                      onTap: () => _select('Home', widget.onHomeTap),
                    ),
                    _menuItem(
                      title: 'My Profile',
                      subtitle: 'Personal information',
                      icon: Icons.person_rounded,
                      onTap: () => _select('My Profile', widget.onProfileTap),
                    ),
                    _menuItem(
                      title: 'Notifications',
                      subtitle: 'Updates and alerts',
                      icon: Icons.notifications_rounded,
                      onTap: () =>
                          _select('Notifications', widget.onNotificationTap),
                    ),
                    _menuItem(
                      title: 'Attendance History',
                      subtitle: 'Your attendance records',
                      icon: Icons.calendar_month_rounded,
                      onTap: () => _select(
                        'Attendance History',
                        widget.onAttendanceHistoryTap,
                      ),
                    ),
                    _menuItem(
                      title: 'Calendar',
                      subtitle: 'Monthly schedule',
                      icon: Icons.event_note_rounded,
                      onTap: () => _select('Calendar', widget.onCalendarTap),
                    ),
                    _menuItem(
                      title: 'Permission',
                      subtitle: 'Request permission',
                      icon: Icons.fact_check_rounded,
                      onTap: () =>
                          _select('Permission', widget.onPermissionTap),
                    ),
                    _menuItem(
                      title: 'Leave Management',
                      subtitle: 'Apply and track leave',
                      icon: Icons.beach_access_rounded,
                      onTap: () =>
                          _select('Leave Management', widget.onLeaveTap),
                    ),
                  ],
                ),
              ),
            ),
            if (widget.onLogoutTap != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Divider(color: AppColors.border, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: _menuItem(
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  selectedColor: AppColors.error.withValues(alpha: 0.08),
                  onTap: widget.onLogoutTap!,
                ),
              ),
            ] else
              const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'LYRA PULSE  •  FROM LYRA TECH',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.hexFF101D49, AppColors.hexFF1E3A70],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.65),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 34,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.employeeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.designation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: AppColors.hexFFD6E1F5,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(30),
              border:
                  Border.all(color: AppColors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: AppColors.hexFF86EFAC,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.employeeId == null || widget.employeeId!.isEmpty
                      ? 'LYRA PULSE EMPLOYEE'
                      : 'EMPLOYEE ID: ${widget.employeeId}',
                  style: GoogleFonts.inter(
                    color: AppColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    Color? selectedColor,
  }) {
    final bool selected = _selectedItem == title;
    final Color effectiveIconColor =
        iconColor ?? (selected ? AppColors.primary : AppColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected
            ? (selectedColor ?? AppColors.primary.withValues(alpha: 0.08))
            : AppColors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.white
                        : AppColors.border.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: effectiveIconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                  color: selected ? AppColors.primary : AppColors.sidebarMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
