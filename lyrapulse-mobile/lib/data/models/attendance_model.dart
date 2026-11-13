/// Backend attendance state for the current day (`GET attendance/today/`).
enum AttendanceState {
  notCheckedIn,
  checkedIn,
  checkedOut;

  static AttendanceState parse(Object? value) {
    switch (value?.toString()) {
      case 'CHECKED_IN':
        return AttendanceState.checkedIn;
      case 'CHECKED_OUT':
        return AttendanceState.checkedOut;
      default:
        return AttendanceState.notCheckedIn;
    }
  }
}

/// Which attendance action the employee is performing.
enum AttendanceAction { checkIn, checkOut }

DateTime? _parseServerTime(Object? value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed?.toLocal();
}

class TodayAttendance {
  const TodayAttendance({
    required this.state,
    this.attendanceDate,
    this.checkInAt,
    this.checkOutAt,
    this.sessions = const [],
    this.shiftSchedule,
  });

  final AttendanceState state;
  final DateTime? attendanceDate;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final List<TodaySession> sessions;
  final TodayShiftSchedule? shiftSchedule;

  factory TodayAttendance.fromJson(Map<String, dynamic> json) =>
      TodayAttendance(
        state: AttendanceState.parse(json['state']),
        attendanceDate:
            DateTime.tryParse(json['attendance_date']?.toString() ?? ''),
        checkInAt: _parseServerTime(json['check_in_at']),
        checkOutAt: _parseServerTime(json['check_out_at']),
        sessions:
            (json['sessions'] is List ? json['sessions'] as List : const [])
                .whereType<Map>()
                .map((item) =>
                    TodaySession.fromJson(Map<String, dynamic>.from(item)))
                .toList(growable: false),
        shiftSchedule: json['shift_schedule'] is Map
            ? TodayShiftSchedule.fromJson(
                Map<String, dynamic>.from(json['shift_schedule'] as Map))
            : null,
      );

  Duration scheduledBreakDurationAt(DateTime now) {
    final schedule = shiftSchedule;
    final day = attendanceDate;
    if (schedule == null || !schedule.isWorking || day == null) {
      return Duration.zero;
    }

    final breakStart = schedule.timeOn(day, schedule.breakStartTime);
    final breakEnd = schedule.timeOn(day, schedule.breakEndTime);
    if (breakStart == null || breakEnd == null || !breakEnd.isAfter(breakStart)) {
      return Duration.zero;
    }

    final attendanceSessions = sessions.isEmpty
        ? [
            TodaySession(
              checkInAt: checkInAt,
              checkOutAt: checkOutAt,
            ),
          ]
        : sessions;
    var total = Duration.zero;
    for (final session in attendanceSessions) {
      final start = session.checkInAt;
      final end = session.checkOutAt ??
          (state == AttendanceState.checkedIn ? now : null);
      if (start == null || end == null) continue;

      final overlapStart = start.isAfter(breakStart) ? start : breakStart;
      final overlapEnd = end.isBefore(breakEnd) ? end : breakEnd;
      if (overlapEnd.isAfter(overlapStart)) {
        total += overlapEnd.difference(overlapStart);
      }
    }
    return total;
  }
}

class TodayShiftSchedule {
  const TodayShiftSchedule({
    required this.shiftName,
    required this.isWorking,
    this.startTime,
    this.endTime,
    this.breakStartTime,
    this.breakEndTime,
  });

  final String shiftName;
  final bool isWorking;
  final String? startTime;
  final String? endTime;
  final String? breakStartTime;
  final String? breakEndTime;

  factory TodayShiftSchedule.fromJson(Map<String, dynamic> json) =>
      TodayShiftSchedule(
        shiftName: json['shift_name']?.toString() ?? '',
        isWorking: json['is_working'] == true,
        startTime: json['start_time']?.toString(),
        endTime: json['end_time']?.toString(),
        breakStartTime: json['break_start_time']?.toString(),
        breakEndTime: json['break_end_time']?.toString(),
      );

  DateTime? timeOn(DateTime day, String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }
}

class TodaySession {
  const TodaySession(
      {required this.checkInAt, this.checkOutAt, this.source = ''});
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String source;

  factory TodaySession.fromJson(Map<String, dynamic> json) => TodaySession(
        checkInAt: _parseServerTime(json['check_in_at']),
        checkOutAt: _parseServerTime(json['check_out_at']),
        source: json['source']?.toString() ?? '',
      );
}

class AttendanceHistoryPage {
  const AttendanceHistoryPage({
    required this.count,
    required this.page,
    required this.pageSize,
    required this.hasNext,
    required this.results,
  });

  final int count;
  final int page;
  final int pageSize;
  final bool hasNext;
  final List<AttendanceHistoryRecord> results;

  factory AttendanceHistoryPage.fromJson(Map<String, dynamic> json) =>
      AttendanceHistoryPage(
        count: (json['count'] as num?)?.toInt() ?? 0,
        page: (json['page'] as num?)?.toInt() ?? 1,
        pageSize: (json['page_size'] as num?)?.toInt() ?? 31,
        hasNext: json['has_next'] == true,
        results: (json['results'] is List ? json['results'] as List : const [])
            .whereType<Map>()
            .map((item) => AttendanceHistoryRecord.fromJson(
                Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );
}

class AttendanceHistoryRecord {
  const AttendanceHistoryRecord({
    required this.id,
    required this.attendanceDate,
    required this.checkInAt,
    required this.status,
    required this.source,
    this.checkOutAt,
    this.workingSeconds,
    this.branchName = '',
    this.checkInLocationVerified,
    this.checkOutLocationVerified,
    this.checkInPhotoAvailable = false,
    this.checkOutPhotoAvailable = false,
  });

  final int id;
  final DateTime? attendanceDate;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int? workingSeconds;
  final String status;
  final String source;
  final String branchName;
  final bool? checkInLocationVerified;
  final bool? checkOutLocationVerified;
  final bool checkInPhotoAvailable;
  final bool checkOutPhotoAvailable;

  factory AttendanceHistoryRecord.fromJson(Map<String, dynamic> json) {
    final branch = json['branch'];
    return AttendanceHistoryRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      attendanceDate:
          DateTime.tryParse(json['attendance_date']?.toString() ?? ''),
      checkInAt: _parseServerTime(json['check_in_at']),
      checkOutAt: _parseServerTime(json['check_out_at']),
      workingSeconds: (json['working_seconds'] as num?)?.toInt(),
      status: json['status']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      branchName: branch is Map ? (branch['name']?.toString() ?? '') : '',
      checkInLocationVerified: json['check_in_location_verified'] as bool?,
      checkOutLocationVerified: json['check_out_location_verified'] as bool?,
      checkInPhotoAvailable: json['check_in_photo_available'] == true,
      checkOutPhotoAvailable: json['check_out_photo_available'] == true,
    );
  }
}

/// Result of `POST attendance/verify-location/`.
class LocationVerification {
  const LocationVerification({
    required this.verified,
    required this.branchName,
    required this.distanceMeters,
    required this.allowedRadiusMeters,
    this.accuracyMeters,
  });

  final bool verified;
  final String branchName;
  final double distanceMeters;
  final int allowedRadiusMeters;
  final double? accuracyMeters;

  factory LocationVerification.fromJson(Map<String, dynamic> json) {
    final branch = json['branch'];
    return LocationVerification(
      verified: json['verified'] == true,
      branchName: branch is Map ? (branch['name']?.toString() ?? '') : '',
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
      allowedRadiusMeters:
          (json['allowed_radius_meters'] as num?)?.toInt() ?? 0,
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
    );
  }
}

/// Server confirmation of a check-in or check-out.
class AttendanceActionResult {
  const AttendanceActionResult({
    required this.action,
    this.checkInAt,
    this.checkOutAt,
    this.distanceMeters,
    this.locationVerified = true,
  });

  final AttendanceAction action;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final double? distanceMeters;
  final bool locationVerified;

  /// The time the server recorded for this specific action.
  DateTime? get recordedAt =>
      action == AttendanceAction.checkIn ? checkInAt : checkOutAt;

  factory AttendanceActionResult.fromJson(
          AttendanceAction action, Map<String, dynamic> json) =>
      AttendanceActionResult(
        action: action,
        checkInAt: _parseServerTime(json['check_in_at']),
        checkOutAt: _parseServerTime(json['check_out_at']),
        distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
        locationVerified: json['location_verified'] != false,
      );
}

/// A failed attendance request, reduced to what the UI needs.
class AttendanceFailure implements Exception {
  const AttendanceFailure(this.message,
      {this.code, this.isConnectivity = false});

  final String message;

  /// Backend business code, e.g. OUTSIDE_ATTENDANCE_RADIUS or ALREADY_CHECKED_IN.
  final String? code;
  final bool isConnectivity;

  @override
  String toString() => message;
}
