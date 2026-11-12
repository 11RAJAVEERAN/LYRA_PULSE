
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class HomeBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onMenuTap;

  const HomeBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onMenuTap,
  });

  Widget _navItem(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
              size: 23,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.textSecondary,
                fontWeight: isSelected
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.surface,
      elevation: 16,
      notchMargin: 7,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 58,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 'Home', 0),
            _navItem(
              Icons.calendar_month_outlined,
              'Calendar',
              1,
            ),
            const SizedBox(width: 72),
            _navItem(
              Icons.beach_access_outlined,
              'Leave',
              2,
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onMenuTap,
              child: SizedBox(
                width: 58,
                height: 58,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_rounded,
                      size: 22,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Menu',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
