import '../../core/errors/api_response.dart';
import '../../domain/repository_interfaces/i_product_save_repository.dart';
import '../providers/product_api_service.dart';

/// Implementation of IProductSaveRepository
/// Handles save/unsave product operations
class ProductSaveRepositoryImpl implements IProductSaveRepository {
  ProductSaveRepositoryImpl({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService.instance;

  final ProductApiService _apiService;

  @override
  Future<ApiResponse<void>> saveListing(int productId) async {
    return _apiService.saveListing(productId);
  }

  @override
  Future<ApiResponse<void>> unsaveListing(int productId) async {
    return _apiService.unsaveListing(productId);
  }
}
