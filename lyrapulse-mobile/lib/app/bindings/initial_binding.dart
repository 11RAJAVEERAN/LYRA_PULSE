import 'package:get/get.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/providers/api_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/profile/controllers/profile_controller.dart';

/// App-wide dependencies. SplashController is intentionally NOT registered
/// here; it is bound to the splash routes in AppPages so it only lives while
/// the splash screen is active.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SecureStorageService>(SecureStorageService(), permanent: true);
    Get.put<DioClient>(DioClient(secureStorage: Get.find()), permanent: true);
    Get.put<ApiProvider>(ApiProvider(Get.find()), permanent: true);
    Get.put<AuthRepository>(AuthRepository(Get.find(), Get.find()), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}