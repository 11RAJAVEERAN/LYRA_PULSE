abstract final class AppConfig {
  static const String appName = 'Lyra Pulse';
  static const String companyName = 'LyraTech';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
}
