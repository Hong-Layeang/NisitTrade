import '../models/community_post.dart';
import 'api_client.dart';
import 'base_api_service.dart';
import '../../core/errors/api_response.dart';
import 'package:dio/dio.dart';

class CommunityApiService extends BaseApiService {
  CommunityApiService._() : super(ApiClient.instance.dio);

  static final CommunityApiService instance = CommunityApiService._();

  Future<ApiResponse<List<CommunityPost>>> getPosts({
    String feed = 'community',
    int limit = 20,
    int offset = 0,
  }) async {
    return executeListApiCall<CommunityPost>(
      call: () => dio.get(
        '/community',
        queryParameters: {'feed': feed, 'limit': limit, 'offset': offset},
      ),
      itemParser: (json) => CommunityPost.fromJson(json as Map<String, dynamic>),
      errorMessage: 'Failed to fetch community posts',
    );
  }

  Future<ApiResponse<CommunityPost>> createPost({
    required String content,
    List<String> imagePaths = const [],
  }) async {
    final formData = FormData.fromMap({
      'content': content,
    });

    for (final imagePath in imagePaths) {
      formData.files.add(
        MapEntry('images', await MultipartFile.fromFile(imagePath)),
      );
    }

    return executeApiCall<CommunityPost>(
      call: () => dio.post(
        '/community',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
      parser: (data) => CommunityPost.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to create community post',
    );
  }

  Future<ApiResponse<CommunityPost>> getPost(int postId) {
    return executeApiCall<CommunityPost>(
      call: () => dio.get('/community/$postId'),
      parser: (data) => CommunityPost.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to fetch community post detail',
    );
  }

  Future<ApiResponse<void>> likePost(int postId) {
    return executeVoidApiCall(
      call: () => dio.post('/community/$postId/likes'),
      errorMessage: 'Failed to like community post',
    );
  }

  Future<ApiResponse<void>> unlikePost(int postId) {
    return executeVoidApiCall(
      call: () => dio.delete('/community/$postId/likes'),
      errorMessage: 'Failed to unlike community post',
    );
  }

  Future<ApiResponse<void>> addComment({
    required int postId,
    required String content,
  }) {
    return executeVoidApiCall(
      call: () => dio.post('/community/$postId/comments', data: {'content': content}),
      errorMessage: 'Failed to add community comment',
    );
  }

  Future<ApiResponse<void>> updateComment({
    required int postId,
    required int commentId,
    required String content,
  }) {
    return executeVoidApiCall(
      call: () => dio.put('/community/$postId/comments/$commentId', data: {'content': content}),
      errorMessage: 'Failed to update community comment',
    );
  }

  Future<ApiResponse<void>> deleteComment({
    required int postId,
    required int commentId,
  }) {
    return executeVoidApiCall(
      call: () => dio.delete('/community/$postId/comments/$commentId'),
      errorMessage: 'Failed to delete community comment',
    );
  }
}
