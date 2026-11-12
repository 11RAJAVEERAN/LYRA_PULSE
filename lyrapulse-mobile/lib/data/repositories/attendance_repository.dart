import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/services/location_service.dart';
import '../models/attendance_model.dart';
import '../providers/api_provider.dart';

/// Talks to the Django attendance API through the shared [ApiProvider]
/// (JWT, refresh and base URL all come from the existing DioClient).
class AttendanceRepository {
  AttendanceRepository(this._api);

  final ApiProvider _api;

  Future<TodayAttendance> fetchToday() => _guard(() async {
        final response = await _api.getTodayAttendance();
        return TodayAttendance.fromJson(_data(response));
      });

  Future<AttendanceHistoryPage> fetchHistory({
    required DateTime startDate,
    required DateTime endDate,
    required int page,
    int pageSize = 31,
  }) =>
      _guard(() async {
        final response = await _api.getAttendanceHistory(
          startDate: _date(startDate),
          endDate: _date(endDate),
          page: page,
          pageSize: pageSize,
        );
        return AttendanceHistoryPage.fromJson(_data(response));
      });

  Future<LocationVerification> verifyLocation({
    required DevicePosition fix,
  }) =>
      _guard(() async {
        final response = await _api.verifyAttendanceLocation(
          latitude: fix.latitude,
          longitude: fix.longitude,
          accuracy: fix.accuracy,
          locationTimestamp: fix.timestamp,
        );
        return LocationVerification.fromJson(_data(response));
      });

  Future<AttendanceActionResult> checkIn({
    required String idempotencyKey,
    DevicePosition? location,
    String? photoPath,
  }) =>
      _guard(() async {
        final form = await _form(location, photoPath);
        final response = await _api.checkIn(form, idempotencyKey);
        return AttendanceActionResult.fromJson(
          AttendanceAction.checkIn,
          _asMap(_data(response)['attendance']),
        );
      });

  Future<AttendanceActionResult> checkOut({
    required String idempotencyKey,
    DevicePosition? location,
    String? photoPath,
  }) =>
      _guard(() async {
        final form = await _form(location, photoPath);
        final response = await _api.checkOut(form, idempotencyKey);
        return AttendanceActionResult.fromJson(
          AttendanceAction.checkOut,
          _asMap(_data(response)['attendance']),
        );
      });

  // ---------------------------------------------------------------------------

  Future<FormData> _form(DevicePosition? location, String? photoPath) async {
    final fields = <String, dynamic>{...?location?.toRequestFields()};
    if (photoPath != null) {
      final extension =
          photoPath.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      // Only the file bytes matter: the server validates content and names the file itself.
      fields['photo'] =
          await MultipartFile.fromFile(photoPath, filename: 'photo.$extension');
    }
    return FormData.fromMap(fields);
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on AttendanceFailure {
      rethrow;
    } on DioException catch (error) {
      throw _failureFrom(error);
    } on FileSystemException {
      throw const AttendanceFailure(
          'The captured photo could not be read. Please retake it.');
    } on FormatException {
      throw const AttendanceFailure(
          'Unexpected response from the server. Please try again.');
    }
  }

  static AttendanceFailure _failureFrom(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AttendanceFailure(
          'Unable to reach Lyra Pulse. Check your internet connection and try again.',
          isConnectivity: true,
        );
      default:
        break;
    }
    final status = error.response?.statusCode;
    final data = error.response?.data;
    String? code;
    String? message;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        code = errors['code']?.toString();
        if (code == null) {
          // DRF field errors, e.g. {"photo": ["A photo is required."]}
          final flattened = errors.values
              .expand((value) => value is List ? value : [value])
              .join(' ');
          if (flattened.trim().isNotEmpty) message = flattened;
        }
      }
      message ??= data['detail']?.toString() ?? data['message']?.toString();
    }
    if (status != null && status >= 500) {
      return const AttendanceFailure(
        'The server is unavailable right now. Please try again shortly.',
        isConnectivity: true,
      );
    }
    if (status == 401) {
      return const AttendanceFailure(
          'Your session has expired. Please sign in again.',
          code: 'UNAUTHENTICATED');
    }
    return AttendanceFailure(
      message ?? error.message ?? 'Something went wrong. Please try again.',
      code: code,
    );
  }

  static Map<String, dynamic> _data(Response<dynamic> response) {
    final body = _asMap(response.data);
    if (body['success'] == false) {
      throw AttendanceFailure(
          body['message']?.toString() ?? 'The request failed.');
    }
    return _asMap(body['data']);
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }
}
