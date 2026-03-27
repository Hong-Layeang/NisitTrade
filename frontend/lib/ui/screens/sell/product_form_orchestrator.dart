import 'package:image_picker/image_picker.dart';

import '../../../core/errors/api_exception.dart';
import '../../../data/dtos/product_dto.dart';
import '../../../data/repository_interfaces/i_product_image_repository.dart';
import '../../../data/repository_interfaces/i_product_repository.dart';

/// Result of a product form submission.
class ProductSubmissionResult {
  final bool success;
  final String message;
  final ProductDto? product;
  final ApiException? error;

  const ProductSubmissionResult._({
    required this.success,
    required this.message,
    this.product,
    this.error,
  });

  factory ProductSubmissionResult.success(String message, ProductDto product) {
    return ProductSubmissionResult._(
      success: true,
      message: message,
      product: product,
    );
  }

  factory ProductSubmissionResult.failure(String message, ApiException error) {
    return ProductSubmissionResult._(
      success: false,
      message: message,
      error: error,
    );
  }
}

/// Handles the full submission flow including: Product creation/update, Image uploads, Image deletions (for edit mode)
class ProductFormOrchestrator {
  final IProductRepository _productRepository;
  final IProductImageRepository _productImageRepository;

  ProductFormOrchestrator({
    required IProductRepository productRepository,
    required IProductImageRepository productImageRepository,
  })  : _productRepository = productRepository,
        _productImageRepository = productImageRepository;

  /// Creates a new product with images.
  Future<ProductSubmissionResult> createProduct({
    required String title,
    required String? description,
    required double price,
    required int categoryId,
    required List<XFile> images,
  }) async {
    try {
      // 1. Create product
      final createResponse = await _productRepository.createProduct(
        title: title,
        description: description,
        price: price,
        categoryId: categoryId,
      );

      if (!createResponse.isSuccess) {
        throw createResponse.error!;
      }

      final product = createResponse.data!;

      // 2. Upload images
      if (images.isNotEmpty) {
        final imagePaths = images.map((image) => image.path).toList();
        final imageResponse = await _productImageRepository.addProductImages(
          productId: product.id,
          imagePaths: imagePaths,
        );

        if (!imageResponse.isSuccess) {
          throw imageResponse.error!;
        }
      }

      return ProductSubmissionResult.success(
        'Product created successfully.',
        product,
      );
    } on ApiException catch (e) {
      return ProductSubmissionResult.failure(e.message, e);
    }
  }

  /// Updates an existing product with image changes.
  ///
  Future<ProductSubmissionResult> updateProduct({
    required int productId,
    required String title,
    required String? description,
    required double price,
    required int categoryId,
    required Set<int> imageIdsToDelete,
    required List<XFile> newImages,
  }) async {
    try {
      // 1. Update product basic info
      final updateResponse = await _productRepository.updateProduct(
        id: productId,
        title: title,
        description: description,
        price: price,
        categoryId: categoryId,
      );

      if (!updateResponse.isSuccess) {
        throw updateResponse.error!;
      }

      final product = updateResponse.data!;

      // 2. Delete marked images
      for (final imageId in imageIdsToDelete) {
        final deleteResponse = await _productImageRepository.deleteProductImage(
          productId: productId,
          imageId: imageId,
        );

        if (!deleteResponse.isSuccess) {
          throw deleteResponse.error!;
        }
      }

      // 3. Add new images
      if (newImages.isNotEmpty) {
        final imagePaths = newImages.map((image) => image.path).toList();
        final imageResponse = await _productImageRepository.addProductImages(
          productId: productId,
          imagePaths: imagePaths,
        );

        if (!imageResponse.isSuccess) {
          throw imageResponse.error!;
        }
      }

      return ProductSubmissionResult.success(
        'Listing updated successfully.',
        product,
      );
    } on ApiException catch (e) {
      return ProductSubmissionResult.failure(e.message, e);
    }
  }
}

