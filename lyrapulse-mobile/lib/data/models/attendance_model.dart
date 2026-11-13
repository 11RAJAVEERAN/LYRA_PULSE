/// Backend attendance state for the current day (`GET attendance/today/`).
enum AttendanceState {
  notCheckedIn,
  checkedIn,
  onBreak,
  checkedOut;

  bool get allowsCheckIn =>
      this == AttendanceState.notCheckedIn || this == AttendanceState.onBreak;

  bool get allowsCheckOut => this == AttendanceState.checkedIn;

  /// A completed-looking state is reloaded before treating it as final.
  bool get mayNeedCheckInRefresh => this == AttendanceState.checkedOut;

  static AttendanceState parse(Object? value) {
    switch (value?.toString()) {
      case 'CHECKED_IN':
        return AttendanceState.checkedIn;
      case 'ON_BREAK':
        return AttendanceState.onBreak;
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
      );
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
