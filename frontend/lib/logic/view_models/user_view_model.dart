import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repository_interfaces/i_user_repository.dart';

/// ViewModel for managing user profile state
/// Uses domain entities and repository interfaces
class UserViewModel extends ChangeNotifier {
  UserViewModel({
    required IUserRepository userRepository,
  }) : _userRepository = userRepository;

  final IUserRepository _userRepository;

  UserEntity? _profile;
  bool _isLoading = false;
  String? _error;

  UserEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get userId => _profile?.id;

  /// Loads current user profile and updates state for the bound views.
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _userRepository.getCurrentUser();
      if (response.isSuccess) {
        _profile = response.data;
      } else {
        _error = response.error?.message;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e, st) {
      _error = 'Unexpected error while loading profile.';
      debugPrint('UserViewModel.load unexpected error: $e\n$st');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load();
  }

  /// Uploads avatar and updates local profile cache on success.
  Future<String?> updateAvatar({
    required int userId,
    required String filePath,
  }) async {
    try {
      final response = await _userRepository.updateAvatarImage(
        userId: userId,
        filePath: filePath,
      );
      if (response.isSuccess) {
        // Reload profile to get updated data
        await load();
        return response.data;
      }
      return null;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e, st) {
      _error = 'Unexpected error while updating avatar.';
      debugPrint('UserViewModel.updateAvatar unexpected error: $e\n$st');
      return null;
    }
  }

  /// Uploads cover image and updates local profile cache on success.
  Future<String?> updateCover({
    required int userId,
    required String filePath,
  }) async {
    try {
      final response = await _userRepository.updateCoverImage(
        userId: userId,
        filePath: filePath,
      );
      if (response.isSuccess) {
        // Reload profile to get updated data
        await load();
        return response.data;
      }
      return null;
    } on ApiException catch (e) {
      _error = e.message;
      return null;
    } catch (e, st) {
      _error = 'Unexpected error while updating cover image.';
      debugPrint('UserViewModel.updateCover unexpected error: $e\n$st');
      return null;
    }
  }

  /// Resets user-bound state. Useful on logout.
  void clear() {
    _profile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
