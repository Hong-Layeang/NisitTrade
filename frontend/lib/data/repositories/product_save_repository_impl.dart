import '../../core/errors/api_response.dart';
import '../repository_interfaces/i_product_save_repository.dart';
import 'product_repository_impl.dart';

class ProductSaveRepositoryImpl implements IProductSaveRepository {
  ProductSaveRepositoryImpl({ProductRepositoryImpl? repository})
      : _repository = repository ?? ProductRepositoryImpl();

  final ProductRepositoryImpl _repository;

  @override
  Future<ApiResponse<void>> saveListing(int productId) async {
    return _repository.saveListing(productId);
  }

  @override
  Future<ApiResponse<void>> unsaveListing(int productId) async {
    return _repository.unsaveListing(productId);
  }
}
