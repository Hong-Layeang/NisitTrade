import '../../core/errors/api_response.dart';

/// Repository interface for managing product images
/// Separated from ProductRepository to follow Single Responsibility Principle
abstract class IProductImageRepository {
  Future<ApiResponse<void>> addProductImages({
    required int productId,
    required List<String> imagePaths,
  });

  Future<ApiResponse<void>> deleteProductImage({
    required int productId,
    required int imageId,
  });
}
