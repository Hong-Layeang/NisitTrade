import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/errors/api_response.dart';
import 'package:frontend/data/dtos/community_post_dto.dart';
import 'package:frontend/data/dtos/product_dto.dart';
import 'package:frontend/data/dtos/user_profile_dto.dart';
import 'package:frontend/data/repository_interfaces/i_user_repository.dart';
import 'package:frontend/logic/view_models/user_view_model.dart';

void main() {
  group('UserViewModel', () {
    test('load sets profile on success', () async {
      final repo = _FakeUserRepository(
        currentUserResponse: ApiResponse.success(_sampleUser(id: 7)),
      );
      final vm = UserViewModel(userRepository: repo);

      await vm.load();

      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
      expect(vm.profile?.id, 7);
      expect(repo.getCurrentUserCalls, 1);
    });

    test('load sets error on ApiException response', () async {
      final repo = _FakeUserRepository(
        currentUserResponse: ApiResponse.error(
          ApiException(message: 'Unauthorized'),
        ),
      );
      final vm = UserViewModel(userRepository: repo);

      await vm.load();

      expect(vm.profile, isNull);
      expect(vm.error, 'Unauthorized');
    });

    test('updateAvatar returns url and reloads profile on success', () async {
      final repo = _FakeUserRepository(
        currentUserResponse: ApiResponse.success(_sampleUser(id: 11)),
        updateAvatarResponse: ApiResponse.success('https://cdn/avatar.jpg'),
      );
      final vm = UserViewModel(userRepository: repo);

      final url = await vm.updateAvatar(
        userId: 11,
        filePath: '/tmp/avatar.jpg',
      );

      expect(url, 'https://cdn/avatar.jpg');
      expect(repo.lastAvatarUserId, 11);
      expect(repo.lastAvatarPath, '/tmp/avatar.jpg');
      expect(repo.getCurrentUserCalls, 1);
      expect(vm.profile?.id, 11);
    });
  });
}

class _FakeUserRepository implements IUserRepository {
  _FakeUserRepository({
    required this.currentUserResponse,
    ApiResponse<String>? updateAvatarResponse,
    ApiResponse<String>? updateCoverResponse,
  })  : _updateAvatarResponse = updateAvatarResponse ?? ApiResponse.success(''),
        _updateCoverResponse = updateCoverResponse ?? ApiResponse.success('');

    final ApiResponse<UserProfileDto> currentUserResponse;
  final ApiResponse<String> _updateAvatarResponse;
  final ApiResponse<String> _updateCoverResponse;

  int getCurrentUserCalls = 0;
  int? lastAvatarUserId;
  String? lastAvatarPath;

  @override
  Future<ApiResponse<UserProfileDto>> getCurrentUser() async {
    getCurrentUserCalls += 1;
    return currentUserResponse;
  }

  @override
  Future<ApiResponse<String>> updateAvatarImage({
    required int userId,
    required String filePath,
  }) async {
    lastAvatarUserId = userId;
    lastAvatarPath = filePath;
    return _updateAvatarResponse;
  }

  @override
  Future<ApiResponse<String>> updateCoverImage({
    required int userId,
    required String filePath,
  }) async {
    return _updateCoverResponse;
  }

  @override
  Future<ApiResponse<UserProfileDto>> getUserById(int userId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<ProductDto>>> getUserProducts({
    required int userId,
    int? limit,
    int? offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<ProductDto>>> getUserSavedListings({
    required int userId,
    int? limit,
    int? offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<UserProfileDto>>> getAllUsers({
    String? search,
    int? limit,
    int? offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<bool>> followUser(int userId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<bool>> unfollowUser(int userId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<CommunityPostDto>>> getUserSavedPosts({
    required int userId,
    int? limit,
    int? offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<UserProfileDto>> updateProfile({
    required int userId,
    required String fullName,
    String? bio,
    String? major,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> reportUser({
    required int userId,
    required String reason,
    String? details,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<bool>> blockUser(int userId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<bool>> unblockUser(int userId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<bool>> submitRating({
    required int sellerId,
    required int productId,
    required int rating,
    String? feedback,
  }) {
    throw UnimplementedError();
  }
}

UserProfileDto _sampleUser({required int id}) {
  final now = DateTime(2026, 3, 9);
  return UserProfileDto(
    id: id,
    fullName: 'Test User',
    email: 'test@example.com',
    role: 'user',
    createdAt: now,
    updatedAt: now,
  );
}

