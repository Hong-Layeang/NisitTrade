import 'package:dio/dio.dart';

import '../models/category.dart';
import 'api_client.dart';
import '../../core/errors/api_exception.dart';
import '../../core/errors/api_response.dart';

/// Service for category-related API calls
class CategoryApiService {
  CategoryApiService._();
  
  static final CategoryApiService instance = CategoryApiService._();
  
  final Dio _dio = ApiClient.instance.dio;

  /// Get all categories
  Future<ApiResponse<List<Category>>> getCategories() async {
    try {
      final response = await _dio.get('/categories');

      final categories = (response.data as List)
          .map((json) => Category.fromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse.success(categories);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch categories: $e'),
      );
    }
  }

  /// Get a single category by ID
  Future<ApiResponse<Category>> getCategory(int id) async {
    try {
      final response = await _dio.get('/categories/$id');
      final category = Category.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(category);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch category: $e'),
      );
    }
  }

  /// Create a new category (admin only)
  Future<ApiResponse<Category>> createCategory({
    required String name,
  }) async {
    try {
      final response = await _dio.post(
        '/categories',
        data: {'name': name},
      );

      final category = Category.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(category);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to create category: $e'),
      );
    }
  }

  /// Update an existing category (admin only)
  Future<ApiResponse<Category>> updateCategory({
    required int id,
    required String name,
  }) async {
    try {
      final response = await _dio.put(
        '/categories/$id',
        data: {'name': name},
      );

      final category = Category.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(category);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to update category: $e'),
      );
    }
  }

  /// Delete a category (admin only)
  Future<ApiResponse<void>> deleteCategory(int id) async {
    try {
      await _dio.delete('/categories/$id');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to delete category: $e'),
      );
    }
  }
}
