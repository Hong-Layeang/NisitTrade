import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../data/dtos/user_profile_dto.dart';
import '../../data/repository_interfaces/i_user_repository.dart';

/// ViewModel for managing user profile state
/// Uses domain entities and repository interfaces
class UserViewModel extends ChangeNotifier {
  UserViewModel({
    required IUserRepository userRepository,
  }) : _userRepository = userRepository;

  final IUserRepository _userRepository;

  UserProfileDto? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfileDto? get profile => _profile;
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
        _profile = _withStableImageUrls(existing: _profile, incoming: response.data);
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

  /// Applies an optimistic delta to the current user's following count.
  void adjustFollowingCount({required bool increment}) {
    final profile = _profile;
    if (profile == null) return;

    final next = increment
        ? profile.followingCount + 1
        : (profile.followingCount > 0 ? profile.followingCount - 1 : 0);

    _profile = profile.copyWith(followingCount: next);
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String fullName,
    String? bio,
    String? major,
  }) async {
    final userId = _profile?.id;
    if (userId == null) {
      _error = 'Profile not loaded.';
      notifyListeners();
      return false;
    }

    try {
      final response = await _userRepository.updateProfile(
        userId: userId,
        fullName: fullName,
        bio: bio,
        major: major,
      );

      if (!response.isSuccess) {
        _error = response.error?.message ?? 'Failed to update profile.';
        notifyListeners();
        return false;
      }

      _profile = _withStableImageUrls(existing: _profile, incoming: response.data);
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e, st) {
      _error = 'Unexpected error while updating profile.';
      debugPrint('UserViewModel.updateProfile unexpected error: $e\n$st');
      notifyListeners();
      return false;
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
        final nextAvatarUrl = response.data;
        if (nextAvatarUrl != null && _profile != null) {
          _profile = _profile!.copyWith(profileImage: nextAvatarUrl);
          notifyListeners();
        }
        await refresh();
        return nextAvatarUrl;
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
        final nextCoverUrl = response.data;
        if (nextCoverUrl != null && _profile != null) {
          _profile = _profile!.copyWith(coverImage: nextCoverUrl);
          notifyListeners();
        }
        await refresh();
        return nextCoverUrl;
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

  UserProfileDto? _withStableImageUrls({
    required UserProfileDto? existing,
    required UserProfileDto? incoming,
  }) {
    if (existing == null || incoming == null) return incoming;

    final keepProfile = _isSameUnderlyingImage(
      existing.profileImage,
      incoming.profileImage,
    );
    final keepCover = _isSameUnderlyingImage(
      existing.coverImage,
      incoming.coverImage,
    );

    return incoming.copyWith(
      profileImage: keepProfile ? existing.profileImage : incoming.profileImage,
      coverImage: keepCover ? existing.coverImage : incoming.coverImage,
    );
  }

  bool _isSameUnderlyingImage(String? a, String? b) {
    if (a == null || b == null) return false;
    final aTrim = a.trim();
    final bTrim = b.trim();
    if (aTrim.isEmpty || bTrim.isEmpty) return false;
    return _normalizeImageUrl(aTrim) == _normalizeImageUrl(bTrim);
  }

  String _normalizeImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    if ((uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority) {
      return uri.replace(query: '', fragment: '').toString();
    }

    return url;
  }
}

