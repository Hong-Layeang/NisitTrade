import 'package:flutter/material.dart';

import '../../data/repositories/user_repository.dart';
import '../../data/models/user_profile.dart';
import '../../core/errors/api_exception.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository;

  UserProvider({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepositoryImpl();

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get userId => _profile?.id;

  /// Fetch the current user from the server and notify listeners.
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
    } catch (_) {
      // Silently ignore other errors (e.g. network issues)
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload a new avatar image, update the cached profile, and notify listeners.
  /// Returns the new image URL on success, or null on failure.
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
    } catch (e) {
      return null;
    }
  }

  /// Upload a new cover image, update the cached profile, and notify listeners.
  /// Returns the new image URL on success, or null on failure.
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

  /// Clear the cached user data (call on logout).
  void clear() {
    _profile = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
