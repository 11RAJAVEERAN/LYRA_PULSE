abstract final class Formatters {
  static String phone(String value) => '+91 ${value.trim()}';

  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// 09:28 AM. Returns [placeholder] when the time is unknown.
  static String time12(DateTime? time, {String placeholder = '--:--'}) {
    if (time == null) return placeholder;
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute ${time.hour >= 12 ? 'PM' : 'AM'}';
  }

  /// 01:05:09
  static String durationHms(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// 7h 05m
  static String durationShort(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m';
  }

  /// Sunday, 18 October
  static String dayLabel(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}';

  /// 120 m / 1.4 km
  static String distance(double meters) =>
      meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km' : '${meters.round()} m';
}
