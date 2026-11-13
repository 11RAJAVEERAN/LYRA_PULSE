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

    test('tracks scheduled break time and stops at check-out', () {
      final active = TodayAttendance.fromJson({
        'attendance_date': '2026-10-18',
        'state': 'CHECKED_IN',
        'check_in_at': '2026-10-18T09:00:00',
        'check_out_at': null,
        'shift_schedule': {
          'shift_name': 'Day Shift',
          'is_working': true,
          'start_time': '09:00:00',
          'end_time': '18:00:00',
          'break_start_time': '13:00:00',
          'break_end_time': '14:00:00',
        },
      });
      expect(
        active.scheduledBreakDurationAt(DateTime(2026, 10, 18, 13, 30)),
        const Duration(minutes: 30),
      );
      expect(
        active.scheduledBreakDurationAt(DateTime(2026, 10, 18, 15)),
        const Duration(hours: 1),
      );

      final checkedOut = TodayAttendance.fromJson({
        'attendance_date': '2026-10-18',
        'state': 'CHECKED_OUT',
        'check_in_at': '2026-10-18T09:00:00',
        'check_out_at': '2026-10-18T13:20:00',
        'shift_schedule': {
          'shift_name': 'Day Shift',
          'is_working': true,
          'start_time': '09:00:00',
          'end_time': '18:00:00',
          'break_start_time': '13:00:00',
          'break_end_time': '14:00:00',
        },
      });
      expect(
        checkedOut.scheduledBreakDurationAt(DateTime(2026, 10, 18, 15)),
        const Duration(minutes: 20),
      );
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
