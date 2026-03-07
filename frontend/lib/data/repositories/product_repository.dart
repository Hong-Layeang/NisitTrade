import '../models/product.dart';
import '../../core/errors/api_response.dart';
import '../providers/product_api_service.dart';

/// Repository for managing product data
/// Provides a clean abstraction over the API service
abstract class ProductRepository {
  Future<ApiResponse<List<Product>>> getProducts({
    int? categoryId,
    String? status,
    String? search,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<Product>> getProduct(int id);

  Future<ApiResponse<Product>> createProduct({
    required String title,
    String? description,
    required double price,
    required int categoryId,
  });

  Future<ApiResponse<Product>> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? categoryId,
  });

  Future<ApiResponse<void>> deleteProduct(int id);

  Future<ApiResponse<Product>> updateProductStatus({
    required int id,
    required String status,
  });

  Future<ApiResponse<Product>> addProductImages({
    required int id,
    required List<String> imagePaths,
  });

  Future<ApiResponse<void>> deleteProductImage({
    required int productId,
    required int imageId,
  });

  // Likes
  Future<ApiResponse<void>> likeProduct(int productId);
  Future<ApiResponse<void>> unlikeProduct({
    required int productId,
    required int likeId,
  });

  // Saves
  Future<ApiResponse<void>> saveListing(int productId);
  Future<ApiResponse<void>> unsaveListing(int productId);

  // Hide/Unhide
  Future<ApiResponse<Product>> hideProduct(int productId);
  Future<ApiResponse<Product>> unhideProduct(int productId);

  // Share
  Future<ApiResponse<String>> shareProduct(int productId);

  // Report
  Future<ApiResponse<void>> reportProduct({
    required int productId,
    required String reason,
    String? details,
  });

  // Comments
  Future<ApiResponse<void>> addComment({
    required int productId,
    required String content,
    int? rating,
  });
  Future<ApiResponse<void>> deleteComment({
    required int productId,
    required int commentId,
  });
}

/// Implementation of ProductRepository using the API service
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService.instance;

  final ProductApiService _apiService;

  @override
  Future<ApiResponse<List<Product>>> getProducts({
    int? categoryId,
    String? status,
    String? search,
    int? limit,
    int? offset,
  }) async {
    return _apiService.getProducts(
      categoryId: categoryId,
      status: status,
      search: search,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<ApiResponse<Product>> getProduct(int id) async {
    return _apiService.getProduct(id);
  }

  @override
  Future<ApiResponse<Product>> createProduct({
    required String title,
    String? description,
    required double price,
    required int categoryId,
  }) async {
    return _apiService.createProduct(
      title: title,
      description: description,
      price: price,
      categoryId: categoryId,
    );
  }

  @override
  Future<ApiResponse<Product>> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? categoryId,
  }) async {
    return _apiService.updateProduct(
      id: id,
      title: title,
      description: description,
      price: price,
      categoryId: categoryId,
    );
  }

  @override
  Future<ApiResponse<void>> deleteProduct(int id) async {
    return _apiService.deleteProduct(id);
  }

  @override
  Future<ApiResponse<Product>> updateProductStatus({
    required int id,
    required String status,
  }) async {
    return _apiService.updateProductStatus(
      id: id,
      status: status,
    );
  }

  @override
  Future<ApiResponse<Product>> addProductImages({
    required int id,
    required List<String> imagePaths,
  }) async {
    return _apiService.addProductImages(
      id: id,
      imagePaths: imagePaths,
    );
  }

  @override
  Future<ApiResponse<void>> deleteProductImage({
    required int productId,
    required int imageId,
  }) async {
    return _apiService.deleteProductImage(
      productId: productId,
      imageId: imageId,
    );
  }

  @override
  Future<ApiResponse<void>> likeProduct(int productId) async {
    return _apiService.likeProduct(productId);
  }

  @override
  Future<ApiResponse<void>> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    return _apiService.unlikeProduct(
      productId: productId,
      likeId: likeId,
    );
  }

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

  @override
  Future<ApiResponse<void>> saveListing(int productId) async {
    return _apiService.saveListing(productId);
  }

  @override
  Future<ApiResponse<void>> unsaveListing(int productId) async {
    return _apiService.unsaveListing(productId);
  }

  @override
  Future<ApiResponse<Product>> hideProduct(int productId) async {
    return _apiService.hideProduct(productId);
  }

  @override
  Future<ApiResponse<Product>> unhideProduct(int productId) async {
    return _apiService.unhideProduct(productId);
  }

  @override
  Future<ApiResponse<String>> shareProduct(int productId) async {
    return _apiService.shareProduct(productId);
  }

  @override
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
