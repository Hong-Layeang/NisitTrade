import 'package:dio/dio.dart';

import '../../core/errors/api_exception.dart';
import '../dtos/product_dto.dart';
import '../../core/errors/api_response.dart';
import '../../core/network/api_client.dart';
import '../repository_interfaces/i_product_repository.dart';

class ProductRepositoryImpl implements IProductRepository {
  ProductRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  @override
  Future<ApiResponse<List<ProductDto>>> getProducts({
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
          .map((json) => ProductDto.fromJson(json as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(products);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch products: $e'));
    }
  }

  @override
  Future<ApiResponse<ProductDto>> getProduct(int id) async {
    try {
      final response = await _dio.get('/products/$id');
      return ApiResponse.success(ProductDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to fetch product: $e'));
    }
  }

  @override
  Future<ApiResponse<ProductDto>> createProduct({
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
      return ApiResponse.success(ProductDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to create product: $e'));
    }
  }

  @override
  Future<ApiResponse<ProductDto>> updateProduct({
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
      return ApiResponse.success(ProductDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to update product: $e'));
    }
  }

  @override
  Future<ApiResponse<void>> deleteProduct(int id) async {
    return _voidCall(() => _dio.delete('/products/$id'), 'Failed to delete product');
  }

  @override
  Future<ApiResponse<ProductDto>> updateProductStatus({
    required int id,
    required String status,
  }) async {
    try {
      final response = await _dio.patch('/products/$id/status', data: {'status': status});
      return ApiResponse.success(ProductDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to update product status: $e'));
    }
  }

  @override
  Future<ApiResponse<ProductDto>> hideProduct(int productId) async {
    try {
      final response = await _dio.patch('/products/$productId/hide');
      return ApiResponse.success(ProductDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to hide product: $e'));
    }
  }

  @override
  Future<ApiResponse<ProductDto>> unhideProduct(int productId) async {
    try {
      final response = await _dio.patch('/products/$productId/unhide');
      return ApiResponse.success(ProductDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to unhide product: $e'));
    }
  }

  @override
  Future<ApiResponse<String>> shareProduct(int productId) async {
    try {
      final response = await _dio.get('/products/$productId/share');
      final map = response.data as Map<String, dynamic>;
      return ApiResponse.success(map['share_url']?.toString() ?? '');
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to get share link: $e'));
    }
  }

  @Deprecated('Use ProductImageRepository instead')
  Future<ApiResponse<ProductDto>> addProductImages({
    required int id,
    required List<String> imagePaths,
  }) async {
    try {
      final formData = FormData();
      for (final imagePath in imagePaths) {
        formData.files.add(MapEntry('images', await MultipartFile.fromFile(imagePath)));
      }
      final response = await _dio.post(
        '/products/$id/images',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponse.success(ProductDto.fromJson(response.data as Map<String, dynamic>));
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: 'Failed to add product images: $e'));
    }
  }

  @Deprecated('Use ProductImageRepository instead')
  Future<ApiResponse<void>> deleteProductImage({
    required int productId,
    required int imageId,
  }) async {
    return _voidCall(
      () => _dio.delete('/products/$productId/images/$imageId'),
      'Failed to delete product image',
    );
  }

  @Deprecated('Use ProductLikeRepository instead')
  Future<ApiResponse<void>> likeProduct(int productId) async {
    return _voidCall(() => _dio.post('/products/$productId/likes'), 'Failed to like product');
  }

  @Deprecated('Use ProductLikeRepository instead')
  Future<ApiResponse<void>> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    return _voidCall(
      () => _dio.delete('/products/$productId/likes/$likeId'),
      'Failed to unlike product',
    );
  }

  @Deprecated('Use ProductCommentRepository instead')
  Future<ApiResponse<void>> addComment({
    required int productId,
    required String content,
    int? rating,
  }) async {
    final data = <String, dynamic>{'content': content};
    if (rating != null) data['rating'] = rating;
    return _voidCall(
      () => _dio.post('/products/$productId/comments', data: data),
      'Failed to add comment',
    );
  }

  @Deprecated('Use ProductCommentRepository instead')
  Future<ApiResponse<void>> updateComment({
    required int productId,
    required int commentId,
    required String content,
    int? rating,
  }) async {
    final data = <String, dynamic>{'content': content};
    if (rating != null) data['rating'] = rating;
    return _voidCall(
      () => _dio.put('/products/$productId/comments/$commentId', data: data),
      'Failed to update comment',
    );
  }

  @Deprecated('Use ProductCommentRepository instead')
  Future<ApiResponse<void>> deleteComment({
    required int productId,
    required int commentId,
  }) async {
    return _voidCall(
      () => _dio.delete('/products/$productId/comments/$commentId'),
      'Failed to delete comment',
    );
  }

  @Deprecated('Use ProductSaveRepository instead')
  Future<ApiResponse<void>> saveListing(int productId) async {
    return _voidCall(() => _dio.post('/products/$productId/saves'), 'Failed to save listing');
  }

  @Deprecated('Use ProductSaveRepository instead')
  Future<ApiResponse<void>> unsaveListing(int productId) async {
    return _voidCall(
      () => _dio.delete('/products/$productId/saves'),
      'Failed to remove saved listing',
    );
  }

  @Deprecated('Use ProductReportRepository instead')
  Future<ApiResponse<void>> reportProduct({
    required int productId,
    required String reason,
    String? details,
  }) async {
    return _voidCall(
      () => _dio.post(
        '/products/$productId/reports',
        data: {'reason': reason, 'details': details},
      ),
      'Failed to report product',
    );
  }

  Future<ApiResponse<void>> _voidCall(
    Future<dynamic> Function() fn,
    String errorMessage,
  ) async {
    try {
      await fn();
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.error(ApiException.fromDioException(e));
    } catch (e) {
      return ApiResponse.error(ApiException(message: '$errorMessage: $e'));
    }
  }
}

