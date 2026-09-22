abstract final class Validators {
  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (digits.length != 10 || !RegExp(r'^[6-9]').hasMatch(digits)) {
      return 'Enter a valid 10-digit Indian phone number';
    }
    return null;
  }
}
