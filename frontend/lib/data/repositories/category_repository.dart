import '../../models/category.dart';
import '../../services/api/api_response.dart';
import '../../services/api/category_api_service.dart';

/// Repository for managing category data
/// Provides a clean abstraction over the API service
abstract class CategoryRepository {
  Future<ApiResponse<List<Category>>> getCategories();
  
  Future<ApiResponse<Category>> getCategory(int id);

  Future<ApiResponse<Category>> createCategory({
    required String name,
  });

  Future<ApiResponse<Category>> updateCategory({
    required int id,
    required String name,
  });

  Future<ApiResponse<void>> deleteCategory(int id);
}

/// Implementation of CategoryRepository using the API service
class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl({CategoryApiService? apiService})
      : _apiService = apiService ?? CategoryApiService.instance;

  final CategoryApiService _apiService;

  @override
  Future<ApiResponse<List<Category>>> getCategories() async {
    return _apiService.getCategories();
  }

  @override
  Future<ApiResponse<Category>> getCategory(int id) async {
    return _apiService.getCategory(id);
  }

  @override
  Future<ApiResponse<Category>> createCategory({
    required String name,
  }) async {
    return _apiService.createCategory(name: name);
  }

  @override
  Future<ApiResponse<Category>> updateCategory({
    required int id,
    required String name,
  }) async {
    return _apiService.updateCategory(id: id, name: name);
  }

  @override
  Future<ApiResponse<void>> deleteCategory(int id) async {
    return _apiService.deleteCategory(id);
  }
}
