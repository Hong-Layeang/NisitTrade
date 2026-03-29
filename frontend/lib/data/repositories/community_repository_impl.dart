import 'package:dio/dio.dart';

import '../../core/errors/api_exception.dart';
import '../../core/errors/api_response.dart';
import '../../core/network/api_client.dart';
import '../dtos/community_post_dto.dart';
import '../repository_interfaces/i_community_repository.dart';

class CommunityRepositoryImpl implements ICommunityRepository {
  CommunityRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  @override
  Future<ApiResponse<List<CommunityPostDto>>> getPosts({
    String feed = 'community',
    int limit = 20,
    int offset = 0,
    int? userId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'feed': feed,
        'limit': limit,
        'offset': offset,
      };
      if (userId != null) {
        queryParameters['user_id'] = userId;
      }

      final response = await _dio.get(
        '/community',
        queryParameters: queryParameters,
      );
      final items = (response.data as List)
          .map((json) => CommunityPostDto.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(items);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch community posts: $e'));
    }
  }

  @override
  Future<ApiResponse<CommunityPostDto>> createPost({
    required String content,
    List<String> imagePaths = const [],
  }) async {
    try {
      final formData = FormData.fromMap({'content': content});
      for (final imagePath in imagePaths) {
        formData.files.add(MapEntry('images', await MultipartFile.fromFile(imagePath)));
      }
      final response = await _dio.post(
        '/community',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponse.success(
        CommunityPostDto.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to create community post: $e'));
    }
  }

  @override
  Future<ApiResponse<CommunityPostDto>> getPost(int postId) async {
    try {
      final response = await _dio.get('/community/$postId');
      return ApiResponse.success(
        CommunityPostDto.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch community post detail: $e'));
    }
  }

  @override
  Future<ApiResponse<void>> likePost(int postId) {
    return _voidCall(() => _dio.post('/community/$postId/likes'), 'Failed to like community post');
  }

  @override
  Future<ApiResponse<void>> unlikePost(int postId) {
    return _voidCall(() => _dio.delete('/community/$postId/likes'), 'Failed to unlike community post');
  }

  @override
  Future<ApiResponse<void>> savePost(int postId) {
    return _voidCall(() => _dio.post('/community/$postId/saves'), 'Failed to save community post');
  }

  @override
  Future<ApiResponse<void>> unsavePost(int postId) {
    return _voidCall(() => _dio.delete('/community/$postId/saves'), 'Failed to unsave community post');
  }

  @override
  Future<ApiResponse<void>> updatePost({
    required int postId,
    required String content,
    List<String> imagePaths = const [],
    List<String> retainedImageUrls = const [],
  }) async {
    try {
      final formData = FormData.fromMap({'content': content, 'image_urls': retainedImageUrls});
      for (final imagePath in imagePaths) {
        formData.files.add(MapEntry('images', MultipartFile.fromFileSync(imagePath)));
      }
      await _dio.put(
        '/community/$postId',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to update community post: $e'));
    }
  }

  @override
  Future<ApiResponse<void>> deletePost(int postId) {
    return _voidCall(() => _dio.delete('/community/$postId'), 'Failed to delete community post');
  }

  @override
  Future<ApiResponse<void>> reportPost({
    required int postId,
    required String reason,
    String? details,
  }) {
    return _voidCall(
      () => _dio.post(
        '/community/$postId/reports',
        data: {
          'reason': reason,
          if (details != null && details.trim().isNotEmpty) 'details': details.trim(),
        },
      ),
      'Failed to report community post',
    );
  }

  @override
  Future<ApiResponse<void>> hidePostForViewer(int postId) {
    return _voidCall(
      () => _dio.patch('/community/$postId/hide-for-me'),
      'Failed to hide community post for viewer',
    );
  }

  @override
  Future<ApiResponse<void>> unhidePostForViewer(int postId) {
    return _voidCall(
      () => _dio.patch('/community/$postId/unhide-for-me'),
      'Failed to unhide community post for viewer',
    );
  }

  @override
  Future<ApiResponse<void>> addComment({
    required int postId,
    required String content,
  }) {
    return _voidCall(
      () => _dio.post('/community/$postId/comments', data: {'content': content}),
      'Failed to add community comment',
    );
  }

  @override
  Future<ApiResponse<void>> updateComment({
    required int postId,
    required int commentId,
    required String content,
  }) {
    return _voidCall(
      () => _dio.put('/community/$postId/comments/$commentId', data: {'content': content}),
      'Failed to update community comment',
    );
  }

  @override
  Future<ApiResponse<void>> deleteComment({
    required int postId,
    required int commentId,
  }) {
    return _voidCall(
      () => _dio.delete('/community/$postId/comments/$commentId'),
      'Failed to delete community comment',
    );
  }

  Future<ApiResponse<void>> _voidCall(
    Future<dynamic> Function() fn,
    String errorMessage,
  ) async {
    try {
      await fn();
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: '$errorMessage: $e'));
    }
  }
}

