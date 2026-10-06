import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../data/models/employee_model.dart';

class ProfileContent extends StatelessWidget {
  const ProfileContent({required this.employee, super.key});

  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    final photoUrl = employee.profilePhoto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primary.withValues(alpha: .12),
                  backgroundImage: photoUrl == null || photoUrl.isEmpty
                      ? null
                      : NetworkImage(photoUrl),
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Text(
                          employee.name.isEmpty
                              ? 'E'
                              : employee.name.substring(0, 1).toUpperCase(),
                          style: AppTextStyles.title.copyWith(color: AppColors.primary),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name, style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text('Employee ID: ${employee.employeeCode}', style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _ProfileField(label: 'Mobile number', value: employee.phoneNumber),
              _ProfileField(label: 'Email', value: employee.email),
              _ProfileField(label: 'Address', value: employee.address),
              _ProfileField(label: 'Branch', value: employee.branch ?? ''),
              _ProfileField(label: 'Department', value: employee.department ?? ''),
              _ProfileField(label: 'Designation', value: employee.designation ?? ''),
              _ProfileField(label: 'Joining date', value: _formatDate(employee.joiningDate)),
              _ProfileField(label: 'Date of birth', value: _formatDate(employee.dateOfBirth)),
              _ProfileField(label: 'Gender', value: employee.gender),
              _ProfileField(label: 'Emergency contact', value: employee.emergencyContact, last: true),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        ListTile(
          title: Text(label, style: AppTextStyles.bodySmall),
          subtitle: Text(value, style: AppTextStyles.body),
          dense: true,
        ),
        if (!last) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}