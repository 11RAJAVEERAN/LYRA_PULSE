
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';

// import 'package:lyrapulse_mobile/features/calendar/views/calendar_screen.dart';
// import 'package:lyrapulse_mobile/features/leave/views/leave_screen.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   static const Color navy = Color(0xFF142B55);
//   static const Color primaryBlue = Color(0xFF1769AA);
//   static const Color background = Color(0xFFF6F8FC);
//   static const Color textDark = Color(0xFF172B4D);
//   static const Color textMuted = Color(0xFF7B879A);
//   static const Color borderColor = Color(0xFFE8EDF5);

//   int selectedIndex = 0;
//   bool isCheckedIn = false;
//   bool isCheckedOut = false;

//   String checkInTime = '--:--';
//   String checkOutTime = '--:--';

//   void _showMessage(String message) {
//     Get.snackbar(
//       'Lyra Pulse',
//       message,
//       snackPosition: SnackPosition.BOTTOM,
//       backgroundColor: navy,
//       colorText: Colors.white,
//       margin: const EdgeInsets.all(16),
//       borderRadius: 14,
//       duration: const Duration(seconds: 2),
//     );
//   }

//   void _openAttendance() {
//     setState(() => selectedIndex = 1);
//     Get.toNamed('/attendance');
//   }

//   void _openCalendar() {
//     setState(() => selectedIndex = 2);
//     Get.to(() => const CalendarScreen());
//   }

//   void _openLeave() {
//     setState(() => selectedIndex = 3);
//     Get.to(() => const LeaveScreen());
//   }

//   void _openProfile() {
//     setState(() => selectedIndex = 4);
//     Get.toNamed('/profile');
//   }

//   void _checkIn() {
//     if (isCheckedIn && !isCheckedOut) {
//       _showMessage('You have already checked in.');
//       return;
//     }

//     if (isCheckedOut) {
//       _showMessage('Today attendance is already completed.');
//       return;
//     }

//     Get.toNamed('/location-verification');
//   }

//   void _checkOut() {
//     if (!isCheckedIn) {
//       _showMessage('Please check in first.');
//       return;
//     }

//     if (isCheckedOut) {
//       _showMessage('You have already checked out.');
//       return;
//     }

//     Get.toNamed('/location-verification');
//   }

//   String get _greeting {
//     final hour = DateTime.now().hour;

//     if (hour < 12) return 'Good Morning';
//     if (hour < 17) return 'Good Afternoon';
//     return 'Good Evening';
//   }

//   String get _todayDate {
//     final now = DateTime.now();
//     const months = [
//       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
//       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
//     ];
//     const weekdays = [
//       'Monday', 'Tuesday', 'Wednesday', 'Thursday',
//       'Friday', 'Saturday', 'Sunday'
//     ];

//     return '${weekdays[now.weekday - 1]}, '
//         '${now.day} ${months[now.month - 1]} ${now.year}';
//   }

//   String get _workingHours {
//     if (!isCheckedIn || checkInTime == '--:--') {
//       return '00h 00m';
//     }

//     if (isCheckedOut) {
//       return 'Completed';
//     }

//     return 'In progress';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: background,
//       body: SafeArea(
//         child: CustomScrollView(
//           physics: const BouncingScrollPhysics(),
//           slivers: [
//             SliverPadding(
//               padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
//               sliver: SliverList(
//                 delegate: SliverChildListDelegate([
//                   _buildHeader(),
//                   const SizedBox(height: 26),
//                   _buildAttendanceCard(),
//                   const SizedBox(height: 26),
//                   _buildSectionHeader(
//                     'Quick Actions',
//                     'Manage your day',
//                   ),
//                   const SizedBox(height: 14),
//                   _buildQuickActions(),
//                   const SizedBox(height: 26),
//                   _buildSectionHeader(
//                     'Today Overview',
//                     'Your attendance summary',
//                   ),
//                   const SizedBox(height: 14),
//                   _buildOverview(),
//                   const SizedBox(height: 26),
//                   _buildSectionHeader(
//                     'Attendance Details',
//                     'Today at a glance',
//                   ),
//                   const SizedBox(height: 14),
//                   _buildAttendanceDetails(),
//                   const SizedBox(height: 20),
//                   Center(
//                     child: Text(
//                       'POWERED BY LYRATECH',
//                       style: GoogleFonts.inter(
//                         fontSize: 10,
//                         fontWeight: FontWeight.w700,
//                         color: textMuted,
//                         letterSpacing: 2,
//                       ),
//                     ),
//                   ),
//                 ]),
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNavigation(),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 _greeting,
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   color: textMuted,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 'Angel 👋',
//                 style: GoogleFonts.inter(
//                   fontSize: 27,
//                   fontWeight: FontWeight.w800,
//                   color: textDark,
//                   letterSpacing: -0.8,
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 _todayDate,
//                 style: GoogleFonts.inter(
//                   fontSize: 12,
//                   color: textMuted,
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Container(
//           width: 50,
//           height: 50,
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(17),
//             border: Border.all(color: borderColor),
//             boxShadow: [
//               BoxShadow(
//                 color: navy.withAlpha(10),
//                 blurRadius: 16,
//                 offset: const Offset(0, 5),
//               ),
//             ],
//           ),
//           child: IconButton(
//             onPressed: () => _showMessage(
//               'Notifications will be available soon.',
//             ),
//             icon: const Icon(
//               Icons.notifications_none_rounded,
//               color: navy,
//               size: 25,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAttendanceCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(22),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [
//             Color(0xFF193766),
//             Color(0xFF1769AA),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(26),
//         boxShadow: [
//           BoxShadow(
//             color: primaryBlue.withAlpha(45),
//             blurRadius: 22,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(
//                 Icons.access_time_rounded,
//                 color: Colors.white70,
//                 size: 20,
//               ),
//               const SizedBox(width: 9),
//               Text(
//                 'Attendance',
//                 style: GoogleFonts.inter(
//                   color: Colors.white,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const Spacer(),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withAlpha(28),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 7,
//                       height: 7,
//                       decoration: BoxDecoration(
//                         color: isCheckedOut
//                             ? Colors.white70
//                             : isCheckedIn
//                                 ? const Color(0xFF72F0B1)
//                                 : const Color(0xFFFFD166),
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                     const SizedBox(width: 6),
//                     Text(
//                       isCheckedOut
//                           ? 'Completed'
//                           : isCheckedIn
//                               ? 'Checked In'
//                               : 'Not Checked In',
//                       style: GoogleFonts.inter(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 25),
//           Text(
//             'Total working hours',
//             style: GoogleFonts.inter(
//               color: Colors.white70,
//               fontSize: 12,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             _workingHours,
//             style: GoogleFonts.inter(
//               color: Colors.white,
//               fontSize: 31,
//               fontWeight: FontWeight.w800,
//               letterSpacing: -0.8,
//             ),
//           ),
//           const SizedBox(height: 22),
//           Container(
//             padding: const EdgeInsets.all(15),
//             decoration: BoxDecoration(
//               color: Colors.white.withAlpha(18),
//               borderRadius: BorderRadius.circular(17),
//               border: Border.all(
//                 color: Colors.white.withAlpha(30),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: _timeInfo(
//                     icon: Icons.login_rounded,
//                     label: 'CHECK IN',
//                     time: checkInTime,
//                   ),
//                 ),
//                 Container(
//                   height: 40,
//                   width: 1,
//                   color: Colors.white.withAlpha(45),
//                 ),
//                 const SizedBox(width: 15),
//                 Expanded(
//                   child: _timeInfo(
//                     icon: Icons.logout_rounded,
//                     label: 'CHECK OUT',
//                     time: checkOutTime,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
//           Row(
//             children: [
//               Expanded(
//                 child: _attendanceButton(
//                   label: isCheckedIn
//                       ? 'Checked In'
//                       : 'Check In',
//                   icon: Icons.login_rounded,
//                   filled: true,
//                   onTap: _checkIn,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: _attendanceButton(
//                   label: isCheckedOut
//                       ? 'Checked Out'
//                       : 'Check Out',
//                   icon: Icons.logout_rounded,
//                   filled: false,
//                   onTap: _checkOut,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Location and face verification required',
//             style: GoogleFonts.inter(
//               color: Colors.white70,
//               fontSize: 10,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _timeInfo({
//     required IconData icon,
//     required String label,
//     required String time,
//   }) {
//     return Row(
//       children: [
//         Icon(icon, color: Colors.white70, size: 19),
//         const SizedBox(width: 9),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: GoogleFonts.inter(
//                   color: Colors.white70,
//                   fontSize: 9,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 time,
//                 style: GoogleFonts.inter(
//                   color: Colors.white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _attendanceButton({
//     required String label,
//     required IconData icon,
//     required bool filled,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: filled ? Colors.white : Colors.white.withAlpha(18),
//       borderRadius: BorderRadius.circular(13),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(13),
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(13),
//             border: filled
//                 ? null
//                 : Border.all(color: Colors.white54),
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 icon,
//                 size: 17,
//                 color: filled ? navy : Colors.white,
//               ),
//               const SizedBox(width: 7),
//               Flexible(
//                 child: Text(
//                   label,
//                   style: GoogleFonts.inter(
//                     fontSize: 11,
//                     fontWeight: FontWeight.w700,
//                     color: filled ? navy : Colors.white,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title, String subtitle) {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 title,
//                 style: GoogleFonts.inter(
//                   color: textDark,
//                   fontSize: 18,
//                   fontWeight: FontWeight.w800,
//                   letterSpacing: -0.4,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 subtitle,
//                 style: GoogleFonts.inter(
//                   color: textMuted,
//                   fontSize: 11,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildQuickActions() {
//     return Row(
//       children: [
//         Expanded(
//           child: _quickAction(
//             icon: Icons.calendar_month_rounded,
//             title: 'IPO Calendar',
//             subtitle: 'View calendar',
//             color: const Color(0xFF1769AA),
//             backgroundColor: const Color(0xFFEAF3FF),
//             onTap: _openCalendar,
//           ),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _quickAction(
//             icon: Icons.event_available_rounded,
//             title: 'Attendance',
//             subtitle: 'View records',
//             color: const Color(0xFF15856B),
//             backgroundColor: const Color(0xFFE5F7F0),
//             onTap: _openAttendance,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _quickAction({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required Color color,
//     required Color backgroundColor,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(20),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(20),
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.all(15),
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: borderColor),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 width: 43,
//                 height: 43,
//                 decoration: BoxDecoration(
//                   color: backgroundColor,
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: Icon(icon, color: color, size: 23),
//               ),
//               const SizedBox(height: 15),
//               Text(
//                 title,
//                 style: GoogleFonts.inter(
//                   color: textDark,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 subtitle,
//                 style: GoogleFonts.inter(
//                   color: textMuted,
//                   fontSize: 10,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildOverview() {
//     return Row(
//       children: [
//         Expanded(
//           child: _overviewCard(
//             icon: Icons.login_rounded,
//             label: 'Check In',
//             value: checkInTime,
//             color: const Color(0xFF1769AA),
//             bg: const Color(0xFFEAF3FF),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: _overviewCard(
//             icon: Icons.logout_rounded,
//             label: 'Check Out',
//             value: checkOutTime,
//             color: const Color(0xFF15856B),
//             bg: const Color(0xFFE5F7F0),
//           ),
//         ),
//         const SizedBox(width: 10),
//         Expanded(
//           child: _overviewCard(
//             icon: Icons.schedule_rounded,
//             label: 'Hours',
//             value: isCheckedOut ? 'Done' : '--',
//             color: const Color(0xFF8A5BC2),
//             bg: const Color(0xFFF2EAFE),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _overviewCard({
//     required IconData icon,
//     required String label,
//     required String value,
//     required Color color,
//     required Color bg,
//   }) {
//     return Container(
//       padding: const EdgeInsets.symmetric(
//         horizontal: 10,
//         vertical: 15,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(color: borderColor),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 34,
//             height: 34,
//             decoration: BoxDecoration(
//               color: bg,
//               borderRadius: BorderRadius.circular(11),
//             ),
//             child: Icon(icon, color: color, size: 18),
//           ),
//           const SizedBox(height: 13),
//           Text(
//             label,
//             style: GoogleFonts.inter(
//               color: textMuted,
//               fontSize: 10,
//             ),
//           ),
//           const SizedBox(height: 5),
//           FittedBox(
//             fit: BoxFit.scaleDown,
//             alignment: Alignment.centerLeft,
//             child: Text(
//               value,
//               style: GoogleFonts.inter(
//                 color: textDark,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAttendanceDetails() {
//     return Container(
//       padding: const EdgeInsets.all(17),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: borderColor),
//       ),
//       child: Column(
//         children: [
//           _detailRow(
//             icon: Icons.location_on_outlined,
//             title: 'Office Location',
//             subtitle: 'Location verification required',
//             trailing: 'Verify',
//           ),
//           const Divider(height: 25, color: borderColor),
//           _detailRow(
//             icon: Icons.face_retouching_natural_rounded,
//             title: 'Face Verification',
//             subtitle: 'Identity verification',
//             trailing: 'Required',
//           ),
//           const Divider(height: 25, color: borderColor),
//           _detailRow(
//             icon: Icons.event_note_rounded,
//             title: 'Attendance History',
//             subtitle: 'Review your attendance records',
//             trailing: 'View',
//             onTap: _openAttendance,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _detailRow({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required String trailing,
//     VoidCallback? onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Row(
//         children: [
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: const Color(0xFFF0F4FA),
//               borderRadius: BorderRadius.circular(13),
//             ),
//             child: Icon(icon, color: navy, size: 21),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: GoogleFonts.inter(
//                     color: textDark,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   subtitle,
//                   style: GoogleFonts.inter(
//                     color: textMuted,
//                     fontSize: 10,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Text(
//             trailing,
//             style: GoogleFonts.inter(
//               color: primaryBlue,
//               fontSize: 11,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(width: 3),
//           const Icon(
//             Icons.chevron_right_rounded,
//             color: textMuted,
//             size: 18,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomNavigation() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: const Border(
//           top: BorderSide(color: borderColor),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: navy.withAlpha(8),
//             blurRadius: 18,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(
//             horizontal: 8,
//             vertical: 9,
//           ),
//           child: Row(
//             children: [
//               _bottomNavItem(
//                 icon: Icons.home_rounded,
//                 label: 'Home',
//                 index: 0,
//                 onTap: () => setState(() => selectedIndex = 0),
//               ),
//               _bottomNavItem(
//                 icon: Icons.fact_check_outlined,
//                 label: 'Attendance',
//                 index: 1,
//                 onTap: _openAttendance,
//               ),
//               _bottomNavItem(
//                 icon: Icons.calendar_month_outlined,
//                 label: 'Calendar',
//                 index: 2,
//                 onTap: _openCalendar,
//               ),
//               _bottomNavItem(
//                 icon: Icons.event_note_outlined,
//                 label: 'Leave',
//                 index: 3,
//                 onTap: _openLeave,
//               ),
//               _bottomNavItem(
//                 icon: Icons.person_outline_rounded,
//                 label: 'Profile',
//                 index: 4,
//                 onTap: _openProfile,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _bottomNavItem({
//     required IconData icon,
//     required String label,
//     required int index,
//     required VoidCallback onTap,
//   }) {
//     final bool selected = selectedIndex == index;

//     return Expanded(
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(14),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 5),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 icon,
//                 size: 22,
//                 color: selected ? primaryBlue : textMuted,
//               ),
//               const SizedBox(height: 5),
//               FittedBox(
//                 fit: BoxFit.scaleDown,
//                 child: Text(
//                   label,
//                   style: GoogleFonts.inter(
//                     fontSize: 9,
//                     fontWeight: selected
//                         ? FontWeight.w800
//                         : FontWeight.w500,
//                     color: selected ? primaryBlue : textMuted,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 4),
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 width: selected ? 15 : 0,
//                 height: 3,
//                 decoration: BoxDecoration(
//                   color: primaryBlue,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
