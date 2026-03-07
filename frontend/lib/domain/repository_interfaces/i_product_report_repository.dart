import '../../core/errors/api_response.dart';

/// Repository interface for managing product reports
/// Separated from ProductRepository to follow Single Responsibility Principle
abstract class IProductReportRepository {
  Future<ApiResponse<void>> reportProduct({
    required int productId,
    required String reason,
    String? details,
  });
}
