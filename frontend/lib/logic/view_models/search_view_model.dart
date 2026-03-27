import 'package:flutter/material.dart';
import '../../core/errors/app_error_messages.dart';
import '../../core/errors/api_exception.dart';
import '../../data/dtos/category_dto.dart';
import '../../data/dtos/user_profile_dto.dart';
import '../../data/repository_interfaces/i_category_repository.dart';
import '../../data/repository_interfaces/i_user_repository.dart';

/// ViewModel for managing search state and filtering logic.
class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required ICategoryRepository categoryRepository,
    required IUserRepository userRepository,
  })  : _categoryRepository = categoryRepository,
        _userRepository = userRepository;

  final ICategoryRepository _categoryRepository;
  final IUserRepository _userRepository;

  List<CategoryDto> _categories = [];
  List<UserProfileDto> _users = [];
  final Set<int> _updatingFollowUserIds = <int>{};
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _loadError;
  String? _actionError;

  // Search state
  String _searchQuery = '';
  int? _selectedCategoryIndex;
  bool _showUserSearch = false;
  bool _showCategoryFilter = false;

  List<CategoryDto> get categories => _categories;
  List<UserProfileDto> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  Set<int> get updatingFollowUserIds => _updatingFollowUserIds;
  String? get error => _loadError;
  String? get actionError => _actionError;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryIndex => _selectedCategoryIndex;
  bool get showUserSearch => _showUserSearch;
  bool get showCategoryFilter => _showCategoryFilter;

  Future<void> loadCategories() async {
    if (_isLoading) return;

    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final response = await _categoryRepository.getCategories();
      if (!response.isSuccess) {
        throw response.error!;
      }

      _categories = response.data ?? [];
    } on ApiException catch (e) {
      _loadError = e.message;
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
    _loadError = null;
    notifyListeners();

    try {
      final response = await _userRepository.getAllUsers(limit: 100);

      if (!response.isSuccess) {
        throw response.error!;
      }

      _users = response.data ?? [];
    } on ApiException catch (e) {
      _loadError = e.message;
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFollow(int userId) async {
    if (_updatingFollowUserIds.contains(userId)) return false;

    final index = _users.indexWhere((user) => user.id == userId);
    if (index == -1) {
      _actionError = 'User not found.';
      notifyListeners();
      return false;
    }

    final currentUser = _users[index];
    final nextIsFollowing = !currentUser.isFollowing;
    final nextFollowerCount = nextIsFollowing
        ? currentUser.followerCount + 1
        : (currentUser.followerCount > 0 ? currentUser.followerCount - 1 : 0);

    _actionError = null;
    _updatingFollowUserIds.add(userId);
    _users[index] = currentUser.copyWith(
      isFollowing: nextIsFollowing,
      followerCount: nextFollowerCount,
    );
    notifyListeners();

    try {
      final response = nextIsFollowing
          ? await _userRepository.followUser(userId)
          : await _userRepository.unfollowUser(userId);

      if (!response.isSuccess) {
        throw response.error ??
            ApiException(
              message: nextIsFollowing
                  ? 'Failed to follow user.'
                  : 'Failed to unfollow user.',
            );
      }

      return true;
    } on ApiException catch (e) {
      if (nextIsFollowing && AppErrorMessages.isAlreadyFollowingMessage(e)) {
        _actionError = null;
        return true;
      }

      if (!nextIsFollowing && AppErrorMessages.isNotFollowingMessage(e)) {
        _actionError = null;
        return true;
      }

      _users[index] = currentUser;
      _actionError = e.message;
      return false;
    } catch (_) {
      _users[index] = currentUser;
      _actionError = nextIsFollowing
          ? 'Failed to follow user.'
          : 'Failed to unfollow user.';
      return false;
    } finally {
      _updatingFollowUserIds.remove(userId);
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

    if (show && !_isLoadingUsers) {
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
    _updatingFollowUserIds.clear();
    _isLoading = false;
    _isLoadingUsers = false;
    _loadError = null;
    _actionError = null;
    _searchQuery = '';
    _selectedCategoryIndex = null;
    _showUserSearch = false;
    _showCategoryFilter = false;
  }
}

