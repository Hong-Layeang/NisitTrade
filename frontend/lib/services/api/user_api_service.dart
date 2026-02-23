import 'package:dio/dio.dart';

import '../../models/product.dart';
import '../../models/user_profile.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'api_response.dart';

class UserApiService {
  UserApiService._();

  static final UserApiService instance = UserApiService._();

  final Dio _dio = ApiClient.instance.dio;

  Future<ApiResponse<UserProfile>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      final user = UserProfile.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(user);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch current user: $e'),
      );
    }
  }

  Future<ApiResponse<List<Product>>> getUserProducts({
    required int userId,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/users/$userId/products',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse.success(items);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch user products: $e'),
      );
    }
  }

  Future<ApiResponse<List<Product>>> getUserSavedListings({
    required int userId,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/users/$userId/saved',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((json) => (json as Map<String, dynamic>)['Product'])
          .where((productJson) => productJson != null)
          .map((productJson) =>
              Product.fromJson(productJson as Map<String, dynamic>))
          .toList();

      return ApiResponse.success(items);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch saved listings: $e'),
      );
    }
  }
}
