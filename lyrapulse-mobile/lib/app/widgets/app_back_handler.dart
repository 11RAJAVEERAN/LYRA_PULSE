
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';

class AppBackHandler extends StatelessWidget {
  final Widget child;

  const AppBackHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (Get.currentRoute != AppRoutes.home) {
          Get.offAllNamed(AppRoutes.home);
        }
      },
      child: child,
    );
  }
}
