import '../../core/errors/api_response.dart';
import '../../domain/repository_interfaces/i_product_comment_repository.dart';
import '../providers/product_api_service.dart';

/// Implementation of IProductCommentRepository
/// Handles product comment operations
class ProductCommentRepositoryImpl implements IProductCommentRepository {
  ProductCommentRepositoryImpl({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService.instance;

  final ProductApiService _apiService;

  @override
  Future<ApiResponse<void>> addComment({
    required int productId,
    required String content,
    int? rating,
  }) async {
    return _apiService.addComment(
      productId: productId,
      content: content,
      rating: rating,
    );
  }

  @override
  Future<ApiResponse<void>> deleteComment({
    required int productId,
    required int commentId,
  }) async {
    return _apiService.deleteComment(
      productId: productId,
      commentId: commentId,
    );
  }
}
