import '../../core/errors/api_response.dart';
import '../../domain/repository_interfaces/i_product_report_repository.dart';
import '../providers/product_api_service.dart';

/// Implementation of IProductReportRepository
/// Handles product report operations
class ProductReportRepositoryImpl implements IProductReportRepository {
  ProductReportRepositoryImpl({ProductApiService? apiService})
      : _apiService = apiService ?? ProductApiService.instance;

  final ProductApiService _apiService;

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
