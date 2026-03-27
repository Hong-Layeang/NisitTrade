import '../../core/errors/api_response.dart';
import '../repository_interfaces/i_product_report_repository.dart';
import 'product_repository_impl.dart';

class ProductReportRepositoryImpl implements IProductReportRepository {
  ProductReportRepositoryImpl({ProductRepositoryImpl? repository})
      : _repository = repository ?? ProductRepositoryImpl();

  final ProductRepositoryImpl _repository;

  @override
  Future<ApiResponse<void>> reportProduct({
    required int productId,
    required String reason,
    String? details,
  }) async {
    return _repository.reportProduct(
      productId: productId,
      reason: reason,
      details: details,
    );
  }
}
