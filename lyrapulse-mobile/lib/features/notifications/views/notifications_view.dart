
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/notifications_controller.dart';
import '../widgets/notification_content.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      body: SafeArea(
        child: Obx(
          () => NotificationsContent(
            notifications: controller.notifications,
            onNotificationTap: controller.markAsRead,
            onMarkAllAsRead: controller.markAllAsRead,
          ),
        ),
      ),
    );
  }
}