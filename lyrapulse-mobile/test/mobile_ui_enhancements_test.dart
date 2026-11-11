import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lyrapulse_mobile/core/network/dio_client.dart';
import 'package:lyrapulse_mobile/core/services/location_service.dart';
import 'package:lyrapulse_mobile/core/storage/secure_storage_service.dart';
import 'package:lyrapulse_mobile/data/models/employee_model.dart';
import 'package:lyrapulse_mobile/data/providers/api_provider.dart';
import 'package:lyrapulse_mobile/data/repositories/attendance_repository.dart';
import 'package:lyrapulse_mobile/data/repositories/auth_repository.dart';
import 'package:lyrapulse_mobile/features/attendance/controllers/attendance_controller.dart';
import 'package:lyrapulse_mobile/features/attendance/views/attendance_history_screen.dart';
import 'package:lyrapulse_mobile/features/auth/controllers/auth_controller.dart';
import 'package:lyrapulse_mobile/features/auth/views/login_screen.dart';
import 'package:lyrapulse_mobile/features/auth/views/otp_screen.dart';
import 'package:lyrapulse_mobile/features/home/controllers/home_controller.dart';
import 'package:lyrapulse_mobile/features/home/views/home_screen.dart';
import 'package:lyrapulse_mobile/features/home/widgets/bottom_nav_bar.dart';
import 'package:lyrapulse_mobile/features/home/widgets/home_drawer.dart';
import 'package:lyrapulse_mobile/features/home/widgets/quick_action_card.dart';
import 'package:lyrapulse_mobile/features/profile/controllers/profile_controller.dart';
import 'package:lyrapulse_mobile/features/profile/views/profile_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _UiApiAdapter adapter;
  late AuthController auth;
  late AttendanceController attendance;
  var attendanceClosed = false;

  setUp(() {
    Get.testMode = true;
    attendanceClosed = false;
    adapter = _UiApiAdapter();
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
    attendance = Get.put<AttendanceController>(AttendanceController());
    Get.put<HomeController>(HomeController());
    Get.put<ProfileController>(ProfileController());
  });

  tearDown(() {
    if (!attendanceClosed) attendance.onClose();
    Get.reset();
    adapter.close();
  });

  testWidgets('login screen clearly submits an OTP request', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: LoginScreen()));

    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('OR'), findsNothing);
    expect(find.text('Enter your registered mobile number'), findsOneWidget);
  });

  testWidgets('OTP screen shows inline validation feedback', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: OtpScreen()));
    await tester.ensureVisible(find.text('Verify OTP'));
    await tester.tap(find.text('Verify OTP'));
    await tester.pump();

    expect(find.textContaining('We couldn’t verify that code'), findsOneWidget);
    expect(find.byType(OtpScreen), findsOneWidget);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  });

  testWidgets('dashboard keeps available actions and marks placeholders',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: HomeScreen()));
    await tester.pump();

    expect(find.text('Quick Actions'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(QuickActionCard),
        matching: find.text('History'),
      ),
      findsOneWidget,
    );
    expect(find.text('Coming soon'), findsNWidgets(3));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('Your workplace'), findsOneWidget);
  });

  testWidgets('drawer separates navigation and marks unavailable destinations',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: HomeDrawer()));
    await tester.pump();

    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(find.text('ATTENDANCE & REQUESTS'), findsOneWidget);
    expect(find.text('Soon'), findsAtLeastNWidgets(1));
    expect(find.text('Attendance History'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Soon'), findsAtLeastNWidgets(1));
  });

  testWidgets('bottom navigation communicates its destinations',
      (tester) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomNavBar(
            selectedIndex: 0,
            onChanged: (index) => selected = index,
          ),
        ),
      ),
    );

    expect(find.text('History'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    expect(selected, 3);
    await tester.pumpAndSettle();
  });

  testWidgets('profile screen shows grouped employee details and refresh',
      (tester) async {
    attendance.onClose();
    attendanceClosed = true;
    auth.employee.value = const EmployeeModel(
      id: 8,
      employeeCode: 'EMP-8',
      name: 'Test Employee',
      phoneNumber: '9876543210',
      email: 'employee@example.com',
      branch: 'Central',
      department: 'Operations',
    );
    await tester.pumpWidget(const GetMaterialApp(home: ProfileView()));

    expect(find.text('Contact information'), findsOneWidget);
    expect(find.text('Employment details'), findsOneWidget);
    expect(find.text('Central'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('history shows attendance records in a readable card',
      (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(home: AttendanceHistoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Attendance Records'), findsOneWidget);
    expect(find.text('Present'), findsOneWidget);
    expect(find.textContaining('GPS verified'), findsOneWidget);
  });

  testWidgets('quick action is tap-accessible and retains its availability',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickActionCard(
            icon: Icons.event_busy_rounded,
            title: 'Leave',
            subtitle: 'Coming soon',
            isComingSoon: true,
            color: Colors.amber,
            onTap: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Leave'));
    expect(taps, 1);
    expect(find.text('Coming soon'), findsOneWidget);
  });

}

class _MemorySecureStorage extends SecureStorageService {
  String? _access = 'test-access';
  String? _refresh = 'test-refresh';

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    _access = access;
    _refresh = refresh;
  }

  @override
  Future<void> clearTokens() async {
    _access = null;
    _refresh = null;
  }
}

class _UiApiAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final today = DateTime.now();
    final attendanceDay =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    if (options.path.endsWith('attendance/history/')) {
      return _jsonResponse({
        'success': true,
        'data': {
          'count': 1,
          'page': 1,
          'page_size': 31,
          'has_next': false,
          'results': [
            {
              'id': 1,
              'attendance_date': attendanceDay,
              'check_in_at': '${attendanceDay}T09:00:00Z',
              'check_out_at': '${attendanceDay}T17:00:00Z',
              'working_seconds': 28800,
              'status': 'PRESENT',
              'source': 'mobile',
              'check_in_location_verified': true,
              'check_in_photo_available': true,
            }
          ],
        },
      });
    }
    if (options.path.endsWith('mobile/me/')) {
      return _jsonResponse({
        'success': true,
        'data': {
          'id': 8,
          'employee_code': 'EMP-8',
          'name': 'Test Employee',
          'phone_number': '9876543210',
          'mobile_gps_attendance_enabled': true,
        },
      });
    }
    if (options.path.endsWith('auth/me/')) {
      return _jsonResponse({
        'success': true,
        'data': {
          'user': {'email': 'employee@example.com'},
        },
      });
    }
    if (options.path.endsWith('attendance/today/')) {
      return _jsonResponse({
        'success': true,
        'data': {'state': 'NOT_CHECKED_IN', 'sessions': []},
      });
    }
    return _jsonResponse({'success': true, 'data': {}});
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body) =>
    ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
