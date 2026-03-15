import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/community_post.dart';
import '../../data/repositories/community_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repository_interfaces/i_product_repository.dart';
import '../../domain/repository_interfaces/i_product_save_repository.dart';
import '../../domain/repository_interfaces/i_user_repository.dart';

/// ViewModel for managing saved listings state and actions.
class SavedListingsViewModel extends ChangeNotifier {
  SavedListingsViewModel({
    required IUserRepository userRepository,
    required IProductRepository productRepository,
    required IProductSaveRepository productSaveRepository,
    required CommunityRepository communityRepository,
  })  : _userRepository = userRepository,
        _productRepository = productRepository,
        _productSaveRepository = productSaveRepository,
        _communityRepository = communityRepository;

  final IUserRepository _userRepository;
  final IProductRepository _productRepository;
  final IProductSaveRepository _productSaveRepository;
  final CommunityRepository _communityRepository;

  List<ProductEntity> _savedProducts = [];
  List<CommunityPost> _savedPosts = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isActionLoading = false;
  String? _loadError;
  String? _actionError;
  int? _lastUserId;
  bool _hasLoadedForCurrentUser = false;

  List<ProductEntity> get savedProducts => _savedProducts;
  List<CommunityPost> get savedPosts => _savedPosts;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isActionLoading => _isActionLoading;
  String? get error => _loadError;
  String? get actionError => _actionError;

  bool hasLoadedForUser({required int userId}) {
    return _hasLoadedForCurrentUser && _lastUserId == userId;
  }

  bool hasSavedProduct(int productId) {
    return _savedProducts.any((item) => item.id == productId);
  }

  Future<void> ensureLoadedForUser({required int userId}) async {
    if (_hasLoadedForCurrentUser && _lastUserId == userId) {
      return;
    }

    await loadSavedListings(userId: userId);
  }

  Future<void> loadSavedListings({
    required int userId,
    bool showLoading = true,
  }) async {
    if (_isLoading || _isRefreshing) return;

    _lastUserId = userId;
    final shouldShowBlockingLoader =
        showLoading && !_hasLoadedForCurrentUser && _savedProducts.isEmpty && _savedPosts.isEmpty;

    if (shouldShowBlockingLoader) {
      _isLoading = true;
    } else {
      _isRefreshing = true;
    }

    _loadError = null;
    notifyListeners();

    try {
      final listingsResponse = await _userRepository.getUserSavedListings(
        userId: userId,
        limit: 50,
        offset: 0,
      );
      final postsResponse = await _userRepository.getUserSavedPosts(
        userId: userId,
        limit: 50,
        offset: 0,
      );

      if (!listingsResponse.isSuccess) {
        throw listingsResponse.error!;
      }

      if (!postsResponse.isSuccess) {
        throw postsResponse.error!;
      }

      final newProducts = _mergeSavedProducts(listingsResponse.data ?? []);
      final newPosts = postsResponse.data ?? [];

      _savedProducts = newProducts;
      _savedPosts = newPosts;
      _hasLoadedForCurrentUser = true;
    } on ApiException catch (e) {
      _loadError = e.message;
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_lastUserId != null) {
      await loadSavedListings(userId: _lastUserId!, showLoading: false);
    }
  }

  Future<bool> removeSavedListing({required int productId}) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    try {
      final response = await _productSaveRepository.unsaveListing(productId);
      if (!response.isSuccess) {
        throw response.error!;
      }

      _savedProducts = _savedProducts.where((item) => item.id != productId).toList();
      return true;
    } on ApiException catch (e) {
      _actionError = e.message;
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeSavedPost({required int postId}) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    try {
      final response = await _communityRepository.unsavePost(postId);
      if (!response.isSuccess) {
        throw response.error!;
      }

      _savedPosts = _savedPosts.where((item) => item.id != postId).toList();
      return true;
    } on ApiException catch (e) {
      _actionError = e.message;
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteListing({required int productId}) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _actionError = null;
    notifyListeners();

    try {
      final response = await _productRepository.deleteProduct(productId);
      if (!response.isSuccess) {
        throw response.error!;
      }

      _savedProducts = _savedProducts.where((item) => item.id != productId).toList();
      return true;
    } on ApiException catch (e) {
      _actionError = e.message;
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromListLocally({required int productId}) async {
    _savedProducts = _savedProducts.where((item) => item.id != productId).toList();
    notifyListeners();
  }

  void addSavedProductLocally(ProductEntity product) {
    if (_savedProducts.any((item) => item.id == product.id)) {
      return;
    }

    _savedProducts = [product, ..._savedProducts];
    notifyListeners();
  }

  void removeSavedProductLocally({required int productId}) {
    _savedProducts = _savedProducts.where((item) => item.id != productId).toList();
    notifyListeners();
  }

  void addSavedPostLocally(CommunityPost post) {
    if (_savedPosts.any((item) => item.id == post.id)) {
      return;
    }

    _savedPosts = [post, ..._savedPosts];
    notifyListeners();
  }

  void removeSavedPostLocally({required int postId}) {
    _savedPosts = _savedPosts.where((item) => item.id != postId).toList();
    notifyListeners();
  }

  List<ProductEntity> _mergeSavedProducts(List<ProductEntity> incomingProducts) {
    final existingById = {
      for (final product in _savedProducts) product.id: product,
    };

    return incomingProducts
        .map((incoming) => _withStableImageUrls(
              existing: existingById[incoming.id],
              incoming: incoming,
            ))
        .toList(growable: false);
  }

  ProductEntity _withStableImageUrls({
    required ProductEntity? existing,
    required ProductEntity incoming,
  }) {
    if (existing == null) return incoming;
    if (existing.imageUrls.isEmpty || incoming.imageUrls.isEmpty) return incoming;
    if (existing.imageUrls.length != incoming.imageUrls.length) return incoming;

    final sameUnderlyingImages = _hasSameUnderlyingImageSet(
      existing.imageUrls,
      incoming.imageUrls,
    );

    if (!sameUnderlyingImages) return incoming;

    return ProductEntity(
      id: incoming.id,
      title: incoming.title,
      description: incoming.description,
      price: incoming.price,
      status: incoming.status,
      userId: incoming.userId,
      categoryId: incoming.categoryId,
      createdAt: incoming.createdAt,
      updatedAt: incoming.updatedAt,
      seller: incoming.seller,
      category: incoming.category,
      imageUrls: existing.imageUrls,
      likes: incoming.likes,
      comments: incoming.comments,
      likeCount: incoming.likeCount,
      commentCount: incoming.commentCount,
      isLiked: incoming.isLiked,
    );
  }

  bool _hasSameUnderlyingImageSet(
    List<String> existingUrls,
    List<String> incomingUrls,
  ) {
    for (var index = 0; index < existingUrls.length; index++) {
      if (_normalizeImageUrl(existingUrls[index]) !=
          _normalizeImageUrl(incomingUrls[index])) {
        return false;
      }
    }

    return true;
  }

  String _normalizeImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;

    if ((uri.scheme == 'http' || uri.scheme == 'https') && uri.hasAuthority) {
      return uri.replace(query: '', fragment: '').toString();
    }

    return url;
  }

  void clear() {
    _savedProducts = [];
    _savedPosts = [];
    _isLoading = false;
    _isRefreshing = false;
    _isActionLoading = false;
    _loadError = null;
    _actionError = null;
    _lastUserId = null;
    _hasLoadedForCurrentUser = false;
    notifyListeners();
  }
}