import '../../core/errors/api_response.dart';

/// Repository interface for managing product likes
abstract class IProductLikeRepository {
  Future<ApiResponse<void>> likeProduct(int productId);
  
  Future<ApiResponse<void>> unlikeProduct({
    required int productId,
    required int likeId,
  });
}
