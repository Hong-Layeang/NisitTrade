class AppConfig {
  const AppConfig._();

  static const String baseUrl = 'http://10.250.151.163:4000';
  static const String fallbackBaseUrl = 'http://127.0.0.1:4000';
  static const String apiPrefix = '/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static String get apiBaseUrl => '$baseUrl$apiPrefix';
  static String get fallbackApiBaseUrl => '$fallbackBaseUrl$apiPrefix';
}
