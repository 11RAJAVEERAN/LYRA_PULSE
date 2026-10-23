import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BreakSession {
  final String id;
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final String? endAddress;

  const BreakSession({
    required this.id,
    required this.type,
    required this.startTime,
    this.endTime,
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    this.endAddress,
  });

  bool get isActive => endTime == null;

  Duration durationAt(DateTime now) {
    final duration = (endTime ?? now).difference(startTime);
    return duration.isNegative ? Duration.zero : duration;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'startLatitude': startLatitude,
        'startLongitude': startLongitude,
        'endLatitude': endLatitude,
        'endLongitude': endLongitude,
        'endAddress': endAddress,
      };

  factory BreakSession.fromJson(Map<String, dynamic> json) {
    double? number(dynamic value) =>
        value is num ? value.toDouble() : null;

    return BreakSession(
      id: json['id'] as String,
      type: json['type'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      startLatitude: number(json['startLatitude']),
      startLongitude: number(json['startLongitude']),
      endLatitude: number(json['endLatitude']),
      endLongitude: number(json['endLongitude']),
      endAddress: json['endAddress'] as String?,
    );
  }
}

class AttendanceController extends GetxController {
  final Rxn<DateTime> checkInTime = Rxn<DateTime>();
  final Rxn<DateTime> checkOutTime = Rxn<DateTime>();

  final Rx<Duration> workingDuration = Duration.zero.obs;
  final RxList<Map<String, dynamic>> attendanceHistory =
      <Map<String, dynamic>>[].obs;
  final RxList<BreakSession> breakSessions = <BreakSession>[].obs;
  final RxBool isBreakLoading = true.obs;
  final RxInt _clockTick = 0.obs;

  Timer? _timer;
  bool _isInitialized = false;
  bool _isSavingAttendanceAction = false;

  static const String _checkInKey = 'attendance_check_in';
  static const String _checkOutKey = 'attendance_check_out';
  static const String _historyKey = 'attendance_history';

  String _breakKey(DateTime date) => 'lyra_breaks_${_dateKey(date)}';

  BreakSession? get activeBreak {
    for (final session in breakSessions.reversed) {
      if (session.isActive) return session;
    }
    return null;
  }

  bool get canStartBreak => activeBreak == null;
  bool get canEndBreak => activeBreak != null;
  bool get canCheckOut => activeBreak == null;

  Duration get totalBreakDuration {
    _clockTick.value;
    final now = DateTime.now();
    return breakSessions.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.durationAt(now),
    );
  }

  Duration get activeBreakDuration {
    _clockTick.value;
    final current = activeBreak;
    return current == null
        ? Duration.zero
        : current.durationAt(DateTime.now());
  }

  String get formattedBreakDuration => formatDuration(totalBreakDuration);
  String get formattedNetWorkingDuration =>
      formatDuration(workingDuration.value);

  String get attendanceStatus {
    if (activeBreak != null) return 'On Break';
    if (isCompleted) return 'Completed';
    if (isCheckedIn) return 'Checked In';
    return 'Not Checked In';
  }

  // A Punch Out means the employee is on break, not that the day's
  // attendance is permanently completed. They can Punch In again.
  bool get isCheckedIn =>
      checkInTime.value != null &&
      checkOutTime.value == null &&
      activeBreak == null;

  // This remains true only when the day's final attendance is closed.
  // A later Punch In clears checkOutTime and resumes the same attendance day.
  bool get isCompleted =>
      checkInTime.value != null &&
      checkOutTime.value != null &&
      activeBreak == null;

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

    final parsedCheckIn =
        savedCheckIn == null ? null : DateTime.tryParse(savedCheckIn);
    final parsedCheckOut =
        savedCheckOut == null ? null : DateTime.tryParse(savedCheckOut);

    if (parsedCheckIn != null && _sameDate(parsedCheckIn, now)) {
      checkInTime.value = parsedCheckIn;
      checkOutTime.value =
          parsedCheckOut != null && _sameDate(parsedCheckOut, now)
              ? parsedCheckOut
              : null;
    } else {
      checkInTime.value = null;
      checkOutTime.value = null;
      // Do not let yesterday's unfinished break affect today's totals.
    }

    await loadBreakSessions();

    _isInitialized = true;
    _updateWorkingDuration();
    _startTimer();

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
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        records.sort(
          (a, b) => (b['date']?.toString() ?? '')
              .compareTo(a['date']?.toString() ?? ''),
        );
        attendanceHistory.assignAll(records);
      }
    } catch (e) {
      debugPrint('Attendance history loading error: $e');
    }
  }

  Future<void> loadBreakSessions() async {
    isBreakLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_breakKey(DateTime.now()));
      if (raw == null || raw.isEmpty) {
        breakSessions.clear();
      } else {
        final decoded = jsonDecode(raw) as List;
        breakSessions.assignAll(
          decoded.map(
            (item) => BreakSession.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Break history loading error: $e');
      breakSessions.clear();
    } finally {
      isBreakLoading.value = false;
      _updateWorkingDuration();
    }
  }

  Future<void> _saveBreakSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _breakKey(DateTime.now()),
      jsonEncode(breakSessions.map((session) => session.toJson()).toList()),
    );
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Please turn on your device location.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in Settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Future<String?> _getAddress(double latitude, double longitude) async {
    try {
      final places = await placemarkFromCoordinates(latitude, longitude);
      if (places.isEmpty) return null;
      final place = places.first;
      final parts = <String?>[
        place.name,
        place.street,
        place.subLocality,
        place.locality,
        place.administrativeArea,
        place.postalCode,
      ]
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    } catch (e) {
      debugPrint('Break return address lookup error: $e');
      return null;
    }
  }

  /// Starts a break. Calling this from Punch Out means even a 1-second
  /// break is tracked with its real elapsed duration.
  Future<String?> startBreak(String type) async {
    await _ensureInitialized();
    if (activeBreak != null) return 'A break is already in progress.';

    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    breakSessions.add(BreakSession(
      id: id,
      type: type,
      startTime: now,
    ));

    try {
      await _saveBreakSessions();
      _updateWorkingDuration();
      _startTimer();
      if (checkInTime.value != null) await _syncHistory();
      return null;
    } catch (e) {
      breakSessions.removeWhere((item) => item.id == id);
      _updateWorkingDuration();
      _startTimer();
      debugPrint('Break start save error: $e');
      return 'Unable to save break. Please try again.';
    }
  }

  /// Ends an active break and records return GPS when available.
  /// Punch In can call this after location verification has succeeded.
  Future<String?> endBreak() async {
    await _ensureInitialized();
    final current = activeBreak;
    if (current == null) return 'There is no active break.';

    final index = breakSessions.indexWhere((item) => item.id == current.id);
    if (index == -1) return 'Could not find the active break.';

    Position? position;
    String? address;
    try {
      position = await _getCurrentPosition();
      address = await _getAddress(position.latitude, position.longitude);
    } catch (e) {
      // Location verification may already have run in the screen flow.
      // Do not lose a valid return Punch In solely because reverse geocoding
      // or this secondary GPS lookup failed.
      debugPrint('Break return location lookup: $e');
    }

    final completedSession = BreakSession(
      id: current.id,
      type: current.type,
      startTime: current.startTime,
      endTime: DateTime.now(),
      startLatitude: current.startLatitude,
      startLongitude: current.startLongitude,
      endLatitude: position?.latitude,
      endLongitude: position?.longitude,
      endAddress: address,
    );

    breakSessions[index] = completedSession;
    try {
      await _saveBreakSessions();
      _updateWorkingDuration();
      _startTimer();
      if (checkInTime.value != null) await _syncHistory();
      return null;
    } catch (e) {
      breakSessions[index] = current;
      debugPrint('Break check-in save error: $e');
      return 'Unable to save break. Please try again.';
    }
  }

  /// Punch In. If a break is active, closes it and resumes the same
  /// attendance record; otherwise starts a new attendance for the day.
  Future<void> checkInNow() async {
    await _ensureInitialized();
    if (_isSavingAttendanceAction) return;
    _isSavingAttendanceAction = true;

    try {
      final now = DateTime.now();
      final existingCheckIn = checkInTime.value;

      // Returning from break: end break and resume the existing attendance.
      if (activeBreak != null) {
        final result = await _closeActiveBreakAt(now);
        if (result != null) {
          throw Exception(result);
        }

        checkOutTime.value = null;
        await _persistCheckTimes(checkIn: existingCheckIn, checkOut: null);
        _updateWorkingDuration();
        await _syncHistory();
        _startTimer();
        return;
      }

      // Ignore duplicate Punch In while already working.
      if (existingCheckIn != null &&
          _sameDate(existingCheckIn, now) &&
          checkOutTime.value == null) {
        return;
      }

      // A new day's first Punch In, or a fresh attendance after a completed
      // day. Keep previous days in history.
      checkInTime.value = now;
      checkOutTime.value = null;
      workingDuration.value = Duration.zero;
      await _persistCheckTimes(checkIn: now, checkOut: null);
      await _syncHistory();
      _startTimer();
    } finally {
      _isSavingAttendanceAction = false;
    }
  }

  /// Punch Out. If attendance is active, closes the work session and
  /// immediately starts a break. It does not permanently finish the day:
  /// the next Punch In closes this break and resumes work.
  Future<void> checkOutNow() async {
    await _ensureInitialized();
    if (_isSavingAttendanceAction) return;
    _isSavingAttendanceAction = true;

    try {
      final checkIn = checkInTime.value;
      final now = DateTime.now();

      if (checkIn == null ||
          !_sameDate(checkIn, now) ||
          checkOutTime.value != null ||
          activeBreak != null) {
        return;
      }

      final id = now.microsecondsSinceEpoch.toString();
      final breakSession = BreakSession(
        id: id,
        type: 'Punch Out Break',
        startTime: now,
      );

      // Save the break first. If persistence fails, don't mutate attendance.
      breakSessions.add(breakSession);
      try {
        await _saveBreakSessions();
        checkOutTime.value = now;
        await _persistCheckTimes(checkIn: checkIn, checkOut: now);
        _updateWorkingDuration();
        await _syncHistory();
        _startTimer();
      } catch (e) {
        breakSessions.removeWhere((item) => item.id == id);
        checkOutTime.value = null;
        _updateWorkingDuration();
        _startTimer();
        rethrow;
      }
    } finally {
      _isSavingAttendanceAction = false;
    }
  }

  Future<String?> _closeActiveBreakAt(DateTime endTime) async {
    final current = activeBreak;
    if (current == null) return null;
    final index = breakSessions.indexWhere((item) => item.id == current.id);
    if (index == -1) return 'Could not find the active break.';

    final completed = BreakSession(
      id: current.id,
      type: current.type,
      startTime: current.startTime,
      endTime: endTime,
      startLatitude: current.startLatitude,
      startLongitude: current.startLongitude,
      endLatitude: current.endLatitude,
      endLongitude: current.endLongitude,
      endAddress: current.endAddress,
    );

    breakSessions[index] = completed;
    try {
      await _saveBreakSessions();
      return null;
    } catch (e) {
      breakSessions[index] = current;
      debugPrint('Unable to close break: $e');
      return 'Unable to save break. Please try again.';
    }
  }

  Future<void> _persistCheckTimes({
    required DateTime? checkIn,
    required DateTime? checkOut,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (checkIn == null) {
      await prefs.remove(_checkInKey);
    } else {
      await prefs.setString(_checkInKey, checkIn.toIso8601String());
    }

    if (checkOut == null) {
      await prefs.remove(_checkOutKey);
    } else {
      await prefs.setString(_checkOutKey, checkOut.toIso8601String());
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await _initializeAttendance();
  }

  Future<void> _syncHistory() async {
    final checkIn = checkInTime.value;
    if (checkIn == null) return;

    final checkOut = checkOutTime.value;
    final now = DateTime.now();

    // When working, count up to now. When on break, stop work at Punch Out.
    final end = activeBreak?.startTime ?? checkOut ?? now;

    final dayBreaks = breakSessions
        .where((session) => _sameDate(session.startTime, checkIn))
        .toList();

    final breakDuration = dayBreaks.fold<Duration>(
      Duration.zero,
      (total, session) => total + session.durationAt(now),
    );

    final elapsed = end.difference(checkIn);
    // Only subtract breaks that fall before the work endpoint. The currently
    // active break starts exactly at `end`, so it must not be subtracted twice.
    final breaksInsideWorkWindow = dayBreaks.fold<Duration>(
      Duration.zero,
      (total, session) {
        if (!session.startTime.isBefore(end)) return total;
        final sessionEnd = session.endTime ?? now;
        final cappedEnd = sessionEnd.isAfter(end) ? end : sessionEnd;
        final duration = cappedEnd.difference(session.startTime);
        return total + (duration.isNegative ? Duration.zero : duration);
      },
    );
    final net = elapsed - breaksInsideWorkWindow;

    final index = attendanceHistory.indexWhere(
      (item) => item['date']?.toString() == _dateKey(checkIn),
    );

    final existing = index >= 0 ? attendanceHistory[index] : null;
    final record = <String, dynamic>{
      if (existing != null) ...existing,
      'date': _dateKey(checkIn),
      'checkIn': checkIn.toIso8601String(),
      // Preserve latest Punch Out while on break, clear on return Punch In.
      'checkOut': checkOut?.toIso8601String(),
      'status': activeBreak != null
          ? 'On Break'
          : (checkOut == null ? 'Checked In' : 'Completed'),
      'workingMinutes': (net.inSeconds / 60).floor().clamp(0, 100000000),
      'breakMinutes': (breakDuration.inSeconds / 60).floor(),
      'breakSessions': dayBreaks.map((session) => session.toJson()).toList(),
    };

    if (index >= 0) {
      attendanceHistory[index] = record;
    } else {
      attendanceHistory.add(record);
    }

    attendanceHistory.sort(
      (a, b) =>
          (b['date']?.toString() ?? '').compareTo(a['date']?.toString() ?? ''),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(attendanceHistory.toList()));
  }

  void _updateWorkingDuration() {
    final checkIn = checkInTime.value;
    if (checkIn == null) {
      workingDuration.value = Duration.zero;
      return;
    }

    final now = DateTime.now();
    // While on break, working time stops at break start. While working,
    // it counts to now. Once finally checked out, it remains stopped.
    final end = activeBreak?.startTime ?? checkOutTime.value ?? now;
    final elapsed = end.difference(checkIn);

    final breaksInsideWorkWindow = breakSessions.fold<Duration>(
      Duration.zero,
      (total, session) {
        if (!_sameDate(session.startTime, checkIn) ||
            !session.startTime.isBefore(end)) {
          return total;
        }
        final sessionEnd = session.endTime ?? now;
        final cappedEnd = sessionEnd.isAfter(end) ? end : sessionEnd;
        final duration = cappedEnd.difference(session.startTime);
        return total + (duration.isNegative ? Duration.zero : duration);
      },
    );

    final net = elapsed - breaksInsideWorkWindow;
    workingDuration.value = net.isNegative ? Duration.zero : net;
  }

  void _startTimer() {
    _stopTimer();

    // Tick during work or while a break is active so both clocks update.
    if (checkInTime.value == null ||
        (checkOutTime.value != null && activeBreak == null)) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _clockTick.value++;
      _updateWorkingDuration();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

  String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m';
  }

  String formatElapsedDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String get formattedWorkingDuration =>
      formatElapsedDuration(workingDuration.value);

  Future<void> resetAttendance() async {
    _stopTimer();
    checkInTime.value = null;
    checkOutTime.value = null;
    workingDuration.value = Duration.zero;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_checkInKey);
    await prefs.remove(_checkOutKey);
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
  }
}
