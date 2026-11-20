import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lyrapulse_mobile/data/models/employee_model.dart';
import 'package:lyrapulse_mobile/features/home/widgets/attendance_hero_card.dart';

void main() {
  group('Employee attendance permissions', () {
    test('parses the backend mobile permission fields', () {
      final employee = EmployeeModel.fromJson({
        'id': 42,
        'mobile_gps_attendance_enabled': true,
        'location_attendance_enabled': true,
        'photo_attendance_enabled': false,
        'biometric_attendance_enabled': true,
      });

      expect(employee.mobileAttendanceEnabled, isTrue);
      expect(employee.locationAttendanceEnabled, isTrue);
      expect(employee.photoAttendanceEnabled, isFalse);
      expect(employee.biometricAttendanceEnabled, isTrue);
    });

    test('defaults absent permission fields to disabled', () {
      final employee = EmployeeModel.fromJson(const {});

      expect(employee.mobileAttendanceEnabled, isFalse);
      expect(employee.locationAttendanceEnabled, isFalse);
      expect(employee.photoAttendanceEnabled, isFalse);
      expect(employee.biometricAttendanceEnabled, isFalse);
    });
  });

  testWidgets('mobile attendance controls are hidden when permission is off',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceActionControls(
            visible: false,
            canCheckIn: true,
            canCheckOut: false,
            onCheckIn: () {},
            onCheckOut: () {},
          ),
        ),
      ),
    );

    expect(find.text('Check In'), findsNothing);
    expect(find.text('Check Out'), findsNothing);
  });

  testWidgets('active attendance shows only Check Out', (tester) async {
    var checkIns = 0;
    var checkOuts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceActionControls(
            visible: true,
            canCheckIn: false,
            canCheckOut: true,
            onCheckIn: () => checkIns++,
            onCheckOut: () => checkOuts++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Check Out'));
    await tester.pump();

    expect(checkIns, 0);
    expect(checkOuts, 1);
    expect(find.text('Check In'), findsNothing);
    expect(find.text('Check Out'), findsOneWidget);
  });

  testWidgets('no active attendance shows only Check In', (tester) async {
    var checkIns = 0;
    var checkOuts = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceActionControls(
            visible: true,
            canCheckIn: true,
            canCheckOut: false,
            onCheckIn: () => checkIns++,
            onCheckOut: () => checkOuts++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Check In'));
    await tester.pump();

    expect(checkIns, 1);
    expect(checkOuts, 0);
    expect(find.text('Check In'), findsOneWidget);
    expect(find.text('Check Out'), findsNothing);
  });

  testWidgets('submitting shows a loader and prevents repeated taps',
      (tester) async {
    var checkIns = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttendanceActionControls(
            visible: true,
            canCheckIn: true,
            canCheckOut: false,
            isSubmitting: true,
            submittingCheckIn: true,
            onCheckIn: () => checkIns++,
            onCheckOut: () {},
          ),
        ),
      ),
    );

    expect(find.text('Check In'), findsOneWidget);
    expect(find.text('Check Out'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final checkInButton = find.ancestor(
      of: find.text('Check In'),
      matching: find.byType(InkWell),
    );
    expect(tester.widget<InkWell>(checkInButton.first).onTap, isNull);
    await tester.tap(find.text('Check In'));
    expect(checkIns, 0);
  });
}
