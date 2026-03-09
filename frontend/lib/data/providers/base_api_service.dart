import 'package:dio/dio.dart';
import '../../core/errors/api_exception.dart';
import '../../core/errors/api_response.dart';

/// Base class for all API services to reduce error handling duplication.
/// Provides common patterns for API calls with consistent error handling.
abstract class BaseApiService {
  final Dio dio;

  BaseApiService(this.dio);

  /// Wraps an API call with standardized error handling.
  /// 
  /// [call] - The Dio HTTP operation to execute
  /// [parser] - Function to parse the response data into the expected type
  /// [errorMessage] - Optional custom error message prefix
  Future<ApiResponse<T>> executeApiCall<T>({
    required Future<Response> Function() call,
    required T Function(dynamic data) parser,
    String? errorMessage,
  }) async {
    try {
      final response = await call();
      final parsedData = parser(response.data);
      return ApiResponse.success(parsedData);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      final message = errorMessage != null 
          ? '$errorMessage: $e' 
          : 'API call failed: $e';
      return ApiResponse.error(ApiException(message: message));
    }
  }

  /// Wraps an API call that returns a list with standardized error handling.
  /// 
  /// [call] - The Dio HTTP operation to execute
  /// [itemParser] - Function to parse individual items in the list
  /// [errorMessage] - Optional custom error message prefix
  Future<ApiResponse<List<T>>> executeListApiCall<T>({
    required Future<Response> Function() call,
    required T Function(dynamic item) itemParser,
    String? errorMessage,
  }) async {
    return executeApiCall<List<T>>(
      call: call,
      parser: (data) {
        if (data is! List) {
          throw FormatException('Expected list response, got ${data.runtimeType}');
        }
        return data.map((item) => itemParser(item)).toList();
      },
      errorMessage: errorMessage,
    );
  }

  /// Wraps an API call that may return null with standardized error handling.
  /// 
  /// [call] - The Dio HTTP operation to execute
  /// [parser] - Function to parse the response data into the expected type
  /// [errorMessage] - Optional custom error message prefix
  Future<ApiResponse<T?>> executeNullableApiCall<T>({
    required Future<Response> Function() call,
    required T? Function(dynamic data) parser,
    String? errorMessage,
  }) async {
    try {
      final response = await call();
      
      // Handle null or empty responses
      if (response.data == null) {
        return ApiResponse.success(null);
      }
      
      final parsedData = parser(response.data);
      return ApiResponse.success(parsedData);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      final message = errorMessage != null 
          ? '$errorMessage: $e' 
          : 'API call failed: $e';
      return ApiResponse.error(ApiException(message: message));
    }
  }

  /// Wraps a DELETE or similar operation that returns no data.
  /// 
  /// [call] - The Dio HTTP operation to execute
  /// [errorMessage] - Optional custom error message prefix
  Future<ApiResponse<void>> executeVoidApiCall({
    required Future<Response> Function() call,
    String? errorMessage,
  }) async {
    try {
      await call();
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      final message = errorMessage != null 
          ? '$errorMessage: $e' 
          : 'API call failed: $e';
      return ApiResponse.error(ApiException(message: message));
    }
  }
}
