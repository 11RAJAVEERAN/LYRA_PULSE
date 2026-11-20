import 'package:flutter_test/flutter_test.dart';
import 'package:lyrapulse_mobile/core/services/location_service.dart';

void main() {
  final now = DateTime.utc(2026, 11, 12, 9);

  DevicePosition fixAt(DateTime timestamp) => DevicePosition(
        latitude: 12.5,
        longitude: 77.5,
        accuracy: 10,
        timestamp: timestamp,
      );

  group('LocationService.validateFix', () {
    test('accepts a fix exactly 120 seconds old', () {
      expect(
        () => LocationService.validateFix(
          fixAt(now.subtract(const Duration(seconds: 120))),
          now: now,
        ),
        returnsNormally,
      );
    });

    test('rejects a fix older than 120 seconds', () {
      expect(
        () => LocationService.validateFix(
          fixAt(now.subtract(const Duration(seconds: 121))),
          now: now,
        ),
        throwsA(isA<LocationFailure>().having(
          (failure) => failure.type,
          'type',
          LocationFailureType.stale,
        )),
      );
    });

    test('accepts a fix exactly 30 seconds in the future', () {
      expect(
        () => LocationService.validateFix(
          fixAt(now.add(const Duration(seconds: 30))),
          now: now,
        ),
        returnsNormally,
      );
    });

    test('rejects a fix more than 30 seconds in the future', () {
      expect(
        () => LocationService.validateFix(
          fixAt(now.add(const Duration(seconds: 31))),
          now: now,
        ),
        throwsA(isA<LocationFailure>().having(
          (failure) => failure.type,
          'type',
          LocationFailureType.future,
        )),
      );
    });

    test('rejects invalid coordinates and negative accuracy', () {
      for (final invalid in [
        fixAt(now).copyWith(latitude: 90.1),
        fixAt(now).copyWith(longitude: -180.1),
        fixAt(now).copyWith(accuracy: -0.1),
      ]) {
        expect(
          () => LocationService.validateFix(invalid, now: now),
          throwsA(isA<LocationFailure>().having(
            (failure) => failure.type,
            'type',
            LocationFailureType.invalidEvidence,
          )),
        );
      }
    });
  });

  test('request fields preserve the actual fix timestamp as UTC ISO-8601', () {
    final fix = DevicePosition(
      latitude: 12.5,
      longitude: 77.5,
      accuracy: 4.2,
      timestamp: DateTime.utc(2026, 11, 12, 8, 59, 30),
    );

    expect(fix.toRequestFields(), {
      'latitude': 12.5,
      'longitude': 77.5,
      'accuracy': 4.2,
      'location_timestamp': '2026-11-12T08:59:30.000Z',
    });
  });
}

extension on DevicePosition {
  DevicePosition copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
  }) =>
      DevicePosition(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        accuracy: accuracy ?? this.accuracy,
        timestamp: timestamp,
      );
}
