import '../../core/errors/api_response.dart';

/// Repository interface for managing product comments
abstract class IProductCommentRepository {
  Future<ApiResponse<void>> addComment({
    required int productId,
    required String content,
    int? rating,
  });
  
  Future<ApiResponse<void>> updateComment({
    required int productId,
    required int commentId,
    required String content,
    int? rating,
  });
  
  Future<ApiResponse<void>> deleteComment({
    required int productId,
    required int commentId,
  });
}
