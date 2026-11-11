import 'package:flutter_test/flutter_test.dart';
import 'package:lyrapulse_mobile/core/utils/formatters.dart';
import 'package:lyrapulse_mobile/data/models/attendance_model.dart';

void main() {
  group('TodayAttendance.fromJson', () {
    test('parses a not-checked-in day', () {
      final today = TodayAttendance.fromJson({
        'attendance_date': '2026-10-18',
        'state': 'NOT_CHECKED_IN',
        'check_in_at': null,
        'check_out_at': null,
      });
      expect(today.state, AttendanceState.notCheckedIn);
      expect(today.checkInAt, isNull);
      expect(today.checkOutAt, isNull);
    });

    group('AttendanceHistoryPage.fromJson', () {
      test('parses completed and open employee sessions', () {
        final page = AttendanceHistoryPage.fromJson({
          'count': 2,
          'page': 1,
          'page_size': 1,
          'has_next': true,
          'results': [
            {
              'id': 42,
              'attendance_date': '2026-10-18',
              'check_in_at': '2026-10-18T03:58:00Z',
              'check_out_at': null,
              'working_seconds': null,
              'status': 'CHECKED_IN',
              'source': 'MOBILE_GPS',
              'branch': {'id': 3, 'name': 'Head Office'},
              'check_in_location_verified': true,
              'check_out_location_verified': null,
              'check_in_photo_available': true,
              'check_out_photo_available': false,
            },
          ],
        });

        expect(page.count, 2);
        expect(page.hasNext, isTrue);
        expect(page.results.single.id, 42);
        expect(page.results.single.checkOutAt, isNull);
        expect(page.results.single.source, 'MOBILE_GPS');
        expect(page.results.single.branchName, 'Head Office');
        expect(page.results.single.checkInPhotoAvailable, isTrue);
      });
    });

    test('parses check-in and check-out timestamps', () {
      final today = TodayAttendance.fromJson({
        'attendance_date': '2026-10-18',
        'state': 'CHECKED_OUT',
        'check_in_at': '2026-10-18T03:58:00Z',
        'check_out_at': '2026-10-18T12:28:00Z',
      });
      expect(today.state, AttendanceState.checkedOut);
      expect(today.checkOutAt!.difference(today.checkInAt!),
          const Duration(hours: 8, minutes: 30));
    });

    test('unknown state falls back to not checked in', () {
      expect(AttendanceState.parse('SOMETHING_ELSE'),
          AttendanceState.notCheckedIn);
      expect(AttendanceState.parse(null), AttendanceState.notCheckedIn);
    });
  });

  group('LocationVerification.fromJson', () {
    test('parses an outside-radius result', () {
      final result = LocationVerification.fromJson({
        'verified': false,
        'branch': {'id': 3, 'name': 'Head Office'},
        'distance_meters': 412.5,
        'allowed_radius_meters': 150,
        'accuracy_meters': 12.0,
      });
      expect(result.verified, isFalse);
      expect(result.branchName, 'Head Office');
      expect(result.distanceMeters, 412.5);
      expect(result.allowedRadiusMeters, 150);
    });
  });

  group('Formatters', () {
    test('durationHms and durationShort', () {
      expect(
          Formatters.durationHms(
              const Duration(hours: 1, minutes: 5, seconds: 9)),
          '01:05:09');
      expect(Formatters.durationShort(const Duration(hours: 7, minutes: 5)),
          '7h 05m');
    });

    test('time12 handles midnight, noon and missing values', () {
      expect(Formatters.time12(DateTime(2026, 10, 18, 0, 5)), '12:05 AM');
      expect(Formatters.time12(DateTime(2026, 10, 18, 12, 30)), '12:30 PM');
      expect(Formatters.time12(null), '--:--');
    });

    test('distance switches to km', () {
      expect(Formatters.distance(120.4), '120 m');
      expect(Formatters.distance(1400), '1.4 km');
    });
  });
}
