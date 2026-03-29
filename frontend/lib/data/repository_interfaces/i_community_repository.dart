import '../../core/errors/api_response.dart';
import '../../data/dtos/community_post_dto.dart';

abstract class ICommunityRepository {
  Future<ApiResponse<List<CommunityPostDto>>> getPosts({
    String feed,
    int limit,
    int offset,
    int? userId,
  });
  Future<ApiResponse<CommunityPostDto>> createPost({
    required String content,
    List<String> imagePaths,
  });
  Future<ApiResponse<CommunityPostDto>> getPost(int postId);
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
  Future<ApiResponse<void>> hidePostForViewer(int postId);
  Future<ApiResponse<void>> unhidePostForViewer(int postId);
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

