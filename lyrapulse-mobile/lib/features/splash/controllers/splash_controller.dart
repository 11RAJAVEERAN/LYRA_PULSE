import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();

    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    // TODO: Replace with your actual login route
    // Get.offNamed(AppRoutes.login);
  }
}