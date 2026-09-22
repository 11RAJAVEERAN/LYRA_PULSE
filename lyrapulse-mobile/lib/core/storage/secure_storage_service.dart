import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage storage;
}
