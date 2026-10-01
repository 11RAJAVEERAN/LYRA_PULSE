import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color navy = Color(0xFF102B63);
  static const Color blue = Color(0xFF5E7BB7);
  static const Color purple = Color(0xFF4F46E5);
  static const Color green = Color(0xFF09A66A);
  static const Color red = Color(0xFFE9364B);
  static const Color background = Color(0xFFF8FAFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildTodayStatus(),
                    const SizedBox(height: 18),
                    _buildActionButtons(),
                    const SizedBox(height: 18),
                    _buildTodaySummary(),
                  ],
                ),
              ),
            ),

            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HEADER
  // --------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE7EBF4),
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            image: const DecorationImage(
              image: AssetImage(
                'assets/images/profile.png',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Text(
                    'Angel',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    '👋',
                    style: TextStyle(fontSize: 17),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Here's your today's overview",
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  color: blue,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),

        // Notification
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE7ECF5),
            ),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: navy,
                  size: 22,
                ),
              ),
              Positioned(
                right: 7,
                top: 6,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // TODAY'S STATUS
  // --------------------------------------------------------------------------

  Widget _buildTodayStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFE4EAF3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF50658A).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Present
          Row(
            children: [
              Text(
                "Today's Status",
                style: GoogleFonts.poppins(
                  color: navy,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF8EC),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Present',
                      style: GoogleFonts.poppins(
                        color: green,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _statusItem(
                  icon: Icons.access_time_rounded,
                  title: 'Check In',
                  value: '09:28 AM',
                ),
              ),

              Container(
                width: 1,
                height: 58,
                color: const Color(0xFFE8ECF3),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: _statusItem(
                  icon: Icons.logout_rounded,
                  title: 'Check Out',
                  value: '--',
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          _statusItem(
            icon: Icons.timer_outlined,
            title: 'Working Hours',
            value: '--',
          ),
        ],
      ),
    );
  }

  Widget _statusItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: purple,
            size: 17,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: blue,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // ACTION BUTTONS
  // --------------------------------------------------------------------------

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            title: 'Check In',
            icon: Icons.arrow_downward_rounded,
            background: const Color(0xFF08A96A),
            iconBackground: const Color(0xFFE9FFF6),
            textColor: Colors.white,
            onTap: () {
              debugPrint('Check In tapped');
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _actionCard(
            title: 'Permission',
            icon: Icons.phone_android_outlined,
            background: const Color(0xFFEFF3F8),
            iconBackground: Colors.white,
            textColor: navy,
            onTap: () {
              debugPrint('Permission tapped');
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _actionCard(
            title: 'Check Out',
            icon: Icons.center_focus_strong_rounded,
            background: const Color(0xFFFFEEF1),
            iconBackground: Colors.white,
            textColor: red,
            onTap: () {
              debugPrint('Check Out tapped');
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required IconData icon,
    required Color background,
    required Color iconBackground,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 92,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: background == const Color(0xFF08A96A)
                  ? const Color(0xFF08A96A)
                  : const Color(0xFFE4E9F1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  icon,
                  color: background == const Color(0xFF08A96A)
                      ? const Color(0xFF08A96A)
                      : textColor,
                  size: 20,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TODAY'S SUMMARY
  // --------------------------------------------------------------------------

  Widget _buildTodaySummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE3E9F2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF50658A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Summary",
            style: GoogleFonts.poppins(
              color: navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.event_available_outlined,
                  color: purple,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  'No attendance marked yet',
                  style: GoogleFonts.poppins(
                    color: blue,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BOTTOM NAVIGATION
  // --------------------------------------------------------------------------

  Widget _buildBottomNavigation() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE8ECF3),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _navItem(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: true,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _navItem(
              icon: Icons.access_time_rounded,
              label: 'Attendance',
              selected: false,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _navItem(
              icon: Icons.event_note_outlined,
              label: 'Leave',
              selected: false,
              onTap: () {},
            ),
          ),
          Expanded(
            child: _navItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: false,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 21,
            color: selected ? purple : const Color(0xFF8292B1),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: selected ? purple : const Color(0xFF8292B1),
              fontSize: 8.5,
              fontWeight: selected
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: selected ? 28 : 0,
            height: 2,
            decoration: BoxDecoration(
              color: purple,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}