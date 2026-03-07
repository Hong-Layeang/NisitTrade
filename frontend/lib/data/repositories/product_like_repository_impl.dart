import '../../core/errors/api_response.dart';
import '../../domain/repository_interfaces/i_product_like_repository.dart';
import '../providers/product_api_service.dart';

/// Implementation of IProductLikeRepository
/// Handles product like/unlike operations
class ProductLikeRepositoryImpl implements IProductLikeRepository {
  ProductLikeRepositoryImpl({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService.instance;

  final ProductApiService _apiService;

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
}
