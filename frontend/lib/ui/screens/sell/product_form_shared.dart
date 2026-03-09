import '../../../core/errors/api_exception.dart';
import '../../../data/models/category.dart';
import '../../../domain/repository_interfaces/i_category_repository.dart';

class ProductFormValidationResult {
  final String title;
  final String description;
  final double? price;
  final String? error;

  const ProductFormValidationResult({
    required this.title,
    required this.description,
    required this.price,
    required this.error,
  });

  bool get isValid => error == null;
}

class ProductFormShared {
  const ProductFormShared._();

  static Future<List<Category>> loadCategories(
    ICategoryRepository categoryRepository,
  ) async {
    final response = await categoryRepository.getCategories();
    if (!response.isSuccess) {
      throw response.error ??
          ApiException(message: 'Failed to load product categories.');
    }

    return (response.data ?? [])
        .map((entity) => Category.fromEntity(entity))
        .toList();
  }

  static ProductFormValidationResult validateSubmission({
    required String titleInput,
    required String descriptionInput,
    required String priceInput,
    required int? selectedCategoryId,
    required int imageCount,
    required String imageRequiredMessage,
  }) {
    final title = titleInput.trim();
    final description = descriptionInput.trim();
    final price = double.tryParse(priceInput.trim());

    if (title.isEmpty) {
      return ProductFormValidationResult(
        title: title,
        description: description,
        price: price,
        error: 'Title is required.',
      );
    }

    if (price == null || price <= 0) {
      return ProductFormValidationResult(
        title: title,
        description: description,
        price: price,
        error: 'Please enter a valid price.',
      );
    }

    if (selectedCategoryId == null) {
      return ProductFormValidationResult(
        title: title,
        description: description,
        price: price,
        error: 'Please select a category.',
      );
    }

    if (imageCount < 1) {
      return ProductFormValidationResult(
        title: title,
        description: description,
        price: price,
        error: imageRequiredMessage,
      );
    }

    return ProductFormValidationResult(
      title: title,
      description: description,
      price: price,
      error: null,
    );
  }
}