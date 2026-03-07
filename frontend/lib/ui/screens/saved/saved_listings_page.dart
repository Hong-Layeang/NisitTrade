import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../../domain/repository_interfaces/i_user_repository.dart';
import '../../../domain/repository_interfaces/i_product_repository.dart';
import '../../../data/models/product.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../widgets/app_refresh_indicator.dart';
import '../../widgets/app_action_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_grid_card.dart';
import '../edit/edit_product_page.dart';
import '../marketplace/product_detail_page.dart';

final getIt = GetIt.instance;

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key});

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  late final IUserRepository _userRepository;
  late final IProductRepository _productRepository;
  List<Product> _savedProducts = [];
  bool _isLoading = false;
  String? _error;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _userRepository = getIt<IUserRepository>();
    _productRepository = getIt<IProductRepository>();
    _loadSavedListings();
  }

  Future<void> _loadSavedListings() async {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final savedResponse = await _userRepository.getUserSavedListings(
        userId: userId,
        limit: 50,
        offset: 0,
      );

      if (!savedResponse.isSuccess) {
        throw savedResponse.error!;
      }

      if (mounted) {
        setState(() {
          _savedProducts = (savedResponse.data ?? [])
              .map((entity) => Product.fromEntity(entity))
              .toList();
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeSaved(Product product) async {
    try {
      await context.read<ProductFeedViewModel>().unsaveListing(product.id);
      if (mounted) {
        setState(() {
          _savedProducts = _savedProducts
              .where((item) => item.id != product.id)
              .toList();
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove saved listing.')),
      );
    }
  }

  bool _isOwner(Product product) {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) return false;
    return product.userId == userId;
  }

  Future<void> _handleEditListing(Product product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: product),
      ),
    );

    // If edit was successful, refresh the saved listings
    if (result == true && mounted) {
      _loadSavedListings();
    }
  }

  Future<void> _handleDeleteListing(Product product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing'),
        content: const Text('Are you sure you want to delete this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      final response = await _productRepository.deleteProduct(product.id);
      if (!response.isSuccess) {
        throw response.error!;
      }

      if (mounted) {
        setState(() {
          _savedProducts = _savedProducts
              .where((item) => item.id != product.id)
              .toList();
        });
      }

      context.read<ProductFeedViewModel>().refresh();
      _showSnack('Listing deleted.');
    } catch (_) {
      _showSnack('Failed to delete listing.');
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  void _showOwnerActions(Product product) {
    if (!_isOwner(product)) return;

    AppActionSheet.show(
      context,
      title: 'Listing options',
      items: [
        AppActionSheetItem(
          label: 'Edit listing',
          icon: Icons.edit_outlined,
          onTap: () => _handleEditListing(product),
        ),
        AppActionSheetItem(
          label: 'Delete listing',
          icon: Icons.delete_outline,
          isDestructive: true,
          onTap: () => _handleDeleteListing(product),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    if (_savedProducts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.bookmark_border,
            title: 'No saved listings',
            subtitle: 'Save items to view them here.',
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _savedProducts.length,
      itemBuilder: (context, index) {
        final product = _savedProducts[index];
        return ProductGridCard(
          product: product,
          isLiked: false,
          onTap: () async {
            await Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: ProductDetailArgs(productId: product.id),
            );
            // Refresh saved products list when returning from detail page
            if (mounted) {
              _loadSavedListings();
            }
          },
          onLikeTap: () => _removeSaved(product),
          onLongPress: () => _showOwnerActions(product),
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Listings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${_error ?? 'Unknown error'}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSavedListings,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : AppRefreshIndicator(
                  onRefresh: _loadSavedListings,
                  child: _buildGrid(),
                ),
    );
  }
}

