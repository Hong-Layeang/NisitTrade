import '../entities/product_entity.dart';
import '../../core/errors/api_response.dart';

/// Repository interface for managing product data
abstract class IProductRepository {
  Future<ApiResponse<List<ProductEntity>>> getProducts({
    int? categoryId,
    String? status,
    String? search,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<ProductEntity>> getProduct(int id);

  Future<ApiResponse<ProductEntity>> createProduct({
    required String title,
    String? description,
    required double price,
    required int categoryId,
  });

  Future<ApiResponse<ProductEntity>> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? categoryId,
  });

  Future<ApiResponse<void>> deleteProduct(int id);

  Future<ApiResponse<ProductEntity>> updateProductStatus({
    required int id,
    required String status,
  });

  Future<ApiResponse<ProductEntity>> hideProduct(int productId);
  
  Future<ApiResponse<ProductEntity>> unhideProduct(int productId);

  Future<ApiResponse<String>> shareProduct(int productId);
}
