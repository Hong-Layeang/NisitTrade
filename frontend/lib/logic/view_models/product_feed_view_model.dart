import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../data/dtos/product_dto.dart';
import '../../data/repository_interfaces/i_product_repository.dart';
import '../../data/repository_interfaces/i_product_like_repository.dart';
import '../../data/repository_interfaces/i_product_save_repository.dart';
import '../../data/repository_interfaces/i_product_comment_repository.dart';
import '../../data/repository_interfaces/i_product_report_repository.dart';
import '../services/product_interaction_service.dart';

/// ViewModel for managing product feed state
/// Uses domain entities and repository interfaces
class ProductFeedViewModel extends ChangeNotifier {
  ProductFeedViewModel({
    required IProductRepository productRepository,
    required IProductLikeRepository likeRepository,
    required IProductSaveRepository saveRepository,
    required IProductCommentRepository commentRepository,
    required IProductReportRepository reportRepository,
  })  : _productRepository = productRepository,
        _interactionService = ProductInteractionService(
          productRepository: productRepository,
          likeRepository: likeRepository,
          saveRepository: saveRepository,
          commentRepository: commentRepository,
          reportRepository: reportRepository,
        );

  final IProductRepository _productRepository;
  final ProductInteractionService _interactionService;

  List<ProductDto> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  
  // Pagination state
  int _currentPage = 0;
  static const int _pageSize = 20;
  bool _hasMore = true;

  // Product cache for optimized navigation
  final Map<int, ProductDto> _productCache = {};

  List<ProductDto> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// Get a cached product by ID, returns null if not cached
  ProductDto? getCachedProduct(int productId) {
    return _productCache[productId];
  }

  Future<void> load() async {
    await loadFirstPage();
  }

  /// Load the first page of products
  Future<void> loadFirstPage({bool preserveExisting = false}) async {
    if (_isLoading) return;

    final keepCurrentProducts = preserveExisting && _products.isNotEmpty;

    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    _currentPage = 0;
    _hasMore = true;
    if (!keepCurrentProducts) {
      _products = [];
    }
    notifyListeners();

    try {
      final response = await _productRepository.getProducts(
        limit: _pageSize,
        offset: 0,
      );
      if (!response.isSuccess) {
        throw response.error!;
      }

      final loadedProducts = response.data ?? [];
      _products = loadedProducts;
      _hasMore = loadedProducts.length >= _pageSize;
      
      // Cache all loaded products
      for (final product in loadedProducts) {
        _productCache[product.id] = product;
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load the next page of products (for infinite scroll)
  Future<void> loadNextPage() async {
    if (_isLoadingMore || _isLoading || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final offset = _currentPage * _pageSize;

      final response = await _productRepository.getProducts(
        limit: _pageSize,
        offset: offset,
      );
      if (!response.isSuccess) {
        throw response.error!;
      }

      final loadedProducts = response.data ?? [];
      _products = [..._products, ...loadedProducts];
      _hasMore = loadedProducts.length >= _pageSize;
      
      // Cache all loaded products
      for (final product in loadedProducts) {
        _productCache[product.id] = product;
      }
    } on ApiException catch (e) {
      _error = e.message;
      _currentPage--; // Revert page increment on error
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh({bool preserveExisting = true}) async {
    await loadFirstPage(preserveExisting: preserveExisting);
  }

  Future<ProductDto?> refreshProduct(int productId) async {
    final product = await _interactionService.refreshProduct(productId);
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<ProductDto?> likeProduct(int productId) async {
    final product = await _interactionService.likeProduct(productId);
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<ProductDto?> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    final product = await _interactionService.unlikeProduct(
      productId: productId,
      likeId: likeId,
    );
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<ProductDto?> addComment({
    required int productId,
    required String content,
  }) async {
    final product = await _interactionService.addComment(
      productId: productId,
      content: content,
    );
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<ProductDto?> updateComment({
    required int productId,
    required int commentId,
    required String content,
  }) async {
    final product = await _interactionService.updateComment(
      productId: productId,
      commentId: commentId,
      content: content,
    );
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<ProductDto?> deleteComment({
    required int productId,
    required int commentId,
  }) async {
    final product = await _interactionService.deleteComment(
      productId: productId,
      commentId: commentId,
    );
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<ProductDto?> hideProduct(int productId) async {
    final product = await _interactionService.hideProduct(productId);
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<ProductDto?> unhideProduct(int productId) async {
    final product = await _interactionService.unhideProduct(productId);
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<void> saveListing(int productId) async {
    await _interactionService.saveListing(productId);
  }

  Future<void> unsaveListing(int productId) async {
    await _interactionService.unsaveListing(productId);
  }

  Future<String?> shareProduct(int productId) async {
    return _interactionService.shareProduct(productId);
  }

  Future<void> reportProduct({
    required int productId,
    required String reason,
    String? details,
  }) async {
    await _interactionService.reportProduct(
      productId: productId,
      reason: reason,
      details: details,
    );
  }

  /// Clears cached product state for auth/session transitions.
  void clear() {
    _products = [];
    _productCache.clear();
    _isLoading = false;
    _isLoadingMore = false;
    _error = null;
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();
  }

  void _upsertProduct(ProductDto product) {
    final existing = _productCache[product.id];
    final nextProduct = _withStableImageUrls(existing: existing, incoming: product);

    // Update cache
    _productCache[nextProduct.id] = nextProduct;
    
    final index = _products.indexWhere((item) => item.id == nextProduct.id);
    if (index == -1) {
      _products = [..._products, nextProduct];
    } else {
      final updated = [..._products];
      updated[index] = nextProduct;
      _products = updated;
    }
    notifyListeners();
  }

  ProductDto _withStableImageUrls({
    required ProductDto? existing,
    required ProductDto incoming,
  }) {
    if (existing == null) return incoming;
    if (existing.imageUrls.isEmpty || incoming.imageUrls.isEmpty) return incoming;
    if (existing.imageUrls.length != incoming.imageUrls.length) return incoming;

    final sameUnderlyingImages = _hasSameUnderlyingImageSet(
      existing.imageUrls,
      incoming.imageUrls,
    );
    if (!sameUnderlyingImages) return incoming;

    return incoming.copyWith(productImages: existing.productImages);
  }

  bool _hasSameUnderlyingImageSet(
    List<String> existingUrls,
    List<String> incomingUrls,
  ) {
    for (var i = 0; i < existingUrls.length; i++) {
      if (_normalizeImageUrl(existingUrls[i]) != _normalizeImageUrl(incomingUrls[i])) {
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
}

