import '../../core/errors/api_response.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repository_interfaces/i_category_repository.dart';
import '../providers/category_api_service.dart';

/// Implementation of ICategoryRepository using the API service
class CategoryRepositoryImpl implements ICategoryRepository {
  CategoryRepositoryImpl({CategoryApiService? apiService})
      : _apiService = apiService ?? CategoryApiService.instance;

  final CategoryApiService _apiService;

  @override
  Future<ApiResponse<List<CategoryEntity>>> getCategories() async {
    final response = await _apiService.getCategories();
    if (response.isSuccess && response.data != null) {
      final entities = response.data!.map((model) => model.toEntity()).toList();
      return ApiResponse.success(entities);
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<CategoryEntity>> getCategory(int id) async {
    final response = await _apiService.getCategory(id);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<CategoryEntity>> createCategory({
    required String name,
  }) async {
    final response = await _apiService.createCategory(name: name);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<CategoryEntity>> updateCategory({
    required int id,
    required String name,
  }) async {
    final response = await _apiService.updateCategory(id: id, name: name);
    if (response.isSuccess && response.data != null) {
      return ApiResponse.success(response.data!.toEntity());
    }
    return ApiResponse.error(response.error!);
  }

  @override
  Future<ApiResponse<void>> deleteCategory(int id) async {
    return _apiService.deleteCategory(id);
  }
}
