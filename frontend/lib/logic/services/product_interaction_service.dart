import '../../data/dtos/product_dto.dart';
import '../../data/repository_interfaces/i_product_comment_repository.dart';
import '../../data/repository_interfaces/i_product_like_repository.dart';
import '../../data/repository_interfaces/i_product_report_repository.dart';
import '../../data/repository_interfaces/i_product_repository.dart';
import '../../data/repository_interfaces/i_product_save_repository.dart';

/// Encapsulates product interaction operations (likes, comments, saves, reports).
class ProductInteractionService {
  ProductInteractionService({
    required IProductRepository productRepository,
    required IProductLikeRepository likeRepository,
    required IProductSaveRepository saveRepository,
    required IProductCommentRepository commentRepository,
    required IProductReportRepository reportRepository,
  })  : _productRepository = productRepository,
        _likeRepository = likeRepository,
        _saveRepository = saveRepository,
        _commentRepository = commentRepository,
        _reportRepository = reportRepository;

  final IProductRepository _productRepository;
  final IProductLikeRepository _likeRepository;
  final IProductSaveRepository _saveRepository;
  final IProductCommentRepository _commentRepository;
  final IProductReportRepository _reportRepository;

  Future<ProductDto?> refreshProduct(int productId) async {
    final response = await _productRepository.getProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
    return response.data;
  }

  Future<ProductDto?> likeProduct(int productId) async {
    final response = await _likeRepository.likeProduct(productId);
    if (!response.isSuccess) {
      final message = response.error?.message.toLowerCase() ?? '';
      // Treat duplicate-like as idempotent success and sync latest state.
      if (message.contains('already liked')) {
        return refreshProduct(productId);
      }
      throw response.error!;
    }
    return refreshProduct(productId);
  }

  Future<ProductDto?> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    final response = await _likeRepository.unlikeProduct(
      productId: productId,
      likeId: likeId,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }
    return refreshProduct(productId);
  }

  Future<ProductDto?> addComment({
    required int productId,
    required String content,
  }) async {
    final response = await _commentRepository.addComment(
      productId: productId,
      content: content,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }
    return refreshProduct(productId);
  }

  Future<ProductDto?> updateComment({
    required int productId,
    required int commentId,
    required String content,
  }) async {
    final response = await _commentRepository.updateComment(
      productId: productId,
      commentId: commentId,
      content: content,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }
    return refreshProduct(productId);
  }

  Future<ProductDto?> deleteComment({
    required int productId,
    required int commentId,
  }) async {
    final response = await _commentRepository.deleteComment(
      productId: productId,
      commentId: commentId,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }
    return refreshProduct(productId);
  }

  Future<ProductDto?> hideProduct(int productId) async {
    final response = await _productRepository.hideProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
    return response.data;
  }

  Future<ProductDto?> unhideProduct(int productId) async {
    final response = await _productRepository.unhideProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
    return response.data;
  }

  Future<void> hideProductForViewer(int productId) async {
    final response = await _productRepository.hideProductForViewer(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
  }

  Future<void> unhideProductForViewer(int productId) async {
    final response = await _productRepository.unhideProductForViewer(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
  }

  Future<void> saveListing(int productId) async {
    final response = await _saveRepository.saveListing(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
  }

  Future<void> unsaveListing(int productId) async {
    final response = await _saveRepository.unsaveListing(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
  }

  Future<String?> shareProduct(int productId) async {
    final response = await _productRepository.shareProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
    return response.data;
  }

  Future<void> reportProduct({
    required int productId,
    required String reason,
    String? details,
  }) async {
    final response = await _reportRepository.reportProduct(
      productId: productId,
      reason: reason,
      details: details,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }
  }
}
