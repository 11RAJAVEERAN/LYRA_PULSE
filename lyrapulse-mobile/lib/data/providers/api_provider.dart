import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';

class ApiProvider {
  ApiProvider(this._client);

  final DioClient _client;

  Future<Response<dynamic>> sendOtp(String phoneNumber) => _client.dio.post(
    ApiConstants.sendOtp,
    data: {'phone_number': phoneNumber},
  );

  Future<Response<dynamic>> resendOtp(String phoneNumber) => _client.dio.post(
    ApiConstants.resendOtp,
    data: {'phone_number': phoneNumber},
  );

  Future<Response<dynamic>> verifyOtp(String phoneNumber, String otp) => _client.dio.post(
    ApiConstants.verifyOtp,
    data: {'phone_number': phoneNumber, 'otp': otp},
  );

  Future<Response<dynamic>> getEmployeeProfile() => _client.dio.get(ApiConstants.employeeMe);

  Future<Response<dynamic>> getCurrentUser() => _client.dio.get(ApiConstants.currentUser);

  Future<Response<dynamic>> logout(String refreshToken) => _client.dio.post(
    ApiConstants.logout,
    data: {'refresh': refreshToken},
  );
}