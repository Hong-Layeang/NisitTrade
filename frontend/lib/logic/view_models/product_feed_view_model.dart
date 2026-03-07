import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repository_interfaces/i_product_repository.dart';
import '../../domain/repository_interfaces/i_product_like_repository.dart';
import '../../domain/repository_interfaces/i_product_save_repository.dart';
import '../../domain/repository_interfaces/i_product_comment_repository.dart';
import '../../domain/repository_interfaces/i_product_report_repository.dart';

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
        _likeRepository = likeRepository,
        _saveRepository = saveRepository,
        _commentRepository = commentRepository,
        _reportRepository = reportRepository;

  final IProductRepository _productRepository;
  final IProductLikeRepository _likeRepository;
  final IProductSaveRepository _saveRepository;
  final IProductCommentRepository _commentRepository;
  final IProductReportRepository _reportRepository;

  List<ProductEntity> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductEntity> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _productRepository.getProducts();
      if (!response.isSuccess) {
        throw response.error!;
      }

      _products = response.data ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<ProductEntity?> refreshProduct(int productId) async {
    final response = await _productRepository.getProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }

    final product = response.data;
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<ProductEntity?> likeProduct(int productId) async {
    final response = await _likeRepository.likeProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }

    return refreshProduct(productId);
  }

  Future<ProductEntity?> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    final response = await _likeRepository.unlikeProduct(
      productId: productId,
      likeId: likeId,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }

    return refreshProduct(productId);
  }

  Future<ProductEntity?> addComment({
    required int productId,
    required String content,
  }) async {
    final response = await _commentRepository.addComment(
      productId: productId,
      content: content,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }

    return refreshProduct(productId);
  }

  Future<ProductEntity?> hideProduct(int productId) async {
    final response = await _productRepository.hideProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }

    final product = response.data;
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<ProductEntity?> unhideProduct(int productId) async {
    final response = await _productRepository.unhideProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }

    final product = response.data;
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<void> saveListing(int productId) async {
    final response = await _saveRepository.saveListing(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
  }

  Future<void> unsaveListing(int productId) async {
    final response = await _saveRepository.unsaveListing(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
  }

  Future<String?> shareProduct(int productId) async {
    final response = await _productRepository.shareProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
    return response.data;
  }

  Future<void> reportProduct({
    required int productId,
    required String reason,
    String? details,
  }) async {
    final response = await _reportRepository.reportProduct(
      productId: productId,
      reason: reason,
      details: details,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }
  }

  /// Clears cached product state for auth/session transitions.
  void clear() {
    _products = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _upsertProduct(ProductEntity product) {
    final index = _products.indexWhere((item) => item.id == product.id);
    if (index == -1) {
      _products = [..._products, product];
    } else {
      final updated = [..._products];
      updated[index] = product;
      _products = updated;
    }
    notifyListeners();
  }
}
