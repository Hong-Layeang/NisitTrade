import 'package:dio/dio.dart';
import 'dart:io';

import '../models/product.dart';
import '../models/user_profile.dart';
import '../models/community_post.dart';
import 'api_client.dart';
import '../../core/errors/api_exception.dart';
import '../../core/errors/api_response.dart';

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
          .map((json) {
            final item = json as Map<String, dynamic>;
            final nestedProduct = item['Product'];
            if (nestedProduct is Map<String, dynamic>) {
              return nestedProduct;
            }
            return item;
          })
          .map((productJson) => Product.fromJson(productJson))
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

  Future<ApiResponse<void>> reportUser({
    required int userId,
    required String reason,
    String? details,
  }) async {
    try {
      await _dio.post(
        '/users/$userId/reports',
        data: <String, dynamic>{
          'reason': reason,
          if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
        },
      );
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to report user: $e'),
      );
    }
  }

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
      return ApiResponse.error(
        ApiException(message: 'Failed to block user: $e'),
      );
    }
  }

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
      return ApiResponse.error(
        ApiException(message: 'Failed to unblock user: $e'),
      );
    }
  }

  Future<ApiResponse<List<CommunityPost>>> getUserSavedPosts({
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
          .map((json) => CommunityPost.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(posts);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch saved posts: $e'),
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
      final profileImage = (response.data as Map<String, dynamic>)['profile_image'] as String?;
      if (profileImage == null) {
        return ApiResponse.error(
          ApiException(message: 'Server did not return profile_image'),
        );
      }
      return ApiResponse.success(profileImage);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to update avatar: $e'),
      );
    }
  }

  Future<ApiResponse<UserProfile>> updateProfile({
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
      final user = UserProfile.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(user);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to update profile: $e'),
      );
    }
  }

  /// Submit a purchase rating for a seller.
  /// Idempotent — returns success even if the buyer already rated this product.
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
      return ApiResponse.error(
        ApiException(message: 'Failed to submit rating: $e'),
      );
    }
  }
}
