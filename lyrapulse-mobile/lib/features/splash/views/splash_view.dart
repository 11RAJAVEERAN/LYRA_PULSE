import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/splash_content.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF07164F),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF07164F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: const Scaffold(
        body: SplashContent(),
      ),
    );
  }
}