import 'package:flutter/material.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repository_interfaces/i_category_repository.dart';
import '../../domain/repository_interfaces/i_user_repository.dart';

/// ViewModel for managing search state and filtering logic.
class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required ICategoryRepository categoryRepository,
    required IUserRepository userRepository,
  })  : _categoryRepository = categoryRepository,
        _userRepository = userRepository;

  final ICategoryRepository _categoryRepository;
  final IUserRepository _userRepository;

  List<CategoryEntity> _categories = [];
  List<UserEntity> _users = [];
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _error;

  // Search state
  String _searchQuery = '';
  int? _selectedCategoryIndex;
  bool _showUserSearch = false;
  bool _showCategoryFilter = false;

  List<CategoryEntity> get categories => _categories;
  List<UserEntity> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryIndex => _selectedCategoryIndex;
  bool get showUserSearch => _showUserSearch;
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

      _categories = response.data ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await Future.wait([
      loadCategories(),
      if (_showUserSearch) loadUsers(),
    ]);
  }

  Future<void> loadUsers() async {
    if (_isLoadingUsers) return;

    _isLoadingUsers = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _userRepository.getAllUsers(limit: 100);

      if (!response.isSuccess) {
        throw response.error!;
      }

      _users = (response.data ?? []).cast<UserEntity>();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(int? index) {
    if (_selectedCategoryIndex == index) return;
    _selectedCategoryIndex = index;
    notifyListeners();
  }

  void toggleUserSearch(bool show) {
    if (_showUserSearch == show) return;
    _showUserSearch = show;
    notifyListeners();

    if (show && _users.isEmpty && !_isLoadingUsers) {
      loadUsers();
    }
  }

  void toggleCategoryFilter() {
    _showCategoryFilter = !_showCategoryFilter;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _selectedCategoryIndex = null;
    _showUserSearch = false;
    _showCategoryFilter = false;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }

  void clear() {
    _categories = [];
    _users = [];
    _isLoading = false;
    _isLoadingUsers = false;
    _error = null;
    _searchQuery = '';
    _selectedCategoryIndex = null;
    _showUserSearch = false;
    _showCategoryFilter = false;
  }
}
