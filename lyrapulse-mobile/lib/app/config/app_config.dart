abstract final class AppConfig {
  static const String appName = 'Lyra Pulse';
  static const String companyName = 'LyraTech';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://cz3hhsxq-8001.inc1.devtunnels.ms/api/v1/',
  );
}
