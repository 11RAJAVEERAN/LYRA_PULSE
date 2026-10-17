import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const Color navy = Color(0xFF102B63);
  static const Color blue = Color(0xFF4779D9);
  static const Color purple = Color(0xFF6254E8);
  static const Color green = Color(0xFF0BA875);
  static const Color red = Color(0xFFE94B60);
  static const Color orange = Color(0xFFF29D38);
  static const Color background = Color(0xFFF5F7FD);
  static const Color muted = Color(0xFF8491AA);

  final List<_NotificationItem> _notifications = [
    _NotificationItem(
      title: 'Attendance Reminder',
      message: 'Please remember to mark your attendance for today.',
      time: '09:15 AM',
      icon: Icons.access_time_rounded,
      color: blue,
      isRead: false,
    ),
    _NotificationItem(
      title: 'Attendance Marked',
      message: 'Your check-in attendance was successfully recorded.',
      time: '09:28 AM',
      icon: Icons.check_circle_outline_rounded,
      color: green,
      isRead: false,
    ),
    _NotificationItem(
      title: 'Permission Approved',
      message: 'Your permission request has been approved.',
      time: 'Yesterday',
      icon: Icons.event_available_rounded,
      color: purple,
      isRead: true,
    ),
    _NotificationItem(
      title: 'Leave Request',
      message: 'Your leave request is currently under review.',
      time: 'Yesterday',
      icon: Icons.beach_access_rounded,
      color: orange,
      isRead: true,
    ),
    _NotificationItem(
      title: 'Profile Updated',
      message: 'Your employee profile was successfully updated.',
      time: '02 Oct 2026',
      icon: Icons.person_outline_rounded,
      color: blue,
      isRead: true,
    ),
  ];

  int get _unreadCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  void _markAsRead(int index) {
    if (_notifications[index].isRead) {
      return;
    }

    setState(() {
      _notifications[index].isRead = true;
    });
  }

  void _markAllAsRead() {
    if (_unreadCount == 0) {
      return;
    }

    setState(() {
      for (final notification in _notifications) {
        notification.isRead = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE8EDF6),
                ),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: navy,
                size: 22,
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.inter(
                    color: navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _unreadCount == 0
                      ? 'You are all caught up'
                      : '$_unreadCount unread notification${_unreadCount == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    color: muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (_unreadCount > 0)
            InkWell(
              onTap: _markAllAsRead,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Read all',
                  style: GoogleFonts.inter(
                    color: blue,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================
  // NOTIFICATION LIST
  // =========================================================

  Widget _buildNotificationList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(
          notification: _notifications[index],
          index: index,
        );
      },
    );
  }

  // =========================================================
  // NOTIFICATION CARD
  // =========================================================

  Widget _buildNotificationCard({
    required _NotificationItem notification,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _markAsRead(index),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: notification.isRead
                  ? Colors.white
                  : const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: notification.isRead
                    ? const Color(0xFFE8EDF6)
                    : const Color(0xFFDDE7FB),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------
                // ICON
                // -------------------------------------------------

                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: notification.color.withValues(
                      alpha: 0.10,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    notification.icon,
                    color: notification.color,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 12),

                // -------------------------------------------------
                // CONTENT
                // -------------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.inter(
                                color: navy,
                                fontSize: 12,
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          if (!notification.isRead)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 8,
                              width: 8,
                              decoration: const BoxDecoration(
                                color: red,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      Text(
                        notification.message,
                        style: GoogleFonts.inter(
                          color: muted,
                          fontSize: 9.5,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: muted,
                            size: 12,
                          ),

                          const SizedBox(width: 4),

                          Text(
                            notification.time,
                            style: GoogleFonts.inter(
                              color: muted,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const Spacer(),

                          if (!notification.isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDF0),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Text(
                                'NEW',
                                style: GoogleFonts.inter(
                                  color: red,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: blue,
                size: 42,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              'No Notifications',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'You don’t have any notifications right now.\n'
              'We will notify you when something important happens.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: muted,
                fontSize: 10,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// NOTIFICATION MODEL
// =============================================================

class _NotificationItem {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  bool isRead;

  _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.isRead,
  });
}