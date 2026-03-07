import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/utils/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../../models/like.dart';
import '../../../models/product.dart';
import '../../../providers/product_feed_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/repositories/product_repository.dart';
import '../common/app_action_sheet.dart';
import '../../screens/edit/edit_product_page.dart';
import '../../screens/marketplace/product_detail_page.dart';
import '../../screens/profile/other_profile_page.dart';
import '../../../utils/routes/app_routes.dart';
import 'product_card_action_row.dart';
import 'product_card_image_carousel.dart';
import 'product_card_info.dart';
import 'product_card_seller_header.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final Function(Product)? onProductUpdated;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onProductUpdated,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  late PageController _pageController;
  late AnimationController _likeAnimationController;
  late Product _product;
  bool _isLoading = false;
  bool _isActionLoading = false;
  final ProductRepository _productRepository = ProductRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _product = widget.product;
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always sync with the parent's product if it's a different instance
    // This ensures we get the latest state from the parent, including any like changes
    if (oldWidget.product != widget.product) {
      _product = widget.product;
    }
  }

  Future<void> _handleCommentTap() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: ProductDetailArgs(
        productId: _product.id,
        focusComments: true,
      ),
    );
    if (!mounted) return;
    await context.read<ProductFeedProvider>().refreshProduct(_product.id);
  }

  int? _findCurrentUserLikeId() {
    final userId = context.read<UserProvider>().userId;
    if (userId == null) return null;

    for (final like in _product.likes) {
      if (like.userId == userId) {
        return like.id;
      }
    }
    return null;
  }

  Product _buildOptimisticLikeProduct({required bool willBeLiked}) {
    final now = DateTime.now();
    final userId = context.read<UserProvider>().userId;

    if (willBeLiked) {
      if (userId == null) return _product;

      final likes = List<Like>.from(_product.likes)
        ..add(
          Like(
            id: -now.microsecondsSinceEpoch,
            userId: userId,
            productId: _product.id,
            createdAt: now,
            updatedAt: now,
          ),
        );

      return _product.copyWith(likes: likes, updatedAt: now);
    }

    if (userId == null) return _product;

    final likes = _product.likes.where((like) => like.userId != userId).toList();
    return _product.copyWith(likes: likes, updatedAt: now);
  }

  bool _isProductLikedByCurrentUser() {
    final userId = context.read<UserProvider>().userId;
    if (userId == null) return false;
    return _product.likes.any((like) => like.userId == userId);
  }

  bool _isOwner() {
    final userId = context.read<UserProvider>().userId;
    if (userId == null) return false;
    return _product.userId == userId;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleSaveListing() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      await context.read<ProductFeedProvider>().saveListing(_product.id);
      _showSnack('Saved to your list.');
    } catch (e) {
      _showSnack('Failed to save listing.');
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleEditListing() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: _product),
      ),
    );

    // If edit was successful, refresh product feed
    if (result == true && mounted) {
      context.read<ProductFeedProvider>().refresh();
    }
  }

  Future<void> _handleDeleteListing() async {
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
      final response = await _productRepository.deleteProduct(_product.id);
      if (!response.isSuccess) {
        throw response.error!;
      }

      if (mounted) {
        context.read<ProductFeedProvider>().refresh();
      }

      _showSnack('Listing deleted.');
    } catch (_) {
      _showSnack('Failed to delete listing.');
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleHideToggle() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      final wasHidden = _product.isHidden;
      final provider = context.read<ProductFeedProvider>();
      final updated = wasHidden
          ? await provider.unhideProduct(_product.id)
          : await provider.hideProduct(_product.id);

      if (updated != null && mounted) {
        setState(() => _product = updated);
        widget.onProductUpdated?.call(updated);
      }

      _showSnack(wasHidden ? 'Listing unhidden.' : 'Listing hidden.');
    } catch (e) {
      _showSnack('Failed to update listing visibility.');
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleShareListing() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      final shareUrl = await context.read<ProductFeedProvider>().shareProduct(_product.id);
      if (shareUrl != null && shareUrl.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: shareUrl));
        _showSnack('Share link copied to clipboard.');
      } else {
        _showSnack('Failed to get share link.');
      }
    } catch (e) {
      _showSnack('Failed to get share link.');
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleReportListing() async {
    final reasonController = TextEditingController();
    final detailsController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Details (optional)'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (shouldSubmit != true) return;

    final reason = reasonController.text.trim();
    final details = detailsController.text.trim();

    if (reason.isEmpty) {
      _showSnack('Reason is required.');
      return;
    }

    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      if (!mounted) return;
      await context.read<ProductFeedProvider>().reportProduct(
            productId: _product.id,
            reason: reason,
            details: details.isEmpty ? null : details,
          );
      _showSnack('Report submitted.');
    } catch (e) {
      _showSnack('Failed to submit report.');
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  void _showProductActions() {
    final isOwner = _isOwner();
    final items = <AppActionSheetItem>[
      if (isOwner)
        AppActionSheetItem(
          label: 'Edit listing',
          icon: Icons.edit_outlined,
          onTap: _handleEditListing,
        ),
      if (isOwner)
        AppActionSheetItem(
          label: 'Delete listing',
          icon: Icons.delete_outline,
          isDestructive: true,
          onTap: _handleDeleteListing,
        ),
      AppActionSheetItem(
        label: 'Save listing',
        icon: Icons.bookmark_border,
        onTap: _handleSaveListing,
      ),
      if (isOwner)
        AppActionSheetItem(
          label: _product.isHidden ? 'Unhide listing' : 'Hide listing',
          icon: Icons.visibility_off_outlined,
          onTap: _handleHideToggle,
        ),
      AppActionSheetItem(
        label: 'Share',
        icon: Icons.share_outlined,
        onTap: _handleShareListing,
      ),
      AppActionSheetItem(
        label: 'Report',
        icon: Icons.flag_outlined,
        isDestructive: true,
        onTap: _handleReportListing,
      ),
    ];

    AppActionSheet.show(
      context,
      title: 'Listing options',
      items: items,
    );
  }

  Future<void> _handleLikeTap() async {
    if (_isLoading) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (context.read<UserProvider>().userId == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Unable to load your account. Please try again.')),
      );
      return;
    }

    // Trigger animation
    _likeAnimationController.forward(from: 0.0);

    // Provide haptic feedback for modern feel
    HapticFeedback.lightImpact();

    final previousProduct = _product;
    setState(() => _isLoading = true);

    try {
      final provider = context.read<ProductFeedProvider>();
      final isCurrentlyLiked = _isProductLikedByCurrentUser();
      final unlikeLikeId = isCurrentlyLiked ? _findCurrentUserLikeId() : null;

      final optimisticProduct = _buildOptimisticLikeProduct(
        willBeLiked: !isCurrentlyLiked,
      );
      if (mounted) {
        setState(() => _product = optimisticProduct);
        widget.onProductUpdated?.call(_product);
      }

      Product? updatedProduct;

      if (isCurrentlyLiked) {
        var likeId = unlikeLikeId;

        if (likeId == null) {
          final refreshed = await provider.refreshProduct(_product.id);
          if (refreshed != null && mounted) {
            setState(() => _product = refreshed);
          }
          likeId = _findCurrentUserLikeId();
        }

        if (likeId == null) {
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Unable to find your like. Please try again.')),
            );
          }
        } else {
          updatedProduct = await provider.unlikeProduct(
            productId: _product.id,
            likeId: likeId,
          );
        }
      } else {
        updatedProduct = await provider.likeProduct(_product.id);
      }

      if (updatedProduct != null && mounted) {
        setState(() => _product = updatedProduct!);
        widget.onProductUpdated?.call(_product);
      } else {
        final refreshed = await provider.refreshProduct(_product.id);
        if (refreshed != null && mounted) {
          setState(() => _product = refreshed);
          widget.onProductUpdated?.call(_product);
        }
      }

      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Like operation error: $e');
      if (mounted) {
        setState(() => _product = previousProduct);
        widget.onProductUpdated?.call(_product);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Failed to update like. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductCardSellerHeader(
              product: _product,
              onMoreTap: _showProductActions,
              onSellerTap: () => Navigator.pushNamed(
                context,
                AppRoutes.userProfile,
                arguments: OtherProfileArgs(userId: _product.userId),
              ),
            ),
            Expanded(
              child: RepaintBoundary(
                child: ProductCardImageCarousel(
                  key: ValueKey(_product.id),
                  images: _product.imageUrls,
                  currentIndex: _currentImageIndex,
                  pageController: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                ),
              ),
            ),
            _ProductCardActionSection(
              product: _product,
              isLiked: _isProductLikedByCurrentUser(),
              likeAnimationController: _likeAnimationController,
              onLikeTap: _handleLikeTap,
              onCommentTap: _handleCommentTap,
              onProductUpdated: (updated) {
                setState(() => _product = updated);
                widget.onProductUpdated?.call(updated);
              },
            ),
            ProductCardInfo(product: _product),
          ],
        ),
      ),
    );
  }
}

/// Separate widget for action row to prevent image carousel rebuilds
class _ProductCardActionSection extends StatelessWidget {
  final Product product;
  final bool isLiked;
  final AnimationController likeAnimationController;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final Function(Product) onProductUpdated;

  const _ProductCardActionSection({
    required this.product,
    required this.isLiked,
    required this.likeAnimationController,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onProductUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return ProductCardActionRow(
      product: product,
      isLiked: isLiked,
      likeAnimationController: likeAnimationController,
      onLikeTap: onLikeTap,
      onCommentTap: onCommentTap,
      onChatTap: () {},
    );
  }
}
