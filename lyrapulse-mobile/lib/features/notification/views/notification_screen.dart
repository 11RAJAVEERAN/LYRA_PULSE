import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                height: 46,
                width: 46,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: navy,
                  size: 23,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _unreadCount == 0
                      ? 'You are all caught up'
                      : '$_unreadCount unread notification'
                          '${_unreadCount > 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Read all',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: blue,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final item = _notifications[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _markAsRead(index),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: item.isRead
                        ? const Color(0xFFE8EDF6)
                        : blue.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        color: item.color,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: item.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: navy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.time,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.message,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!item.isRead) ...[
                      const SizedBox(width: 7),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        height: 7,
                        width: 7,
                        decoration: const BoxDecoration(
                          color: red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 42,
                color: blue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Notifications',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: navy,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'You do not have any notifications right now.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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