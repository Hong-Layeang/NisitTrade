import '../../core/errors/api_response.dart';

/// Repository interface for managing saved product listings
abstract class IProductSaveRepository {
  Future<ApiResponse<void>> saveListing(int productId);
  
  Future<ApiResponse<void>> unsaveListing(int productId);
}
