import 'package:flutter/material.dart';

import '../data/repositories/product_repository.dart';
import '../models/product.dart';
import '../services/api/api_exception.dart';

class ProductFeedProvider extends ChangeNotifier {
  final ProductRepository _productRepository = ProductRepositoryImpl();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
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

  Future<Product?> refreshProduct(int productId) async {
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

  Future<Product?> likeProduct(int productId) async {
    final response = await _productRepository.likeProduct(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }

    // Fetch updated product and notify listeners so all pages stay in sync.
    // Individual cards (e.g. ProductCard) manage their own optimistic state,
    // so the rebuild is harmless for them.
    final fetchResponse = await _productRepository.getProduct(productId);
    if (!fetchResponse.isSuccess) {
      throw fetchResponse.error!;
    }

    final product = fetchResponse.data;
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<Product?> unlikeProduct({
    required int productId,
    required int likeId,
  }) async {
    final response = await _productRepository.unlikeProduct(
      productId: productId,
      likeId: likeId,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }

    // Fetch updated product and notify listeners so all pages stay in sync.
    final fetchResponse = await _productRepository.getProduct(productId);
    if (!fetchResponse.isSuccess) {
      throw fetchResponse.error!;
    }

    final product = fetchResponse.data;
    if (product != null) {
      _upsertProduct(product);
    }
    return product;
  }

  Future<Product?> addComment({
    required int productId,
    required String content,
  }) async {
    final response = await _productRepository.addComment(
      productId: productId,
      content: content,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }

    return refreshProduct(productId);
  }

  Future<Product?> hideProduct(int productId) async {
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

  Future<Product?> unhideProduct(int productId) async {
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
    final response = await _productRepository.saveListing(productId);
    if (!response.isSuccess) {
      throw response.error!;
    }
  }

  Future<void> unsaveListing(int productId) async {
    final response = await _productRepository.unsaveListing(productId);
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
    final response = await _productRepository.reportProduct(
      productId: productId,
      reason: reason,
      details: details,
    );
    if (!response.isSuccess) {
      throw response.error!;
    }
  }

  void _upsertProduct(Product product) {
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
