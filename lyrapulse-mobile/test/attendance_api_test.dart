import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyrapulse_mobile/core/network/dio_client.dart';
import 'package:lyrapulse_mobile/core/services/location_service.dart';
import 'package:lyrapulse_mobile/core/storage/secure_storage_service.dart';
import 'package:lyrapulse_mobile/data/models/attendance_model.dart';
import 'package:lyrapulse_mobile/data/providers/api_provider.dart';
import 'package:lyrapulse_mobile/data/repositories/attendance_repository.dart';

void main() {
  final fix = DevicePosition(
    latitude: 12.9716,
    longitude: 77.5946,
    accuracy: 5.4,
    timestamp: DateTime.utc(2026, 11, 12, 8, 59, 30),
  );
  const timestamp = '2026-11-12T08:59:30.000Z';

  test('verification and both punch requests carry the same GPS fix evidence',
      () async {
    final adapter = _RecordingAdapter((options) {
      if (options.path.endsWith('verify-location/')) {
        return _jsonResponse({
          'success': true,
          'data': {
            'verified': true,
            'branch': {'id': 7, 'name': 'Test Branch'},
            'distance_meters': 5.0,
            'allowed_radius_meters': 40,
            'accuracy_meters': 5.4,
          },
        });
      }
      return _jsonResponse({
        'success': true,
        'data': {
          'attendance': {
            'id': 1,
            'check_in_at': '2026-11-12T09:00:00Z',
            'check_out_at': '2026-11-12T17:00:00Z',
            'location_verified': true,
            'distance_meters': 5.0,
          },
        },
      });
    });
    final repository = _repository(adapter);

    await repository.verifyLocation(fix: fix);
    await repository.checkIn(idempotencyKey: 'stable-retry-key', location: fix);
    await repository.checkOut(idempotencyKey: 'checkout-key', location: fix);

    final verificationRequest = adapter.requests[0];
    expect(verificationRequest.data, {
      'latitude': 12.9716,
      'longitude': 77.5946,
      'accuracy': 5.4,
      'location_timestamp': timestamp,
    });
    expect(
        verificationRequest.headers['Authorization'], 'Bearer synthetic-jwt');

    final checkInRequest = adapter.requests[1];
    expect(_formFields(checkInRequest), {
      'latitude': '12.9716',
      'longitude': '77.5946',
      'accuracy': '5.4',
      'location_timestamp': timestamp,
    });
    expect(checkInRequest.headers['Idempotency-Key'], 'stable-retry-key');

    final checkOutRequest = adapter.requests[2];
    expect(_formFields(checkOutRequest)['location_timestamp'], timestamp);
    expect(checkOutRequest.headers['Idempotency-Key'], 'checkout-key');
  });

  test('HTTP 400, 403, and 409 business errors retain backend messages',
      () async {
    for (final status in [400, 403, 409]) {
      final adapter = _RecordingAdapter(
        (_) => _jsonResponse(
          {
            'success': false,
            'message': 'Backend rejection $status',
            'errors': {'code': 'TEST_$status'},
          },
          status: status,
        ),
      );
      final repository = _repository(adapter);

      await expectLater(
        repository.fetchToday(),
        throwsA(isA<AttendanceFailure>()
            .having((failure) => failure.code, 'code', 'TEST_$status')
            .having((failure) => failure.message, 'message',
                'Backend rejection $status')),
      );
    }
  });

  test('a location-disabled punch omits all GPS evidence fields', () async {
    final adapter = _RecordingAdapter(
      (_) => _jsonResponse({
        'success': true,
        'data': {
          'attendance': {
            'id': 1,
            'check_in_at': '2026-11-12T09:00:00Z',
            'location_verified': false,
          },
        },
      }),
    );
    final repository = _repository(adapter);

    await repository.checkIn(
      idempotencyKey: 'location-disabled-key',
      location: null,
    );

    expect(_formFields(adapter.requests.single), isEmpty);
  });
}

AttendanceRepository _repository(_RecordingAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.example/api/v1/'))
    ..httpClientAdapter = adapter;
  final client = DioClient(dio: dio, secureStorage: _MemorySecureStorage());
  return AttendanceRepository(ApiProvider(client));
}

Map<String, String> _formFields(RequestOptions request) {
  final data = request.data as FormData;
  return Map.fromEntries(data.fields);
}

ResponseBody _jsonResponse(Map<String, dynamic> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType]
      },
    );

class _MemorySecureStorage extends SecureStorageService {
  @override
  Future<String?> readAccessToken() async => 'synthetic-jwt';

  @override
  Future<String?> readRefreshToken() async => null;
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._responseFor);

  final ResponseBody Function(RequestOptions options) _responseFor;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _responseFor(options);
  }

  @override
  void close({bool force = false}) {}
}
