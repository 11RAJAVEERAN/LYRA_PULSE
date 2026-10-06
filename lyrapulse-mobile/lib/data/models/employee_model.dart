
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
    this.joiningDate,
    this.address = '',
    this.dateOfBirth,
    this.gender = '',
    this.emergencyContact = '',
    this.profilePhoto,
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
  final DateTime? joiningDate;
  final String address;
  final DateTime? dateOfBirth;
  final String gender;
  final String emergencyContact;
  final String? profilePhoto;
  final bool isActive;

  factory EmployeeModel.fromJson(Map<String, dynamic> json, {String emailFallback = ''}) {
    String? relationName(dynamic value) {
      if (value is Map<String, dynamic>) return value['name']?.toString();
      return value?.toString();
    }

    return EmployeeModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      employeeCode: json['employee_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      // /mobile/me/ currently omits email; /auth/me/ includes the same User.email.
      // Keep the employee profile endpoint as the source for all employee fields.
      joiningDate: DateTime.tryParse(json['joining_date']?.toString() ?? ''),
      address: json['address']?.toString() ?? '',
      dateOfBirth: DateTime.tryParse(json['date_of_birth']?.toString() ?? ''),
      gender: json['gender']?.toString() ?? '',
      emergencyContact: json['emergency_contact']?.toString() ?? '',
      profilePhoto: json['profile_photo']?.toString(),
      email: (json['email']?.toString().isNotEmpty ?? false)
          ? json['email'].toString()
          : emailFallback,
      branch: relationName(json['branch']),
      department: relationName(json['department']),
      designation: relationName(json['designation']),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}