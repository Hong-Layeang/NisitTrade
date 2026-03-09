import '../models/product.dart';
import '../../core/errors/api_response.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repository_interfaces/i_product_repository.dart';
import '../providers/product_api_service.dart';

/// Implementation of IProductRepository using the API service
/// Focuses on core product CRUD operations only
/// Other responsibilities (likes, saves, comments, etc.) are handled by separate repositories
class ProductRepositoryImpl implements IProductRepository {
  ProductRepositoryImpl({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService.instance;

  final ProductApiService _apiService;

  @override
  Future<ApiResponse<List<ProductEntity>>> getProducts({
    int? categoryId,
    String? status,
    String? search,
    int? limit,
    int? offset,
  }) async {
    final response = await _apiService.getProducts(
      categoryId: categoryId,
      status: status,
      search: search,
      limit: limit,
      offset: offset,
    );
    if (response.isSuccess && response.data != null) {
      final entities = response.data!.map((model) => model.toEntity()).toList();
      return ApiResponse.success(entities);
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<ProductEntity>> getProduct(int id) async {
    final response = await _apiService.getProduct(id);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<ProductEntity>> createProduct({
    required String title,
    String? description,
    required double price,
    required int categoryId,
  }) async {
    final response = await _apiService.createProduct(
      title: title,
      description: description,
      price: price,
      categoryId: categoryId,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<ProductEntity>> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? categoryId,
  }) async {
    final response = await _apiService.updateProduct(
      id: id,
      title: title,
      description: description,
      price: price,
      categoryId: categoryId,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<void>> deleteProduct(int id) async {
    return _apiService.deleteProduct(id);
  }

  @override
  Future<ApiResponse<ProductEntity>> updateProductStatus({
    required int id,
    required String status,
  }) async {
    final response = await _apiService.updateProductStatus(
      id: id,
      status: status,
    );
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<ProductEntity>> hideProduct(int productId) async {
    final response = await _apiService.hideProduct(productId);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<ProductEntity>> unhideProduct(int productId) async {
    final response = await _apiService.unhideProduct(productId);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<String>> shareProduct(int productId) async {
    return _apiService.shareProduct(productId);
  }

  // Legacy methods maintained for backward compatibility
  // These delegate to the API service directly and return models
  // TODO: Remove these once all consumers are updated to use separate repositories
  @Deprecated('Use ProductImageRepository instead')
  Future<ApiResponse<Product>> addProductImages({
    required int id,
    required List<String> imagePaths,
  }) async {
    return _apiService.addProductImages(
      id: id,
      imagePaths: imagePaths,
    );
  }

  @Deprecated('Use ProductImageRepository instead')
  Future<ApiResponse<void>> deleteProductImage({
    required int productId,
    required int imageId,
  }) async {
    return _apiService.deleteProductImage(
      productId: productId,
      imageId: imageId,
    );
  }

  @Deprecated('Use ProductLikeRepository instead')
  Future<ApiResponse<void>> likeProduct(int productId) async {
    return _apiService.likeProduct(productId);
  }

  @Deprecated('Use ProductLikeRepository instead')
  Future<ApiResponse<void>> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    return _apiService.unlikeProduct(
      productId: productId,
      likeId: likeId,
    );
  }

  @Deprecated('Use ProductCommentRepository instead')
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

  @Deprecated('Use ProductCommentRepository instead')
  Future<ApiResponse<void>> deleteComment({
    required int productId,
    required int commentId,
  }) async {
    return _apiService.deleteComment(
      productId: productId,
      commentId: commentId,
    );
  }

  @Deprecated('Use ProductSaveRepository instead')
  Future<ApiResponse<void>> saveListing(int productId) async {
    return _apiService.saveListing(productId);
  }

  @Deprecated('Use ProductSaveRepository instead')
  Future<ApiResponse<void>> unsaveListing(int productId) async {
    return _apiService.unsaveListing(productId);
  }

  @Deprecated('Use ProductReportRepository instead')
  Future<ApiResponse<void>> reportProduct({
    required int productId,
    required String reason,
    String? details,
  }) async {
    return _apiService.reportProduct(
      productId: productId,
      reason: reason,
      details: details,
    );
  }
}
