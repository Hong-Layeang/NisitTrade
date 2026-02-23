import 'package:dio/dio.dart';

import '../../models/product.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'api_response.dart';

/// Service for product-related API calls
class ProductApiService {
  ProductApiService._();

  static final ProductApiService instance = ProductApiService._();

  final Dio _dio = ApiClient.instance.dio;

  /// Get all products with optional filtering
  ///
  /// Query parameters:
  /// - category_id: Filter by category
  /// - status: Filter by status (available, reserved, sold, hidden)
  /// - search: Search in title and description
  Future<ApiResponse<List<Product>>> getProducts({
    int? categoryId,
    String? status,
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/products',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final products = (response.data as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();

      return ApiResponse.success(products);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch products: $e'),
      );
    }
  }

  /// Get a single product by ID
  Future<ApiResponse<Product>> getProduct(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      final product = Product.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(product);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to fetch product: $e'),
      );
    }
  }

  /// Create a new product
  Future<ApiResponse<Product>> createProduct({
    required String title,
    String? description,
    required double price,
    required int categoryId,
  }) async {
    try {
      final response = await _dio.post(
        '/products',
        data: {
          'title': title,
          'description': description,
          'price': price,
          'category_id': categoryId,
        },
      );

      final product = Product.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(product);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to create product: $e'),
      );
    }
  }

  /// Update an existing product
  Future<ApiResponse<Product>> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? categoryId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (price != null) data['price'] = price;
      if (categoryId != null) data['category_id'] = categoryId;

      final response = await _dio.put('/products/$id', data: data);

      final product = Product.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(product);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to update product: $e'),
      );
    }
  }

  /// Delete a product
  Future<ApiResponse<void>> deleteProduct(int id) async {
    try {
      await _dio.delete('/products/$id');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to delete product: $e'),
      );
    }
  }

  /// Update product status
  Future<ApiResponse<Product>> updateProductStatus({
    required int id,
    required String status,
  }) async {
    try {
      final response = await _dio.patch(
        '/products/$id/status',
        data: {'status': status},
      );

      final product = Product.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(product);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to update product status: $e'),
      );
    }
  }

  /// Add images to a product
  Future<ApiResponse<Product>> addProductImages({
    required int id,
    required List<String> imagePaths,
  }) async {
    try {
      final formData = FormData();

      for (final imagePath in imagePaths) {
        formData.files.add(
          MapEntry('images', await MultipartFile.fromFile(imagePath)),
        );
      }

      final response = await _dio.post(
        '/products/$id/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      final product = Product.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(product);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to add product images: $e'),
      );
    }
  }

  /// Delete a product image
  Future<ApiResponse<void>> deleteProductImage({
    required int productId,
    required int imageId,
  }) async {
    try {
      await _dio.delete('/products/$productId/images/$imageId');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to delete product image: $e'),
      );
    }
  }

  /// Like a product
  Future<ApiResponse<void>> likeProduct(int productId) async {
    try {
      await _dio.post('/products/$productId/likes');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to like product: $e'),
      );
    }
  }

  /// Unlike a product
  Future<ApiResponse<void>> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    try {
      await _dio.delete('/products/$productId/likes/$likeId');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to unlike product: $e'),
      );
    }
  }

  /// Add a comment to a product
  Future<ApiResponse<void>> addComment({
    required int productId,
    required String content,
    int? rating,
  }) async {
    try {
      final Map<String, dynamic> data = {'content': content};
      if (rating != null) data['rating'] = rating;

      await _dio.post('/products/$productId/comments', data: data);
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to add comment: $e'),
      );
    }
  }

  /// Save (bookmark) a listing
  Future<ApiResponse<void>> saveListing(int productId) async {
    try {
      await _dio.post('/products/$productId/saves');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to save listing: $e'),
      );
    }
  }

  /// Remove a saved listing
  Future<ApiResponse<void>> unsaveListing(int productId) async {
    try {
      await _dio.delete('/products/$productId/saves');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to remove saved listing: $e'),
      );
    }
  }

  /// Hide a product
  Future<ApiResponse<Product>> hideProduct(int productId) async {
    try {
      final response = await _dio.patch('/products/$productId/hide');
      final product = Product.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(product);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to hide product: $e'),
      );
    }
  }

  /// Unhide a product
  Future<ApiResponse<Product>> unhideProduct(int productId) async {
    try {
      final response = await _dio.patch('/products/$productId/unhide');
      final product = Product.fromJson(response.data as Map<String, dynamic>);
      return ApiResponse.success(product);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to unhide product: $e'),
      );
    }
  }

  /// Share product
  Future<ApiResponse<String>> shareProduct(int productId) async {
    try {
      final response = await _dio.get('/products/$productId/share');
      final data = response.data as Map<String, dynamic>;
      final shareUrl = data['share_url']?.toString() ?? '';
      return ApiResponse.success(shareUrl);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to get share link: $e'),
      );
    }
  }

  /// Report product
  Future<ApiResponse<void>> reportProduct({
    required int productId,
    required String reason,
    String? details,
  }) async {
    try {
      await _dio.post(
        '/products/$productId/reports',
        data: {
          'reason': reason,
          'details': details,
        },
      );
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to report product: $e'),
      );
    }
  }

  /// Delete a comment
  Future<ApiResponse<void>> deleteComment({
    required int productId,
    required int commentId,
  }) async {
    try {
      await _dio.delete('/products/$productId/comments/$commentId');
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(
        ApiException(message: 'Failed to delete comment: $e'),
      );
    }
  }
}
