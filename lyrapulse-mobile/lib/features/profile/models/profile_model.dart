
class ProfileModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String address;
  final String employeeId;
  final String organization;
  final String designation;
  final String? profileImage;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.address,
    required this.employeeId,
    required this.organization,
    required this.designation,
    this.profileImage,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: '${json['id'] ?? ''}',
      fullName: '${json['full_name'] ?? json['name'] ?? ''}',
      phoneNumber: '${json['phone_number'] ?? json['phone'] ?? ''}',
      address: '${json['address'] ?? ''}',
      employeeId: '${json['employee_id'] ?? ''}',
      organization: '${json['organization'] ?? ''}',
      designation: '${json['designation'] ?? ''}',
      profileImage: json['profile_image']?.toString(),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'address': address,
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? address,
    String? profileImage,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      employeeId: employeeId,
      organization: organization,
      designation: designation,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
