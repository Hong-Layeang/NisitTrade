import '../../data/dtos/category_dto.dart';
import '../../core/errors/api_response.dart';

abstract class ICategoryRepository {
  Future<ApiResponse<List<CategoryDto>>> getCategories();
  
  Future<ApiResponse<CategoryDto>> getCategory(int id);

  Future<ApiResponse<CategoryDto>> createCategory({
    required String name,
  });

  Future<ApiResponse<CategoryDto>> updateCategory({
    required int id,
    required String name,
  });

  Future<ApiResponse<void>> deleteCategory(int id);
}

