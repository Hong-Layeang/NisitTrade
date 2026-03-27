import 'package:dio/dio.dart';

import '../../core/errors/api_exception.dart';
import '../../core/errors/api_response.dart';
import '../../core/network/api_client.dart';
import '../dtos/category_dto.dart';
import '../repository_interfaces/i_category_repository.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  CategoryRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  @override
  Future<ApiResponse<List<CategoryDto>>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      final categories = (response.data as List)
          .map((json) => CategoryDto.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(categories);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch categories: $e'));
    }
  }

  @override
  Future<ApiResponse<CategoryDto>> getCategory(int id) async {
    try {
      final response = await _dio.get('/categories/$id');
      final category = CategoryDto.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(category);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch category: $e'));
    }
  }

  @override
  Future<ApiResponse<CategoryDto>> createCategory({required String name}) async {
    try {
      final response = await _dio.post('/categories', data: {'name': name});
      final category = CategoryDto.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(category);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to create category: $e'));
    }
  }

  @override
  Future<ApiResponse<CategoryDto>> updateCategory({
    required int id,
    required String name,
  }) async {
    try {
      final response = await _dio.put('/categories/$id', data: {'name': name});
      final category = CategoryDto.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(category);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to update category: $e'));
    }
  }

  @override
  Future<ApiResponse<void>> deleteCategory(int id) async {
    try {
      await _dio.delete('/categories/$id');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to delete category: $e'));
    }
  }
}

