import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/errors/api_response.dart';
import 'package:frontend/domain/entities/category_entity.dart';
import 'package:frontend/domain/repository_interfaces/i_category_repository.dart';
import 'package:frontend/ui/screens/sell/product_form_shared.dart';

void main() {
  group('ProductFormShared.validateSubmission', () {
    test('returns error when title is empty', () {
      final result = ProductFormShared.validateSubmission(
        titleInput: '   ',
        descriptionInput: 'Desc',
        priceInput: '10',
        selectedCategoryId: 1,
        imageCount: 1,
        imageRequiredMessage: 'Need image',
      );

      expect(result.isValid, isFalse);
      expect(result.error, 'Title is required.');
    });

    test('returns error when price is invalid', () {
      final result = ProductFormShared.validateSubmission(
        titleInput: 'Desk',
        descriptionInput: 'Desc',
        priceInput: 'abc',
        selectedCategoryId: 1,
        imageCount: 1,
        imageRequiredMessage: 'Need image',
      );

      expect(result.isValid, isFalse);
      expect(result.error, 'Please enter a valid price.');
    });

    test('returns error when category is missing', () {
      final result = ProductFormShared.validateSubmission(
        titleInput: 'Desk',
        descriptionInput: 'Desc',
        priceInput: '100',
        selectedCategoryId: null,
        imageCount: 1,
        imageRequiredMessage: 'Need image',
      );

      expect(result.isValid, isFalse);
      expect(result.error, 'Please select a category.');
    });

    test('returns error when no images', () {
      final result = ProductFormShared.validateSubmission(
        titleInput: 'Desk',
        descriptionInput: 'Desc',
        priceInput: '100',
        selectedCategoryId: 1,
        imageCount: 0,
        imageRequiredMessage: 'Please add at least 1 photo.',
      );

      expect(result.isValid, isFalse);
      expect(result.error, 'Please add at least 1 photo.');
    });

    test('returns normalized values when valid', () {
      final result = ProductFormShared.validateSubmission(
        titleInput: '  Desk  ',
        descriptionInput: '  Good condition  ',
        priceInput: '149.50',
        selectedCategoryId: 1,
        imageCount: 2,
        imageRequiredMessage: 'Need image',
      );

      expect(result.isValid, isTrue);
      expect(result.error, isNull);
      expect(result.title, 'Desk');
      expect(result.description, 'Good condition');
      expect(result.price, 149.5);
    });
  });

  group('ProductFormShared.loadCategories', () {
    test('maps entities to categories on success', () async {
      final now = DateTime(2026, 3, 9);
      final repo = _FakeCategoryRepository(
        response: ApiResponse.success([
          CategoryEntity(
            id: 1,
            name: 'Electronics',
            imageUrl: null,
            createdAt: now,
            updatedAt: now,
          ),
        ]),
      );

      final categories = await ProductFormShared.loadCategories(repo);

      expect(categories.length, 1);
      expect(categories.first.id, 1);
      expect(categories.first.name, 'Electronics');
    });

    test('throws ApiException when repository fails', () async {
      final repo = _FakeCategoryRepository(
        response: ApiResponse.error(
          ApiException(message: 'Failed to load categories'),
        ),
      );

      expect(
        () => ProductFormShared.loadCategories(repo),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

class _FakeCategoryRepository implements ICategoryRepository {
  _FakeCategoryRepository({required this.response});

  final ApiResponse<List<CategoryEntity>> response;

  @override
  Future<ApiResponse<List<CategoryEntity>>> getCategories() async {
    return response;
  }

  @override
  Future<ApiResponse<CategoryEntity>> getCategory(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<CategoryEntity>> createCategory({required String name}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<CategoryEntity>> updateCategory({required int id, required String name}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> deleteCategory(int id) {
    throw UnimplementedError();
  }
}
