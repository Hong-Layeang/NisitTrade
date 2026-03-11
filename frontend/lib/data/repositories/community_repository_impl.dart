import '../models/community_post.dart';
import '../../core/errors/api_response.dart';
import '../providers/community_api_service.dart';

abstract class CommunityRepository {
  Future<ApiResponse<List<CommunityPost>>> getPosts({
    String feed,
    int limit,
    int offset,
  });
  Future<ApiResponse<CommunityPost>> createPost({
    required String content,
    List<String> imagePaths,
  });
  Future<ApiResponse<CommunityPost>> getPost(int postId);
  Future<ApiResponse<void>> likePost(int postId);
  Future<ApiResponse<void>> unlikePost(int postId);
  Future<ApiResponse<void>> addComment({
    required int postId,
    required String content,
  });
  Future<ApiResponse<void>> updateComment({
    required int postId,
    required int commentId,
    required String content,
  });
  Future<ApiResponse<void>> deleteComment({
    required int postId,
    required int commentId,
  });
}

class CommunityRepositoryImpl implements CommunityRepository {
  CommunityRepositoryImpl({CommunityApiService? apiService})
      : _apiService = apiService ?? CommunityApiService.instance;

  final CommunityApiService _apiService;

  @override
  Future<ApiResponse<List<CommunityPost>>> getPosts({
    String feed = 'community',
    int limit = 20,
    int offset = 0,
  }) {
    return _apiService.getPosts(feed: feed, limit: limit, offset: offset);
  }

  @override
  Future<ApiResponse<CommunityPost>> createPost({
    required String content,
    List<String> imagePaths = const [],
  }) {
    return _apiService.createPost(content: content, imagePaths: imagePaths);
  }

  @override
  Future<ApiResponse<CommunityPost>> getPost(int postId) {
    return _apiService.getPost(postId);
  }

  @override
  Future<ApiResponse<void>> likePost(int postId) {
    return _apiService.likePost(postId);
  }

  @override
  Future<ApiResponse<void>> unlikePost(int postId) {
    return _apiService.unlikePost(postId);
  }

  @override
  Future<ApiResponse<void>> addComment({
    required int postId,
    required String content,
  }) {
    return _apiService.addComment(postId: postId, content: content);
  }

  @override
  Future<ApiResponse<void>> updateComment({
    required int postId,
    required int commentId,
    required String content,
  }) {
    return _apiService.updateComment(
      postId: postId,
      commentId: commentId,
      content: content,
    );
  }

  @override
  Future<ApiResponse<void>> deleteComment({
    required int postId,
    required int commentId,
  }) {
    return _apiService.deleteComment(postId: postId, commentId: commentId);
  }
}
