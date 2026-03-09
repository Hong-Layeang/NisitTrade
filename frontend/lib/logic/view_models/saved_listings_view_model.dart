import 'package:flutter/material.dart';

import '../../core/errors/api_exception.dart';
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
  })  : _userRepository = userRepository,
        _productRepository = productRepository,
        _productSaveRepository = productSaveRepository;

  final IUserRepository _userRepository;
  final IProductRepository _productRepository;
  final IProductSaveRepository _productSaveRepository;

  List<ProductEntity> _savedProducts = [];
  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _error;
  int? _lastUserId;

  List<ProductEntity> get savedProducts => _savedProducts;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get error => _error;

  Future<void> loadSavedListings({required int userId}) async {
    if (_isLoading) return;

    _lastUserId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _userRepository.getUserSavedListings(
        userId: userId,
        limit: 50,
        offset: 0,
      );

      if (!response.isSuccess) {
        throw response.error!;
      }

      // Keep entities, don't convert to models
      _savedProducts = response.data ?? [];
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_lastUserId != null) {
      await loadSavedListings(userId: _lastUserId!);
    }
  }

  Future<bool> removeSavedListing({required int productId}) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _productSaveRepository.unsaveListing(productId);
      if (!response.isSuccess) {
        throw response.error!;
      }

      _savedProducts = _savedProducts.where((item) => item.id != productId).toList();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteListing({required int productId}) async {
    if (_isActionLoading) return false;

    _isActionLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _productRepository.deleteProduct(productId);
      if (!response.isSuccess) {
        throw response.error!;
      }

      _savedProducts = _savedProducts.where((item) => item.id != productId).toList();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
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

  void clear() {
    _savedProducts = [];
    _isLoading = false;
    _isActionLoading = false;
    _error = null;
    _lastUserId = null;
    notifyListeners();
  }
}