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

  // ---------------------------------------------------------------------------
  // ATTENDANCE
  // ---------------------------------------------------------------------------
  Future<Response<dynamic>> getTodayAttendance() => _client.dio.get(ApiConstants.attendanceToday);

  Future<Response<dynamic>> verifyAttendanceLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
  }) => _client.dio.post(
    ApiConstants.attendanceVerifyLocation,
    data: {'latitude': latitude, 'longitude': longitude, 'accuracy': accuracy},
  );

  Future<Response<dynamic>> checkIn(FormData form) => _client.dio.post(
    ApiConstants.attendanceCheckIn,
    data: form,
    options: Options(sendTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60)),
  );

  Future<Response<dynamic>> checkOut(FormData form) => _client.dio.post(
    ApiConstants.attendanceCheckOut,
    data: form,
    options: Options(sendTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60)),
  );

  Future<Response<dynamic>> logout(String refreshToken) => _client.dio.post(
    ApiConstants.logout,
    data: {'refresh': refreshToken},
  );
}