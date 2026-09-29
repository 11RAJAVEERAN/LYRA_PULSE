class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.phoneNumber,
    this.email = '',
    this.branch,
    this.department,
    this.designation,
    this.isActive = true,
  });

  final int id;
  final String employeeCode;
  final String name;
  final String phoneNumber;
  final String email;
  final String? branch;
  final String? department;
  final String? designation;
  final bool isActive;

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    String? relationName(dynamic value) {
      if (value is Map<String, dynamic>) return value['name']?.toString();
      return value?.toString();
    }

    return EmployeeModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      employeeCode: json['employee_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      branch: relationName(json['branch']),
      department: relationName(json['department']),
      designation: relationName(json['designation']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
