import '../../core/errors/api_response.dart';
import '../repository_interfaces/i_product_image_repository.dart';
import 'product_repository_impl.dart';

class ProductImageRepositoryImpl implements IProductImageRepository {
  ProductImageRepositoryImpl({ProductRepositoryImpl? repository})
      : _repository = repository ?? ProductRepositoryImpl();

  final ProductRepositoryImpl _repository;

  @override
  Future<ApiResponse<void>> addProductImages({
    required int productId,
    required List<String> imagePaths,
  }) async {
    final response = await _repository.addProductImages(
      id: productId,
      imagePaths: imagePaths,
    );
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
    return _repository.deleteProductImage(
      productId: productId,
      imageId: imageId,
    );
  }
}
