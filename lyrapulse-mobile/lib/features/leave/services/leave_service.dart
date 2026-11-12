import '../models/leave_model.dart';

class LeaveService {
  final List<LeaveModel> _leaves = [];
  final Map<String, double> _leaveBalances = {};

  List<LeaveModel> getLeaves() {
    return List.unmodifiable(_leaves);
  }

  Map<String, double> getLeaveBalances() {
    return Map.from(_leaveBalances);
  }

  Future<bool> applyLeave(LeaveModel leave) async {
    return false;
  }

  Future<bool> withdrawLeave(String id) async {
    return false;
  }
}
