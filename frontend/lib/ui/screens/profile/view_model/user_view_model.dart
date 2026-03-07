import 'package:flutter/material.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../domain/repository_interfaces/i_user_repository.dart';

class UserViewModel extends ChangeNotifier {
  UserViewModel({IUserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepositoryImpl();

  final IUserRepository _userRepository;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
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
        final entity = response.data;
        _profile = entity != null ? UserProfile.fromEntity(entity) : null;
      } else {
        _error = response.error?.message;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      // Ignore unknown errors to avoid crashing the UI tree.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
        _profile = _profile?.copyWith(profileImage: response.data);
        notifyListeners();
        return response.data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Uploads cover image and updates local profile cache on success.
  Future<String?> updateCover({
    required int userId,
    required String filePath,
  }) async {
    final response = await _userRepository.updateCoverImage(
      userId: userId,
      filePath: filePath,
    );
    if (response.isSuccess) {
      _profile = _profile?.copyWith(coverImage: response.data);
      notifyListeners();
      return response.data;
    }
    return null;
  }

  /// Resets user-bound state. Useful on logout.
  void clear() {
    _profile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
