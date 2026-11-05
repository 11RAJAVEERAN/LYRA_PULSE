import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage storage;

  static const String _accessKey = 'lyrapulse_access_token';
  static const String _refreshKey = 'lyrapulse_refresh_token';

  Future<void> saveTokens({required String access, required String refresh}) async {
    await storage.write(key: _accessKey, value: access);
    await storage.write(key: _refreshKey, value: refresh);
  }

  Future<String?> readAccessToken() => storage.read(key: _accessKey);

  Future<String?> readRefreshToken() => storage.read(key: _refreshKey);

  Future<void> clearTokens() async {
    await storage.delete(key: _accessKey);
    await storage.delete(key: _refreshKey);
  }
}
