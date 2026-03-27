import '../../core/errors/api_response.dart';
import '../repository_interfaces/i_product_comment_repository.dart';
import 'product_repository_impl.dart';

class ProductCommentRepositoryImpl implements IProductCommentRepository {
  ProductCommentRepositoryImpl({ProductRepositoryImpl? repository})
      : _repository = repository ?? ProductRepositoryImpl();

  final ProductRepositoryImpl _repository;

  @override
  Future<ApiResponse<void>> addComment({
    required int productId,
    required String content,
    int? rating,
  }) async {
    return _repository.addComment(
      productId: productId,
      content: content,
      rating: rating,
    );
  }

  @override
  Future<ApiResponse<void>> updateComment({
    required int productId,
    required int commentId,
    required String content,
    int? rating,
  }) async {
    return _repository.updateComment(
      productId: productId,
      commentId: commentId,
      content: content,
      rating: rating,
    );
  }

  @override
  Future<ApiResponse<void>> deleteComment({
    required int productId,
    required int commentId,
  }) async {
    return _repository.deleteComment(
      productId: productId,
      commentId: commentId,
    );
  }
}
