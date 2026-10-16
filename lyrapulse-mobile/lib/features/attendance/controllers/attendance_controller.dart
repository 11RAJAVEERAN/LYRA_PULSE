import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceController extends GetxController {
  final Rxn<DateTime> checkInTime = Rxn<DateTime>();
  final Rxn<DateTime> checkOutTime = Rxn<DateTime>();

  final Rx<Duration> workingDuration = Duration.zero.obs;

  final RxList<Map<String, dynamic>> attendanceHistory =
      <Map<String, dynamic>>[].obs;

  Timer? _timer;

  static const String _checkInKey = 'attendance_check_in';
  static const String _checkOutKey = 'attendance_check_out';
  static const String _historyKey = 'attendance_history';

  bool _isInitialized = false;

  // HomeScreen and confirmation screen compatibility.
  bool get isCheckedIn {
    return checkInTime.value != null && !isCompleted;
  }

  bool get isCompleted {
    return checkInTime.value != null &&
        checkOutTime.value != null;
  }

  String get attendanceStatus {
    if (isCompleted) {
      return 'Completed';
    }

    if (isCheckedIn) {
      return 'Checked In';
    }

    return 'Not Checked In';
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAttendance();
  }

  Future<void> _initializeAttendance() async {
    if (_isInitialized) return;

    await loadHistory();

    final prefs = await SharedPreferences.getInstance();

    final savedCheckIn = prefs.getString(_checkInKey);
    final savedCheckOut = prefs.getString(_checkOutKey);

    final now = DateTime.now();

    final parsedCheckIn = savedCheckIn == null
        ? null
        : DateTime.tryParse(savedCheckIn);

    final parsedCheckOut = savedCheckOut == null
        ? null
        : DateTime.tryParse(savedCheckOut);

    if (parsedCheckIn != null &&
        _sameDate(parsedCheckIn, now)) {
      checkInTime.value = parsedCheckIn;

      if (parsedCheckOut != null &&
          _sameDate(parsedCheckOut, now)) {
        checkOutTime.value = parsedCheckOut;
      } else {
        checkOutTime.value = null;
      }
    } else {
      checkInTime.value = null;
      checkOutTime.value = null;
    }

    _updateWorkingDuration();
    _startTimer();

    _isInitialized = true;

    if (checkInTime.value != null) {
      await _syncHistory();
    }
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHistory = prefs.getString(_historyKey);

    if (savedHistory == null || savedHistory.isEmpty) {
      attendanceHistory.clear();
      return;
    }

    try {
      final decoded = jsonDecode(savedHistory);

      if (decoded is List) {
        final records = decoded
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
            )
            .toList();

        records.sort((a, b) {
          final dateA = a['date']?.toString() ?? '';
          final dateB = b['date']?.toString() ?? '';
          return dateB.compareTo(dateA);
        });

        attendanceHistory.assignAll(records);
      }
    } catch (e) {
      print('Attendance history loading error: $e');
    }
  }

  Future<void> checkInNow() async {
    await _ensureInitialized();

    final now = DateTime.now();

    if (checkInTime.value != null &&
        _sameDate(checkInTime.value!, now)) {
      return;
    }

    checkInTime.value = now;
    checkOutTime.value = null;
    workingDuration.value = Duration.zero;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _checkInKey,
      now.toIso8601String(),
    );

    await prefs.remove(_checkOutKey);

    await _syncHistory();
    _startTimer();
  }

  Future<void> checkOutNow() async {
    await _ensureInitialized();

    final checkIn = checkInTime.value;

    if (checkIn == null ||
        checkOutTime.value != null ||
        !_sameDate(checkIn, DateTime.now())) {
      return;
    }

    final now = DateTime.now();

    checkOutTime.value = now;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _checkOutKey,
      now.toIso8601String(),
    );

    _updateWorkingDuration();

    await _syncHistory();
    _stopTimer();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeAttendance();
    }
  }

  Future<void> _syncHistory() async {
    final checkIn = checkInTime.value;

    if (checkIn == null) return;

    final checkOut = checkOutTime.value;
    final date = _dateKey(checkIn);

    final record = <String, dynamic>{
      'date': date,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
      'status': checkOut == null ? 'Checked In' : 'Completed',
      'workingMinutes': _calculateWorkingMinutes(
        checkIn,
        checkOut ?? DateTime.now(),
      ),
    };

    final index = attendanceHistory.indexWhere(
      (item) => item['date']?.toString() == date,
    );

    if (index >= 0) {
      attendanceHistory[index] = record;
    } else {
      attendanceHistory.add(record);
    }

    attendanceHistory.sort((a, b) {
      final dateA = a['date']?.toString() ?? '';
      final dateB = b['date']?.toString() ?? '';
      return dateB.compareTo(dateA);
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _historyKey,
      jsonEncode(attendanceHistory.toList()),
    );
  }

  int _calculateWorkingMinutes(
    DateTime start,
    DateTime end,
  ) {
    final difference = end.difference(start);

    if (difference.isNegative) return 0;

    return difference.inMinutes;
  }

  void _updateWorkingDuration() {
    final checkIn = checkInTime.value;

    if (checkIn == null) {
      workingDuration.value = Duration.zero;
      return;
    }

    final end = checkOutTime.value ?? DateTime.now();
    final difference = end.difference(checkIn);

    workingDuration.value = difference.isNegative
        ? Duration.zero
        : difference;
  }

  void _startTimer() {
    _stopTimer();

    if (checkInTime.value == null ||
        checkOutTime.value != null) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        _updateWorkingDuration();
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String formatTime(DateTime? time) {
    if (time == null) return '--:--';

    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String get formattedWorkingDuration {
    final duration = workingDuration.value;

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  Future<void> resetAttendance() async {
    _stopTimer();

    checkInTime.value = null;
    checkOutTime.value = null;
    workingDuration.value = Duration.zero;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_checkInKey);
    await prefs.remove(_checkOutKey);

    // Keep previously saved attendance history.
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
  }
}