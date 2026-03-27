import '../../core/errors/api_response.dart';
import '../repository_interfaces/i_product_like_repository.dart';
import 'product_repository_impl.dart';

class ProductLikeRepositoryImpl implements IProductLikeRepository {
  ProductLikeRepositoryImpl({ProductRepositoryImpl? repository})
      : _repository = repository ?? ProductRepositoryImpl();

  final ProductRepositoryImpl _repository;

  @override
  Future<ApiResponse<void>> likeProduct(int productId) async {
    return _repository.likeProduct(productId);
  }

  @override
  Future<ApiResponse<void>> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    return _repository.unlikeProduct(
      productId: productId,
      likeId: likeId,
    );
  }
}
