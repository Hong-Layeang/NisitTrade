class AppConfig {
  const AppConfig._();

  static const String baseUrl = 'http://172.23.3.110:4000';
  static const String fallbackBaseUrl = 'http://localhost:4000';
  static const String apiPrefix = '/api';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static String get apiBaseUrl => '$baseUrl$apiPrefix';
  static String get fallbackApiBaseUrl => '$fallbackBaseUrl$apiPrefix';
}
