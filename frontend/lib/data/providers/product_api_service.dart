import 'package:dio/dio.dart';

import '../models/product.dart';
import 'api_client.dart';
import 'base_api_service.dart';
import '../../core/errors/api_response.dart';

/// Service for product-related API calls
class ProductApiService extends BaseApiService {
  ProductApiService._() : super(ApiClient.instance.dio);

  static final ProductApiService instance = ProductApiService._();

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
    final queryParams = <String, dynamic>{};
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;
    if (limit != null) queryParams['limit'] = limit;
    if (offset != null) queryParams['offset'] = offset;

    return executeListApiCall<Product>(
      call: () => dio.get(
        '/products',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      ),
      itemParser: (json) => Product.fromJson(json as Map<String, dynamic>),
      errorMessage: 'Failed to fetch products',
    );
  }

  /// Get a single product by ID
  Future<ApiResponse<Product>> getProduct(int id) async {
    return executeApiCall<Product>(
      call: () => dio.get('/products/$id'),
      parser: (data) => Product.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to fetch product',
    );
  }

  /// Create a new product
  Future<ApiResponse<Product>> createProduct({
    required String title,
    String? description,
    required double price,
    required int categoryId,
  }) async {
    return executeApiCall<Product>(
      call: () => dio.post(
        '/products',
        data: {
          'title': title,
          'description': description,
          'price': price,
          'category_id': categoryId,
        },
      ),
      parser: (data) => Product.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to create product',
    );
  }

  /// Update an existing product
  Future<ApiResponse<Product>> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? categoryId,
  }) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (categoryId != null) data['category_id'] = categoryId;

    return executeApiCall<Product>(
      call: () => dio.put('/products/$id', data: data),
      parser: (data) => Product.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to update product',
    );
  }

  /// Delete a product
  Future<ApiResponse<void>> deleteProduct(int id) async {
    return executeVoidApiCall(
      call: () => dio.delete('/products/$id'),
      errorMessage: 'Failed to delete product',
    );
  }

  /// Update product status
  Future<ApiResponse<Product>> updateProductStatus({
    required int id,
    required String status,
  }) async {
    return executeApiCall<Product>(
      call: () => dio.patch(
        '/products/$id/status',
        data: {'status': status},
      ),
      parser: (data) => Product.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to update product status',
    );
  }

  /// Add images to a product
  Future<ApiResponse<Product>> addProductImages({
    required int id,
    required List<String> imagePaths,
  }) async {
    final formData = FormData();

    for (final imagePath in imagePaths) {
      formData.files.add(
        MapEntry('images', await MultipartFile.fromFile(imagePath)),
      );
    }

    return executeApiCall<Product>(
      call: () => dio.post(
        '/products/$id/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      ),
      parser: (data) => Product.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to add product images',
    );
  }

  /// Delete a product image
  Future<ApiResponse<void>> deleteProductImage({
    required int productId,
    required int imageId,
  }) async {
    return executeVoidApiCall(
      call: () => dio.delete('/products/$productId/images/$imageId'),
      errorMessage: 'Failed to delete product image',
    );
  }

  /// Like a product
  Future<ApiResponse<void>> likeProduct(int productId) async {
    return executeVoidApiCall(
      call: () => dio.post('/products/$productId/likes'),
      errorMessage: 'Failed to like product',
    );
  }

  /// Unlike a product
  Future<ApiResponse<void>> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    return executeVoidApiCall(
      call: () => dio.delete('/products/$productId/likes/$likeId'),
      errorMessage: 'Failed to unlike product',
    );
  }

  /// Add a comment to a product
  Future<ApiResponse<void>> addComment({
    required int productId,
    required String content,
    int? rating,
  }) async {
    final Map<String, dynamic> data = {'content': content};
    if (rating != null) data['rating'] = rating;

    return executeVoidApiCall(
      call: () => dio.post('/products/$productId/comments', data: data),
      errorMessage: 'Failed to add comment',
    );
  }

  /// Update a comment
  Future<ApiResponse<void>> updateComment({
    required int productId,
    required int commentId,
    required String content,
    int? rating,
  }) async {
    final Map<String, dynamic> data = {'content': content};
    if (rating != null) data['rating'] = rating;

    return executeVoidApiCall(
      call: () => dio.put('/products/$productId/comments/$commentId', data: data),
      errorMessage: 'Failed to update comment',
    );
  }

  /// Save (bookmark) a listing
  Future<ApiResponse<void>> saveListing(int productId) async {
    return executeVoidApiCall(
      call: () => dio.post('/products/$productId/saves'),
      errorMessage: 'Failed to save listing',
    );
  }

  /// Remove a saved listing
  Future<ApiResponse<void>> unsaveListing(int productId) async {
    return executeVoidApiCall(
      call: () => dio.delete('/products/$productId/saves'),
      errorMessage: 'Failed to remove saved listing',
    );
  }

  /// Hide a product
  Future<ApiResponse<Product>> hideProduct(int productId) async {
    return executeApiCall<Product>(
      call: () => dio.patch('/products/$productId/hide'),
      parser: (data) => Product.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to hide product',
    );
  }

  /// Unhide a product
  Future<ApiResponse<Product>> unhideProduct(int productId) async {
    return executeApiCall<Product>(
      call: () => dio.patch('/products/$productId/unhide'),
      parser: (data) => Product.fromJson(data as Map<String, dynamic>),
      errorMessage: 'Failed to unhide product',
    );
  }

  /// Share product
  Future<ApiResponse<String>> shareProduct(int productId) async {
    return executeApiCall<String>(
      call: () => dio.get('/products/$productId/share'),
      parser: (data) {
        final map = data as Map<String, dynamic>;
        return map['share_url']?.toString() ?? '';
      },
      errorMessage: 'Failed to get share link',
    );
  }

  /// Report product
  Future<ApiResponse<void>> reportProduct({
    required int productId,
    required String reason,
    String? details,
  }) async {
    return executeVoidApiCall(
      call: () => dio.post(
        '/products/$productId/reports',
        data: {
          'reason': reason,
          'details': details,
        },
      ),
      errorMessage: 'Failed to report product',
    );
  }

  /// Delete a comment
  Future<ApiResponse<void>> deleteComment({
    required int productId,
    required int commentId,
  }) async {
    return executeVoidApiCall(
      call: () => dio.delete('/products/$productId/comments/$commentId'),
      errorMessage: 'Failed to delete comment',
    );
  }
}
