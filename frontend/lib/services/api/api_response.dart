import 'api_exception.dart';

/// Generic response wrapper for API calls
/// Provides a consistent way to handle success and error states
class ApiResponse<T> {
  final T? data;
  final ApiException? error;
  final bool isSuccess;

  ApiResponse._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Create a successful response
  factory ApiResponse.success(T data) {
    return ApiResponse._(
      data: data,
      isSuccess: true,
    );
  }

  /// Create an error response
  factory ApiResponse.error(ApiException error) {
    return ApiResponse._(
      error: error,
      isSuccess: false,
    );
  }

  /// Check if the response is an error
  bool get isError => !isSuccess;

  /// Get data or throw error if it doesn't exist
  T get dataOrThrow {
    if (data != null) return data as T;
    throw error ?? ApiException(message: 'No data available');
  }

  /// Transform the data if successful
  ApiResponse<R> map<R>(R Function(T data) transform) {
    if (isSuccess && data != null) {
      try {
        return ApiResponse.success(transform(data as T));
      } catch (e) {
        return ApiResponse.error(
          ApiException(message: 'Data transformation failed: $e'),
        );
      }
    }
    return ApiResponse.error(error ?? ApiException(message: 'No data to transform'));
  }

  /// Execute callback based on success or error
  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) error,
  }) {
    if (isSuccess && data != null) {
      return success(data as T);
    }
    return error(this.error ?? ApiException(message: 'Unknown error'));
  }
}
