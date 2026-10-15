
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LyraPulseApp());
}

class LyraPulseApp extends StatelessWidget {
  const LyraPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lyra Pulse',
      theme: AppTheme.light,
      initialRoute: AppRoutes.initial,
      getPages: AppPages.pages,
    );
  }
}
