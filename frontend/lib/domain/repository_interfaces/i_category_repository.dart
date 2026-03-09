import '../entities/category_entity.dart';
import '../../core/errors/api_response.dart';

/// Repository interface for managing category data
abstract class ICategoryRepository {
  Future<ApiResponse<List<CategoryEntity>>> getCategories();
  
  Future<ApiResponse<CategoryEntity>> getCategory(int id);

  Future<ApiResponse<CategoryEntity>> createCategory({
    required String name,
  });

  Future<ApiResponse<CategoryEntity>> updateCategory({
    required int id,
    required String name,
  });

  Future<ApiResponse<void>> deleteCategory(int id);
}
