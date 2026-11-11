import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lyrapulse_mobile/app/routes/app_routes.dart';
import 'package:lyrapulse_mobile/core/network/dio_client.dart';
import 'package:lyrapulse_mobile/core/services/location_service.dart';
import 'package:lyrapulse_mobile/core/storage/secure_storage_service.dart';
import 'package:lyrapulse_mobile/data/models/attendance_model.dart';
import 'package:lyrapulse_mobile/data/models/employee_model.dart';
import 'package:lyrapulse_mobile/data/providers/api_provider.dart';
import 'package:lyrapulse_mobile/data/repositories/attendance_repository.dart';
import 'package:lyrapulse_mobile/data/repositories/auth_repository.dart';
import 'package:lyrapulse_mobile/features/attendance/controllers/attendance_controller.dart';
import 'package:lyrapulse_mobile/features/auth/controllers/auth_controller.dart';
import 'package:lyrapulse_mobile/features/home/widgets/attendance_hero_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _AttendanceAdapter adapter;
  late AttendanceController attendance;
  late AuthController auth;

  setUp(() async {
    Get.testMode = true;
    adapter = _AttendanceAdapter();
    final storage = _MemorySecureStorage();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.example/api/v1/'))
      ..httpClientAdapter = adapter;
    final client = DioClient(dio: dio, secureStorage: storage);
    final api = ApiProvider(client);

    Get.put<SecureStorageService>(storage);
    Get.put<DioClient>(client);
    Get.put<ApiProvider>(api);
    Get.put<AuthRepository>(AuthRepository(api, storage));
    Get.put<AttendanceRepository>(AttendanceRepository(api));
    Get.put<LocationService>(LocationService());
    auth = Get.put<AuthController>(AuthController());
    auth.employee.value = EmployeeModel.fromJson(_profile(true));
    attendance = Get.put<AttendanceController>(AttendanceController());
    await attendance.refreshToday();
  });

  tearDown(() async {
    attendance.onClose();
    Get.reset();
    adapter.close();
  });

  testWidgets('confirmed check-in replaces Check In with Check Out',
      (tester) async {
    await _pumpHome(tester);

    expect(find.text('Check In'), findsOneWidget);
    expect(find.text('Check Out'), findsNothing);
    await tester.tap(find.text('Check In'));
    await _pumpAction(tester, attendance);

    expect(adapter.state, AttendanceState.checkedIn);
    expect(find.text('Attendance submitted'), findsOneWidget);
    Get.offNamed(AppRoutes.home);
    await _pumpRoute(tester);
    expect(find.text('Check In'), findsNothing);
    expect(find.text('Check Out'), findsOneWidget);
    attendance.onClose();
  });

  testWidgets('confirmed check-out replaces Check Out with Check In',
      (tester) async {
    adapter.state = AttendanceState.checkedIn;
    await tester.runAsync(attendance.refreshToday);
    await _pumpHome(tester);

    expect(find.text('Check Out'), findsOneWidget);
    expect(find.text('Check In'), findsNothing);
    await tester.tap(find.text('Check Out'));
    await _pumpAction(tester, attendance);

    expect(adapter.state, AttendanceState.checkedOut);
    expect(find.text('Attendance submitted'), findsOneWidget);
    Get.offNamed(AppRoutes.home);
    await _pumpRoute(tester);
    expect(find.text('Check Out'), findsNothing);
    expect(find.text('Check In'), findsOneWidget);
    attendance.onClose();
  });

  testWidgets('failed Check In preserves the no-attendance action',
      (tester) async {
    adapter.failCheckIn = true;
    await _pumpHome(tester);

    await tester.tap(find.text('Check In'));
    await _pumpAction(tester, attendance);

    expect(attendance.state, AttendanceState.notCheckedIn);
    expect(find.text('Check In'), findsOneWidget);
    expect(find.text('Check Out'), findsNothing);
    expect(attendance.submitError.value, 'Punch rejected');
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('failed Check Out preserves the active-session action',
      (tester) async {
    adapter.state = AttendanceState.checkedIn;
    adapter.failCheckOut = true;
    await tester.runAsync(attendance.refreshToday);
    await _pumpHome(tester);

    await tester.tap(find.text('Check Out'));
    await _pumpAction(tester, attendance);

    expect(attendance.state, AttendanceState.checkedIn);
    expect(find.text('Check Out'), findsOneWidget);
    expect(find.text('Check In'), findsNothing);
    expect(attendance.submitError.value, 'Punch rejected');
    attendance.onClose();
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('permission refresh hides and restores action from fresh profile',
      (tester) async {
    await _pumpHome(tester);
    expect(find.text('Check In'), findsOneWidget);

    adapter.mobileAttendanceEnabled = false;
    await tester.runAsync(attendance.refreshToday);
    await tester.pump();
    expect(find.text('Check In'), findsNothing);
    expect(find.text('Check Out'), findsNothing);

    adapter.mobileAttendanceEnabled = true;
    adapter.state = AttendanceState.checkedIn;
    await tester.runAsync(attendance.refreshToday);
    await tester.pump();
    expect(find.text('Check In'), findsNothing);
    expect(find.text('Check Out'), findsOneWidget);
    attendance.onClose();
  });

  test('refresh reloads both today attendance and authenticated profile',
      () async {
    final todayBefore = adapter.todayRequests;
    final profileBefore = adapter.employeeProfileRequests;
    final currentUserBefore = adapter.currentUserRequests;

    await attendance.refreshToday();

    expect(adapter.todayRequests, todayBefore + 1);
    expect(adapter.employeeProfileRequests, profileBefore + 1);
    expect(adapter.currentUserRequests, currentUserBefore + 1);
  });

  testWidgets('profile refresh failure hides actions and exposes an error',
      (tester) async {
    await _pumpHome(tester);
    adapter.failProfile = true;

    await tester.runAsync(attendance.refreshToday);
    await tester.pump();

    expect(attendance.mobileAttendanceEnabled, isFalse);
    expect(find.text('Check In'), findsNothing);
    expect(find.text('Check Out'), findsNothing);
    expect(attendance.profileError.value, isNotNull);
    expect(find.text(attendance.profileError.value!), findsOneWidget);
  });

  test('overlapping refreshes share requests and settle consistently',
      () async {
    final todayBefore = adapter.todayRequests;
    final profileBefore = adapter.employeeProfileRequests;
    final gate = Completer<void>();
    adapter.todayGate = gate;

    final first = attendance.refreshToday();
    final second = attendance.refreshToday();
    expect(identical(first, second), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(adapter.todayRequests, todayBefore + 1);
    expect(adapter.employeeProfileRequests, profileBefore + 1);
    expect(attendance.isLoadingToday.value, isTrue);

    gate.complete();
    await first;
    expect(attendance.isLoadingToday.value, isFalse);
    expect(attendance.state, AttendanceState.notCheckedIn);
    expect(attendance.mobileAttendanceEnabled, isTrue);
  });

  test('normal profile reload and re-login use current permission values',
      () async {
    adapter.mobileAttendanceEnabled = false;
    await auth.reloadEmployeeProfile();
    expect(auth.employee.value?.mobileAttendanceEnabled, isFalse);

    auth.phoneController.text = '9876543210';
    auth.otpController.text = '123456';
    adapter.mobileAttendanceEnabled = true;
    await auth.verifyOtp();
    expect(auth.employee.value?.mobileAttendanceEnabled, isTrue);
  });

  test('fingerprint permission remains independent of mobile permission', () {
    adapter.mobileAttendanceEnabled = false;
    final employee = EmployeeModel.fromJson({
      ..._profile(false),
      'biometric_attendance_enabled': true,
    });

    expect(employee.mobileAttendanceEnabled, isFalse);
    expect(employee.biometricAttendanceEnabled, isTrue);
  });
}

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(
    GetMaterialApp(
      initialRoute: AppRoutes.home,
      getPages: [
        GetPage(
          name: AppRoutes.home,
          page: () => const Scaffold(body: AttendanceHeroCard()),
        ),
        GetPage(
          name: AppRoutes.attendanceSuccess,
          page: () => const Scaffold(body: Text('Attendance submitted')),
        ),
      ],
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Future<void> _pumpAction(
  WidgetTester tester,
  AttendanceController attendance,
) async {
  await tester.pump();
  for (var attempt = 0;
      attempt < 100 && attendance.isSubmitting.value;
      attempt++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  if (attendance.isSubmitting.value) {
    fail('Attendance action did not finish in the test window.');
  }
  await tester.pump();
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

Map<String, dynamic> _profile(bool mobileAttendanceEnabled) => {
      'id': 42,
      'employee_code': 'EMP-42',
      'name': 'Test Employee',
      'phone_number': '9876543210',
      'mobile_gps_attendance_enabled': mobileAttendanceEnabled,
      'location_attendance_enabled': false,
      'photo_attendance_enabled': false,
      'biometric_attendance_enabled': false,
    };

ResponseBody _jsonResponse(Map<String, dynamic> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _MemorySecureStorage extends SecureStorageService {
  String? _access = 'synthetic-access';
  String? _refresh = 'synthetic-refresh';

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> saveTokens(
      {required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
  }
}

class _AttendanceAdapter implements HttpClientAdapter {
  AttendanceState state = AttendanceState.notCheckedIn;
  bool mobileAttendanceEnabled = true;
  bool failCheckIn = false;
  bool failCheckOut = false;
  bool failProfile = false;
  Completer<void>? todayGate;
  int todayRequests = 0;
  int employeeProfileRequests = 0;
  int currentUserRequests = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('attendance/today/')) {
      todayRequests++;
      await todayGate?.future;
      return _jsonResponse({
        'success': true,
        'data': {'state': _stateName(state), 'sessions': []},
      });
    }

    if (options.path.endsWith('mobile/me/')) {
      employeeProfileRequests++;
      if (failProfile) {
        return _jsonResponse(
          {'success': false, 'message': 'Profile unavailable'},
          status: 503,
        );
      }
      return _jsonResponse(
          {'success': true, 'data': _profile(mobileAttendanceEnabled)});
    }

    if (options.path.endsWith('auth/me/')) {
      currentUserRequests++;
      return _jsonResponse({
        'success': true,
        'data': {
          'user': {'email': 'employee@example.com'},
        },
      });
    }

    if (options.path.endsWith('auth/employee/verify-otp/')) {
      return _jsonResponse({
        'success': true,
        'data': {
          'access': 'new-access',
          'refresh': 'new-refresh',
        },
      });
    }

    if (options.path.endsWith('attendance/check-in/')) {
      if (failCheckIn) {
        return _jsonResponse(
          {'success': false, 'message': 'Punch rejected'},
          status: 403,
        );
      }
      state = AttendanceState.checkedIn;
      return _punchResponse();
    }

    if (options.path.endsWith('attendance/check-out/')) {
      if (failCheckOut) {
        return _jsonResponse(
          {'success': false, 'message': 'Punch rejected'},
          status: 403,
        );
      }
      state = AttendanceState.checkedOut;
      return _punchResponse();
    }

    return _jsonResponse({'success': true, 'data': {}});
  }

  ResponseBody _punchResponse() => _jsonResponse({
        'success': true,
        'data': {
          'attendance': {
            'check_in_at': '2026-11-06T09:00:00Z',
            'check_out_at': state == AttendanceState.checkedOut
                ? '2026-11-06T17:00:00Z'
                : null,
            'location_verified': true,
          },
        },
      });

  String _stateName(AttendanceState value) {
    switch (value) {
      case AttendanceState.notCheckedIn:
        return 'NOT_CHECKED_IN';
      case AttendanceState.checkedIn:
        return 'CHECKED_IN';
      case AttendanceState.checkedOut:
        return 'CHECKED_OUT';
    }
  }

  @override
  void close({bool force = false}) {}
}
