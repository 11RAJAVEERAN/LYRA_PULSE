import '../models/leave_model.dart';

class LeaveService {
  final List<LeaveModel> _leaves = [];

  final Map<String, double> _leaveBalances = {
    'CL': 8,
    'SL': 6,
    'EL': 12,
    'LWP': 0,
  };

  List<LeaveModel> getLeaves() {
    return List.unmodifiable(_leaves);
  }

  Map<String, double> getLeaveBalances() {
    return Map.from(_leaveBalances);
  }

  Future<bool> applyLeave(LeaveModel leave) async {
    _leaves.insert(0, leave);
    return true;
  }

  Future<bool> withdrawLeave(String id) async {
    final index = _leaves.indexWhere((leave) => leave.id == id);

    if (index == -1) return false;

    if (_leaves[index].status != 'Pending') return false;

    _leaves[index] = _leaves[index].copyWith(
      status: 'Withdrawn',
    );

    return true;
  }
}