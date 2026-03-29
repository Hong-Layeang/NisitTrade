import '../../data/dtos/product_dto.dart';
import '../../core/errors/api_response.dart';

abstract class IProductRepository {
  Future<ApiResponse<List<ProductDto>>> getProducts({
    int? categoryId,
    String? status,
    String? search,
    int? limit,
    int? offset,
  });

  Future<ApiResponse<ProductDto>> getProduct(int id);

  Future<ApiResponse<ProductDto>> createProduct({
    required String title,
    String? description,
    required double price,
    required int categoryId,
  });

  Future<ApiResponse<ProductDto>> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? categoryId,
  });

  Future<ApiResponse<void>> deleteProduct(int id);

  Future<ApiResponse<ProductDto>> updateProductStatus({
    required int id,
    required String status,
  });

  Future<ApiResponse<ProductDto>> hideProduct(int productId);
  
  Future<ApiResponse<ProductDto>> unhideProduct(int productId);

  Future<ApiResponse<void>> hideProductForViewer(int productId);

  Future<ApiResponse<void>> unhideProductForViewer(int productId);

  Future<ApiResponse<String>> shareProduct(int productId);
}

