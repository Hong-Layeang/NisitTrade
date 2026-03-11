import '../models/community_post.dart';
import '../../core/errors/api_response.dart';
import '../providers/community_api_service.dart';

abstract class CommunityRepository {
  Future<ApiResponse<List<CommunityPost>>> getPosts({
    String feed,
    int limit,
    int offset,
    int? userId,
  });
  Future<ApiResponse<CommunityPost>> createPost({
    required String content,
    List<String> imagePaths,
  });
  Future<ApiResponse<CommunityPost>> getPost(int postId);
  Future<ApiResponse<void>> likePost(int postId);
  Future<ApiResponse<void>> unlikePost(int postId);
  Future<ApiResponse<void>> savePost(int postId);
  Future<ApiResponse<void>> unsavePost(int postId);
  Future<ApiResponse<void>> updatePost({
    required int postId,
    required String content,
    List<String> imagePaths,
    List<String> retainedImageUrls,
  });
  Future<ApiResponse<void>> deletePost(int postId);
  Future<ApiResponse<void>> reportPost({
    required int postId,
    required String reason,
    String? details,
  });
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
    int? userId,
  }) {
    return _apiService.getPosts(
      feed: feed,
      limit: limit,
      offset: offset,
      userId: userId,
    );
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
  Future<ApiResponse<void>> savePost(int postId) {
    return _apiService.savePost(postId);
  }

  @override
  Future<ApiResponse<void>> unsavePost(int postId) {
    return _apiService.unsavePost(postId);
  }

  @override
  Future<ApiResponse<void>> updatePost({
    required int postId,
    required String content,
    List<String> imagePaths = const [],
    List<String> retainedImageUrls = const [],
  }) {
    return _apiService.updatePost(
      postId: postId,
      content: content,
      imagePaths: imagePaths,
      retainedImageUrls: retainedImageUrls,
    );
  }

  @override
  Future<ApiResponse<void>> deletePost(int postId) {
    return _apiService.deletePost(postId);
  }

  @override
  Future<ApiResponse<void>> reportPost({
    required int postId,
    required String reason,
    String? details,
  }) {
    return _apiService.reportPost(postId: postId, reason: reason, details: details);
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
