import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/errors/api_exception.dart';
import '../../core/errors/api_response.dart';
import '../../core/network/api_client.dart';
import '../dtos/user_profile_dto.dart';
import '../dtos/product_dto.dart';
import '../dtos/community_post_dto.dart';
import '../repository_interfaces/i_user_repository.dart';

class UserRepositoryImpl implements IUserRepository {
  UserRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  @override
  Future<ApiResponse<UserProfileDto>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return ApiResponse.success(UserProfileDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch current user: $e'));
    }
  }

  @override
  Future<ApiResponse<UserProfileDto>> getUserById(int userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return ApiResponse.success(UserProfileDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch user: $e'));
    }
  }

  @override
  Future<ApiResponse<List<ProductDto>>> getUserProducts({
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
          .map((json) => ProductDto.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(items);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch user products: $e'));
    }
  }

  @override
  Future<ApiResponse<List<ProductDto>>> getUserSavedListings({
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
          .map((json) {
            final item = json as Map<String, dynamic>;
            final nestedProduct = item['Product'];
            if (nestedProduct is Map<String, dynamic>) {
              return nestedProduct;
            }
            return item;
          })
          .map((productJson) => ProductDto.fromJson(productJson))
          .toList();
      return ApiResponse.success(items);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch saved listings: $e'));
    }
  }

  @override
  Future<ApiResponse<List<UserProfileDto>>> getAllUsers({
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
          .map((json) => UserProfileDto.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(items);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch users: $e'));
    }
  }

  @override
  Future<ApiResponse<List<CommunityPostDto>>> getUserSavedPosts({
    required int userId,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/users/$userId/saved/posts',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = response.data as Map<String, dynamic>;
      final posts = (data['posts'] as List)
          .map((json) => CommunityPostDto.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(posts);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch saved posts: $e'));
    }
  }

  @override
  Future<ApiResponse<bool>> followUser(int userId) async {
    return _boolCall(() => _dio.post('/users/$userId/follow'), 'Failed to follow user');
  }

  @override
  Future<ApiResponse<bool>> unfollowUser(int userId) async {
    return _boolCall(() => _dio.delete('/users/$userId/follow'), 'Failed to unfollow user');
  }

  @override
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
      final response = await _dio.put('/users/$userId/cover', data: formData);
      final coverImage = (response.data as Map<String, dynamic>)['cover_image'] as String;
      return ApiResponse.success(coverImage);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to update cover image: $e'));
    }
  }

  @override
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
      final response = await _dio.put('/users/$userId/avatar', data: formData);
      final profileImage = (response.data as Map<String, dynamic>)['profile_image'] as String?;
      if (profileImage == null) {
        return ApiResponse.error(ApiException(message: 'Server did not return profile_image'));
      }
      return ApiResponse.success(profileImage);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to update avatar: $e'));
    }
  }

  @override
  Future<ApiResponse<UserProfileDto>> updateProfile({
    required int userId,
    required String fullName,
    String? bio,
    String? major,
  }) async {
    try {
      final payload = <String, dynamic>{
        'full_name': fullName,
        'bio': bio,
        'major': major,
      };
      final response = await _dio.put('/users/$userId', data: payload);
      return ApiResponse.success(UserProfileDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to update profile: $e'));
    }
  }

  @override
  Future<ApiResponse<void>> reportUser({
    required int userId,
    required String reason,
    String? details,
  }) async {
    try {
      await _dio.post(
        '/users/$userId/reports',
        data: {
          'reason': reason,
          if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
        },
      );
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to report user: $e'));
    }
  }

  @override
  Future<ApiResponse<bool>> blockUser(int userId) async {
    try {
      await _dio.post('/users/$userId/block');
      return ApiResponse.success(true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return ApiResponse.success(true);
      }
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to block user: $e'));
    }
  }

  @override
  Future<ApiResponse<bool>> unblockUser(int userId) async {
    try {
      await _dio.delete('/users/$userId/block');
      return ApiResponse.success(true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return ApiResponse.success(true);
      }
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to unblock user: $e'));
    }
  }

  @override
  Future<ApiResponse<bool>> submitRating({
    required int sellerId,
    required int productId,
    required int rating,
    String? feedback,
  }) async {
    try {
      await _dio.post('/ratings', data: {
        'seller_id': sellerId,
        'product_id': productId,
        'rating': rating,
        if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
      });
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to submit rating: $e'));
    }
  }

  Future<ApiResponse<bool>> _boolCall(
    Future<dynamic> Function() fn,
    String errorMessage,
  ) async {
    try {
      await fn();
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: '$errorMessage: $e'));
    }
  }
}

