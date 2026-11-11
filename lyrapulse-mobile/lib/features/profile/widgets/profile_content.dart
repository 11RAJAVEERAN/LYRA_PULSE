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
                _EmployeePhoto(name: employee.name, url: photoUrl),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(employee.name, style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text('Employee ID: ${employee.employeeCode}',
                          style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ProfileSection(
          title: 'Contact information',
          icon: Icons.contact_phone_outlined,
          fields: [
            _ProfileField(label: 'Mobile number', value: employee.phoneNumber),
            _ProfileField(label: 'Email', value: employee.email),
            _ProfileField(label: 'Address', value: employee.address),
            _ProfileField(
              label: 'Emergency contact',
              value: employee.emergencyContact,
              last: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileSection(
          title: 'Employment details',
          icon: Icons.work_outline_rounded,
          fields: [
            _ProfileField(label: 'Branch', value: employee.branch ?? ''),
            _ProfileField(
                label: 'Department', value: employee.department ?? ''),
            _ProfileField(
                label: 'Designation', value: employee.designation ?? ''),
            _ProfileField(
              label: 'Joining date',
              value: _formatDate(employee.joiningDate),
            ),
            _ProfileField(
              label: 'Date of birth',
              value: _formatDate(employee.dateOfBirth),
            ),
            _ProfileField(label: 'Gender', value: employee.gender, last: true),
          ],
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

class _EmployeePhoto extends StatelessWidget {
  const _EmployeePhoto({required this.name, required this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? 'E' : name.substring(0, 1).toUpperCase();
    final fallback = CircleAvatar(
      radius: 34,
      backgroundColor: AppColors.primary.withValues(alpha: .12),
      child: Text(
        initial,
        style: AppTextStyles.title.copyWith(color: AppColors.primary),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url!,
        width: 68,
        height: 68,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.fields,
  });

  final String title;
  final IconData icon;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(icon, size: 19, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text(title, style: AppTextStyles.label),
                ],
              ),
            ),
            ...fields,
          ],
        ),
      );
}

class _ProfileField extends StatelessWidget {
  const _ProfileField(
      {required this.label, required this.value, this.last = false});

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
