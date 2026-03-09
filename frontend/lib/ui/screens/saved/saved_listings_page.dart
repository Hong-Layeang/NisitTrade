import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/product.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/saved_listings_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../widgets/app_refresh_indicator.dart';
import '../../widgets/app_action_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_error_builder.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/app_snack_bar.dart';
import '../edit/edit_product_page.dart';
import '../marketplace/product_detail_page.dart';

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key});

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage> {
  bool _didInitialLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedListings();
    });
  }

  Future<void> _loadSavedListings() async {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) return;
    await context.read<SavedListingsViewModel>().loadSavedListings(userId: userId);
    _didInitialLoad = true;
  }

  Future<void> _removeSaved(ProductEntity product) async {
    final ok = await context
        .read<SavedListingsViewModel>()
        .removeSavedListing(productId: product.id);

    if (!mounted) return;
    if (!ok) {
      _showSnack('Failed to remove saved listing.');
    }
  }

  bool _isOwner(ProductEntity product) {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) return false;
    return product.userId == userId;
  }

  Future<void> _handleEditListing(ProductEntity product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: Product.fromEntity(product)),
      ),
    );

    // If edit was successful, refresh the saved listings
    if (result == true && mounted) {
      _loadSavedListings();
    }
  }

  Future<void> _handleDeleteListing(ProductEntity product) async {
    final savedListingsVm = context.read<SavedListingsViewModel>();
    final productFeedVm = context.read<ProductFeedViewModel>();

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

    final ok = await savedListingsVm.deleteListing(productId: product.id);

    if (!mounted) return;
    if (ok) {
      productFeedVm.refresh();
      _showSnack('Listing deleted.');
    } else {
      _showSnack('Failed to delete listing.');
    }
  }

  void _showOwnerActions(ProductEntity product) {
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
    final savedProducts = context.watch<SavedListingsViewModel>().savedProducts;
    if (savedProducts.isEmpty) {
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
      itemCount: savedProducts.length,
      itemBuilder: (context, index) {
        final product = savedProducts[index];
        return ProductGridCard(
          key: ValueKey(product.id),
          product: product,
          isLiked: false,
          onTap: () async {
            await Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: ProductDetailArgs(
                productId: product.id,
                initialProduct: product,
              ),
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
    AppSnackBar.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SavedListingsViewModel>();

    if (!_didInitialLoad && !vm.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSavedListings();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Listings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
          body: LoadingErrorBuilder(
            isLoading: vm.isLoading,
            error: vm.error,
            onRetry: _loadSavedListings,
            isInitialLoad: !_didInitialLoad,
            child: AppRefreshIndicator(
              onRefresh: _loadSavedListings,
              child: _buildGrid(),
            ),
          ),
    );
  }
}

