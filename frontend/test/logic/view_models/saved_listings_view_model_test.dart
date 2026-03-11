import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/errors/api_exception.dart';
import 'package:frontend/core/errors/api_response.dart';
import 'package:frontend/data/models/community_post.dart';
import 'package:frontend/data/repositories/community_repository_impl.dart';
import 'package:frontend/domain/entities/product_entity.dart';
import 'package:frontend/domain/entities/user_entity.dart';
import 'package:frontend/domain/repository_interfaces/i_product_repository.dart';
import 'package:frontend/domain/repository_interfaces/i_product_save_repository.dart';
import 'package:frontend/domain/repository_interfaces/i_user_repository.dart';
import 'package:frontend/logic/view_models/saved_listings_view_model.dart';

void main() {
  group('SavedListingsViewModel', () {
    test('loadSavedListings populates products on success', () async {
      final userRepo = _FakeUserRepository(
        savedListingsResponse: ApiResponse.success([_sampleProductEntity(id: 1)]),
      );
      final productRepo = _FakeProductRepository();
      final saveRepo = _FakeProductSaveRepository();
      final communityRepo = _FakeCommunityRepository();
      final vm = SavedListingsViewModel(
        userRepository: userRepo,
        productRepository: productRepo,
        productSaveRepository: saveRepo,
        communityRepository: communityRepo,
      );

      await vm.loadSavedListings(userId: 99);

      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
      expect(vm.savedProducts.length, 1);
      expect(vm.savedProducts.first.id, 1);
      expect(userRepo.lastSavedListingsUserId, 99);
    });

    test('removeSavedListing removes item when unsave succeeds', () async {
      final userRepo = _FakeUserRepository(
        savedListingsResponse: ApiResponse.success([
          _sampleProductEntity(id: 1),
          _sampleProductEntity(id: 2),
        ]),
      );
      final productRepo = _FakeProductRepository();
      final saveRepo = _FakeProductSaveRepository(
        unsaveResponse: ApiResponse.success(null),
      );
      final communityRepo = _FakeCommunityRepository();
      final vm = SavedListingsViewModel(
        userRepository: userRepo,
        productRepository: productRepo,
        productSaveRepository: saveRepo,
        communityRepository: communityRepo,
      );

      await vm.loadSavedListings(userId: 99);
      final ok = await vm.removeSavedListing(productId: 1);

      expect(ok, isTrue);
      expect(vm.error, isNull);
      expect(vm.savedProducts.length, 1);
      expect(vm.savedProducts.first.id, 2);
      expect(saveRepo.lastUnsaveProductId, 1);
    });

    test('deleteListing returns false and exposes error when API fails', () async {
      final userRepo = _FakeUserRepository(
        savedListingsResponse: ApiResponse.success([_sampleProductEntity(id: 1)]),
      );
      final productRepo = _FakeProductRepository(
        deleteResponse: ApiResponse.error(
          ApiException(message: 'Delete failed on server'),
        ),
      );
      final saveRepo = _FakeProductSaveRepository();
      final communityRepo = _FakeCommunityRepository();
      final vm = SavedListingsViewModel(
        userRepository: userRepo,
        productRepository: productRepo,
        productSaveRepository: saveRepo,
        communityRepository: communityRepo,
      );

      await vm.loadSavedListings(userId: 99);
      final ok = await vm.deleteListing(productId: 1);

      expect(ok, isFalse);
      expect(vm.actionError, 'Delete failed on server');
      expect(vm.savedProducts.length, 1);
      expect(productRepo.lastDeleteProductId, 1);
    });
  });
}

ProductEntity _sampleProductEntity({required int id}) {
  final now = DateTime(2026, 1, 1);
  return ProductEntity(
    id: id,
    title: 'Product $id',
    description: 'Description $id',
    price: 10.0,
    status: ProductStatus.available,
    userId: 7,
    categoryId: 3,
    createdAt: now,
    updatedAt: now,
    imageUrls: const ['https://example.com/item.jpg'],
  );
}

class _FakeUserRepository implements IUserRepository {
  _FakeUserRepository({
    required this.savedListingsResponse,
    ApiResponse<List<CommunityPost>>? savedPostsResponse,
  }) : _savedPostsResponse = savedPostsResponse ?? ApiResponse.success(const []);

  final ApiResponse<List<CommunityPost>> _savedPostsResponse;

  final ApiResponse<List<ProductEntity>> savedListingsResponse;
  int? lastSavedListingsUserId;

  @override
  Future<ApiResponse<List<ProductEntity>>> getUserSavedListings({
    required int userId,
    int? limit,
    int? offset,
  }) async {
    lastSavedListingsUserId = userId;
    return savedListingsResponse;
  }

  @override
  Future<ApiResponse<UserEntity>> getCurrentUser() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<UserEntity>> getUserById(int userId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<ProductEntity>>> getUserProducts({
    required int userId,
    int? limit,
    int? offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<UserEntity>>> getAllUsers({
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
  Future<ApiResponse<String>> updateCoverImage({
    required int userId,
    required String filePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<String>> updateAvatarImage({
    required int userId,
    required String filePath,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<CommunityPost>>> getUserSavedPosts({
    required int userId,
    int? limit,
    int? offset,
  }) async {
    return _savedPostsResponse;
  }

  @override
  Future<ApiResponse<UserEntity>> updateProfile({
    required int userId,
    required String fullName,
    String? bio,
    String? major,
  }) {
    throw UnimplementedError();
  }
}

class _FakeProductRepository implements IProductRepository {
  _FakeProductRepository({
    ApiResponse<void>? deleteResponse,
  }) : _deleteResponse = deleteResponse ?? ApiResponse.success(null);

  final ApiResponse<void> _deleteResponse;
  int? lastDeleteProductId;

  @override
  Future<ApiResponse<void>> deleteProduct(int id) async {
    lastDeleteProductId = id;
    return _deleteResponse;
  }

  @override
  Future<ApiResponse<List<ProductEntity>>> getProducts({
    int? categoryId,
    String? status,
    String? search,
    int? limit,
    int? offset,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<ProductEntity>> getProduct(int id) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<ProductEntity>> createProduct({
    required String title,
    String? description,
    required double price,
    required int categoryId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<ProductEntity>> updateProduct({
    required int id,
    String? title,
    String? description,
    double? price,
    int? categoryId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<ProductEntity>> updateProductStatus({
    required int id,
    required String status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<ProductEntity>> hideProduct(int productId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<ProductEntity>> unhideProduct(int productId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<String>> shareProduct(int productId) {
    throw UnimplementedError();
  }
}

class _FakeProductSaveRepository implements IProductSaveRepository {
  _FakeProductSaveRepository({
    ApiResponse<void>? saveResponse,
    ApiResponse<void>? unsaveResponse,
  })  : _saveResponse = saveResponse ?? ApiResponse.success(null),
        _unsaveResponse = unsaveResponse ?? ApiResponse.success(null);

  final ApiResponse<void> _saveResponse;
  final ApiResponse<void> _unsaveResponse;
  int? lastUnsaveProductId;

  @override
  Future<ApiResponse<void>> saveListing(int productId) async {
    return _saveResponse;
  }

  @override
  Future<ApiResponse<void>> unsaveListing(int productId) async {
    lastUnsaveProductId = productId;
    return _unsaveResponse;
  }
}

class _FakeCommunityRepository implements CommunityRepository {
  _FakeCommunityRepository({
    ApiResponse<void>? unsaveResponse,
  }) : _unsaveResponse = unsaveResponse ?? ApiResponse.success(null);

  final ApiResponse<void> _unsaveResponse;

  @override
  Future<ApiResponse<void>> unsavePost(int postId) async => _unsaveResponse;

  @override
  Future<ApiResponse<void>> addComment({required int postId, required String content}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<CommunityPost>> createPost({required String content, List<String> imagePaths = const []}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> deleteComment({required int postId, required int commentId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> deletePost(int postId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<CommunityPost>> getPost(int postId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<List<CommunityPost>>> getPosts({
    String feed = 'community',
    int limit = 20,
    int offset = 0,
    int? userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> likePost(int postId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> reportPost({required int postId, required String reason, String? details}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> savePost(int postId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> unlikePost(int postId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> updateComment({required int postId, required int commentId, required String content}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResponse<void>> updatePost({required int postId, required String content, List<String> imagePaths = const [], List<String> retainedImageUrls = const []}) {
    throw UnimplementedError();
  }
}