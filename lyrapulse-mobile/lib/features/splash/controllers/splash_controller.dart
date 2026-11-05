import 'dart:async';

import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/controllers/auth_controller.dart';

/// Orchestrates app start-up only. All authentication behaviour (token
/// handling, profile loading, refresh) stays in AuthController/AuthRepository.
class SplashController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  bool _navigated = false;

  @override
  void onReady() {
    super.onReady();
    unawaited(_start());
  }

  Future<void> _start() async {
    // Run the minimum display timer and the session check together, then wait
    // for BOTH. The splash stays visible the whole time and the next screen is
    // decided exactly once, so Login never flashes before Home.
    final minimumDisplay = Future<void>.delayed(AppConstants.splashMinDuration);

    var authenticated = false;
    try {
      authenticated = await _authController.restoreSession();
    } catch (_) {
      authenticated = false;
    }

    await minimumDisplay;
    _navigate(authenticated);
  }

  void _navigate(bool authenticated) {
    if (_navigated || isClosed) return;
    _navigated = true;
    // offAllNamed removes the splash from the back stack.
    Get.offAllNamed(authenticated ? AppRoutes.home : AppRoutes.login);
  }
}