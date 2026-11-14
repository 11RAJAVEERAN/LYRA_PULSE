import 'package:get/get.dart';

import '../../../data/providers/api_provider.dart';
import '../../auth/controllers/auth_controller.dart';

/// Loads the authenticated employee's assignment through the existing mobile
/// API. This endpoint returns the current assignment, not a dated future list.
class UpcomingShiftsController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final assignment = Rxn<Map<String, dynamic>>();

  final _apiProvider = Get.find<ApiProvider>();
  final _authController = Get.find<AuthController>();

  @override
  void onInit() {
    super.onInit();
    loadAssignment();
  }

  Future<void> loadAssignment() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final response = await _apiProvider.getCurrentEmployeeShiftAssignment();
      final body = _asMap(response.data);
      if (body['success'] == false) {
        throw FormatException(body['message']?.toString() ?? 'Unable to load shift assignment.');
      }
      final data = _asMap(body['data']);
      assignment.value = data.isEmpty ? null : data;
    } catch (error) {
      errorMessage.value = _authController.errorMessage(error);
    } finally {
      isLoading.value = false;
    }
  }

  String? get shiftName => assignment.value?['shift'] is Map
      ? _asMap(assignment.value?['shift'])['name']?.toString()
      : null;

  String get branchName {
    final name = _authController.employee.value?.branch?.trim();
    if (name != null && name.isNotEmpty) return name;
    final branchId = assignment.value?['branch_id'];
    return branchId == null ? 'Not available' : 'Branch $branchId';
  }

  String get effectivePeriod {
    final from = _formatDate(assignment.value?['effective_from']);
    final to = _formatDate(assignment.value?['effective_to']);
    if (from == null) return 'Not available';
    return to == null ? 'From $from' : '$from – $to';
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  static String? _formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return null;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
