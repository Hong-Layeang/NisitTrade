import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/models/product.dart';
import '../../../logic/state_managers/product_feed_provider.dart';
import '../../../logic/state_managers/user_provider.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../widgets/common/app_refresh_indicator.dart';
import '../../widgets/common/app_action_sheet.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/product_grid_card.dart';
import '../edit/edit_product_page.dart';
import '../marketplace/product_detail_page.dart';

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key});

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  final UserRepository _userRepository = UserRepositoryImpl();
  final ProductRepository _productRepository = ProductRepositoryImpl();
  List<Product> _savedProducts = [];
  bool _isLoading = false;
  String? _error;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedListings();
  }

  Future<void> _loadSavedListings() async {
    final userId = context.read<UserProvider>().userId;
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
          _savedProducts = savedResponse.data ?? [];
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
      await context.read<ProductFeedProvider>().unsaveListing(product.id);
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
    final userId = context.read<UserProvider>().userId;
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

      context.read<ProductFeedProvider>().refresh();
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
