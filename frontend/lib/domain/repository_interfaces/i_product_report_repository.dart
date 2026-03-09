import '../../core/errors/api_response.dart';

/// Repository interface for managing product reports
abstract class IProductReportRepository {
  Future<ApiResponse<void>> reportProduct({
    required int productId,
    required String reason,
    String? details,
  });
}
