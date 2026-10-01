import 'package:get/get.dart';

class NotificationsController extends GetxController {
  final notifications = <NotificationItem>[
    NotificationItem(
      title: 'Attendance Reminder',
      message: 'Don\'t forget to check in today.',
      time: '10 min ago',
      type: NotificationType.attendance,
    ),
    NotificationItem(
      title: 'Leave Request Updated',
      message: 'Your leave request status has been updated.',
      time: '2 hours ago',
      type: NotificationType.leave,
    ),
    NotificationItem(
      title: 'Welcome to Lyra Pulse',
      message: 'Your employee account is ready to use.',
      time: 'Yesterday',
      type: NotificationType.general,
    ),
  ].obs;

  void markAsRead(int index) {
    if (index >= 0 && index < notifications.length) {
      notifications[index] = notifications[index].copyWith(
        isRead: true,
      );
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < notifications.length; i++) {
      notifications[i] = notifications[i].copyWith(
        isRead: true,
      );
    }
  }
}

enum NotificationType {
  attendance,
  leave,
  general,
}

class NotificationItem {
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isRead;

  const NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? title,
    String? message,
    String? time,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationItem(
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}