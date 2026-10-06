
import 'package:dio/dio.dart';

import '../../core/storage/secure_storage_service.dart';
import '../models/employee_model.dart';
import '../providers/api_provider.dart';

class AuthRepository {
  AuthRepository(this._api, this._secureStorage);

  final ApiProvider _api;
  final SecureStorageService _secureStorage;

  Future<String?> sendOtp(String phoneNumber) async {
    final response = await _api.sendOtp(phoneNumber);
    final body = _asMap(response.data);
    _ensureSuccess(body);
    final data = _asMap(body['data']);
    return data['dev_otp']?.toString();
  }

  Future<String?> resendOtp(String phoneNumber) async {
    final response = await _api.resendOtp(phoneNumber);
    final body = _asMap(response.data);
    _ensureSuccess(body);
    final data = _asMap(body['data']);
    return data['dev_otp']?.toString();
  }

  Future<EmployeeModel> verifyOtp(String phoneNumber, String otp) async {
    final response = await _api.verifyOtp(phoneNumber, otp);
    final body = _asMap(response.data);
    _ensureSuccess(body);
    final data = _asMap(body['data']);
    final access = data['access']?.toString();
    final refresh = data['refresh']?.toString();
    if (access == null || refresh == null) {
      throw const FormatException('The server did not return login tokens.');
    }
    await _secureStorage.saveTokens(access: access, refresh: refresh);
    try {
      return await loadEmployeeProfile();
    } catch (_) {
      await _secureStorage.clearTokens();
      rethrow;
    }
  }

  Future<EmployeeModel> loadEmployeeProfile() async {
    final responses = await Future.wait([
      _api.getEmployeeProfile(),
      _api.getCurrentUser(),
    ]);
    final profileBody = _asMap(responses[0].data);
    final currentUserBody = _asMap(responses[1].data);
    _ensureSuccess(profileBody);
    _ensureSuccess(currentUserBody);
    final profile = _asMap(profileBody['data']);
    final currentUser = _asMap(_asMap(currentUserBody['data'])['user']);
    return EmployeeModel.fromJson(profile, emailFallback: currentUser['email']?.toString() ?? '');
  }

  Future<void> logout() async {
    final refreshToken = await _secureStorage.readRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final response = await _api.logout(refreshToken);
        _ensureSuccess(_asMap(response.data));
      }
    } finally {
      await _secureStorage.clearTokens();
    }
  }

  Future<void> clearSession() => _secureStorage.clearTokens();

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, item) => MapEntry(key.toString(), item));
    return <String, dynamic>{};
  }

  static void _ensureSuccess(Map<String, dynamic> body) {
    if (body['success'] == false) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: body['message']?.toString() ?? 'The request failed.',
      );
    }
  }
}