import '../../core/errors/api_response.dart';
import '../../domain/repository_interfaces/i_product_image_repository.dart';
import '../providers/product_api_service.dart';

/// Implementation of IProductImageRepository
/// Handles product image management operations
class ProductImageRepositoryImpl implements IProductImageRepository {
  ProductImageRepositoryImpl({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService.instance;

  final ProductApiService _apiService;

  @override
  Future<ApiResponse<void>> addProductImages({
    required int productId,
    required List<String> imagePaths,
  }) async {
    final response = await _apiService.addProductImages(
      id: productId,
      imagePaths: imagePaths,
    );
    // API returns product, but we just need void
    if (response.isSuccess) {
      return ApiResponse.success(null);
    }
    return ApiResponse.error(response.error!);
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
}
