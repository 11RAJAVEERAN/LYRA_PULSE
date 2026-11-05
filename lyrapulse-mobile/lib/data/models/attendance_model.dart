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
  });

  final AttendanceState state;
  final DateTime? attendanceDate;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final List<TodaySession> sessions;

  factory TodayAttendance.fromJson(Map<String, dynamic> json) => TodayAttendance(
        state: AttendanceState.parse(json['state']),
        attendanceDate: DateTime.tryParse(json['attendance_date']?.toString() ?? ''),
        checkInAt: _parseServerTime(json['check_in_at']),
        checkOutAt: _parseServerTime(json['check_out_at']),
        sessions: (json['sessions'] is List ? json['sessions'] as List : const [])
            .whereType<Map>()
            .map((item) => TodaySession.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );
}

class TodaySession {
  const TodaySession({required this.checkInAt, this.checkOutAt, this.source = ''});
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final String source;

  factory TodaySession.fromJson(Map<String, dynamic> json) => TodaySession(
        checkInAt: _parseServerTime(json['check_in_at']),
        checkOutAt: _parseServerTime(json['check_out_at']),
        source: json['source']?.toString() ?? '',
      );
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
      allowedRadiusMeters: (json['allowed_radius_meters'] as num?)?.toInt() ?? 0,
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
  DateTime? get recordedAt => action == AttendanceAction.checkIn ? checkInAt : checkOutAt;

  factory AttendanceActionResult.fromJson(AttendanceAction action, Map<String, dynamic> json) =>
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
  const AttendanceFailure(this.message, {this.code, this.isConnectivity = false});

  final String message;

  /// Backend business code, e.g. OUTSIDE_ATTENDANCE_RADIUS or ALREADY_CHECKED_IN.
  final String? code;
  final bool isConnectivity;

  @override
  String toString() => message;
}
