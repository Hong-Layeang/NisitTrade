class AppConfig {
  const AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:4000',
  );
  static const String fallbackBaseUrl = String.fromEnvironment(
    'FALLBACK_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );
  // static const String fallbackBaseUrl = String.fromEnvironment(
  //   'FALLBACK_BASE_URL',
  //   defaultValue: 'http://172.17.96.163:4000',
  // );
  static const String apiPrefix = '/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static String get apiBaseUrl => '$baseUrl$apiPrefix';
  static String get fallbackApiBaseUrl => '$fallbackBaseUrl$apiPrefix';
}
