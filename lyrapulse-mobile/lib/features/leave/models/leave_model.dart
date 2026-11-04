
class LeaveModel {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String duration;
  final double totalDays;
  final String reason;
  final String status;
  final DateTime appliedDate;

  LeaveModel({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.totalDays,
    required this.reason,
    required this.status,
    required this.appliedDate,
  });

  LeaveModel copyWith({String? status}) {
    return LeaveModel(
      id: id,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      duration: duration,
      totalDays: totalDays,
      reason: reason,
      status: status ?? this.status,
      appliedDate: appliedDate,
    );
  }

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'].toString(),
      leaveType: json['leaveType'] ?? '',
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      duration: json['duration'] ?? 'Full Day',
      totalDays: (json['totalDays'] as num).toDouble(),
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'Pending',
      appliedDate: DateTime.parse(json['appliedDate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaveType': leaveType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'duration': duration,
      'totalDays': totalDays,
      'reason': reason,
      'status': status,
      'appliedDate': appliedDate.toIso8601String(),
    };
  }
}