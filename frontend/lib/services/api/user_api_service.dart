import 'package:dio/dio.dart';
import 'dart:io';

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

  Future<ApiResponse<UserProfile>> getUserById(int userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      final user = UserProfile.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(user);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch user: $e'),
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

  Future<ApiResponse<List<UserProfile>>> getAllUsers({
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/users',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((json) => UserProfile.fromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse.success(items);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch users: $e'),
      );
    }
  }

  Future<ApiResponse<bool>> followUser(int userId) async {
    try {
      await _dio.post('/users/$userId/follow');
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to follow user: $e'),
      );
    }
  }

  Future<ApiResponse<bool>> unfollowUser(int userId) async {
    try {
      await _dio.delete('/users/$userId/follow');
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to unfollow user: $e'),
      );
    }
  }

  Future<ApiResponse<String>> updateCoverImage({
    required int userId,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'cover': await MultipartFile.fromFile(
          filePath,
          filename: File(filePath).uri.pathSegments.last,
        ),
      });
      final response = await _dio.put(
        '/users/$userId/cover',
        data: formData,
      );
      final coverImage = (response.data as Map<String, dynamic>)['cover_image'] as String;
      return ApiResponse.success(coverImage);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to update cover image: $e'),
      );
    }
  }

  Future<ApiResponse<String>> updateAvatarImage({
    required int userId,
    required String filePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(
          filePath,
          filename: File(filePath).uri.pathSegments.last,
        ),
      });
      final response = await _dio.put(
        '/users/$userId/avatar',
        data: formData,
      );
      final profileImage = (response.data as Map<String, dynamic>)['profile_image'] as String;
      return ApiResponse.success(profileImage);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to update avatar: $e'),
      );
    }
  }
}
