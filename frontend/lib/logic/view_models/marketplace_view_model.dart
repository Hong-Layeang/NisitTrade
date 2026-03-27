import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../data/dtos/category_dto.dart';
import '../../data/repository_interfaces/i_category_repository.dart';

/// ViewModel for managing marketplace state and category filtering.
class MarketplaceViewModel extends ChangeNotifier {
  MarketplaceViewModel({
    required ICategoryRepository categoryRepository,
  }) : _categoryRepository = categoryRepository;

  final ICategoryRepository _categoryRepository;

  List<CategoryDto> _categories = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedCategoryIndex;
  bool _showCategoryFilter = false;

  List<CategoryDto> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedCategoryIndex => _selectedCategoryIndex;
  bool get showCategoryFilter => _showCategoryFilter;

  Future<void> loadCategories() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _categoryRepository.getCategories();
      if (!response.isSuccess) {
        throw response.error!;
      }

      // Keep entities, don't convert to models
      _categories = response.data ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadCategories();
  }

  void selectCategory(int? index) {
    _selectedCategoryIndex = index;
    notifyListeners();
  }

  void toggleCategoryFilter() {
    _showCategoryFilter = !_showCategoryFilter;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCategoryIndex = null;
    _showCategoryFilter = false;
    notifyListeners();
  }

  void clear() {
    _categories = [];
    _isLoading = false;
    _error = null;
    _selectedCategoryIndex = null;
    _showCategoryFilter = false;
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}

