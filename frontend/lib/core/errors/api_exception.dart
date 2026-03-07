import 'package:dio/dio.dart';

/// Custom exception for API errors with structured error information
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final ApiErrorType type;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
    this.type = ApiErrorType.unknown,
  });

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          type: ApiErrorType.timeout,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        
        String message = 'An error occurred';
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          message = data['message'] as String;
        } else if (data is Map<String, dynamic> && data.containsKey('error')) {
          message = data['error'] as String;
        }

        return ApiException(
          message: message,
          statusCode: statusCode,
          data: data,
          type: _getErrorTypeFromStatusCode(statusCode),
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled',
          type: ApiErrorType.cancelled,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection. Please check your network.',
          type: ApiErrorType.network,
        );

      default:
        return ApiException(
          message: error.message ?? 'An unexpected error occurred',
          type: ApiErrorType.unknown,
        );
    }
  }

  static ApiErrorType _getErrorTypeFromStatusCode(int? statusCode) {
    if (statusCode == null) return ApiErrorType.unknown;
    
    if (statusCode >= 400 && statusCode < 500) {
      if (statusCode == 401) return ApiErrorType.unauthorized;
      if (statusCode == 403) return ApiErrorType.forbidden;
      if (statusCode == 404) return ApiErrorType.notFound;
      if (statusCode == 422) return ApiErrorType.validation;
      return ApiErrorType.client;
    }
    
    if (statusCode >= 500) {
      return ApiErrorType.server;
    }
    
    return ApiErrorType.unknown;
  }

  @override
  String toString() => message;
}

enum ApiErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  client,
  server,
  cancelled,
  unknown,
}
