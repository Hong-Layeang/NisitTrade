import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/utils/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../../models/product.dart';
import '../../../providers/product_feed_provider.dart';
import '../../../services/api/user_api_service.dart';
import '../../../data/repositories/product_repository.dart';
import '../common/app_action_sheet.dart';
import '../../screens/edit/edit_product_page.dart';
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
  int? _currentUserId;
  final UserApiService _userApiService = UserApiService.instance;
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
    _getCurrentUserId();
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

  Future<void> _getCurrentUserId() async {
    final response = await _userApiService.getCurrentUser();
    if (response.isSuccess && response.data != null) {
      setState(() {
        _currentUserId = response.data!.id;
      });
    }
  }

  bool _isProductLikedByCurrentUser() {
    if (_currentUserId == null) return false;
    return _product.likes.any((like) => like.userId == _currentUserId);
  }

  bool _isOwner() {
    if (_currentUserId == null) return false;
    return _product.userId == _currentUserId;
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
    if (_currentUserId == null || _isLoading) return;

    // Trigger animation
    _likeAnimationController.forward(from: 0.0);

    // Provide haptic feedback for modern feel
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    try {
      final isCurrentlyLiked = _isProductLikedByCurrentUser();

      if (isCurrentlyLiked) {
        // Find the like ID for current user
        try {
          final likeRecord = _product.likes.firstWhere(
            (like) => like.userId == _currentUserId,
          );

          await context.read<ProductFeedProvider>().unlikeProduct(
                productId: _product.id,
                likeId: likeRecord.id,
              );
          // Provide success haptic feedback
          HapticFeedback.mediumImpact();
          await _refreshProduct();
        } catch (e) {
          print('Error unliking product: $e');
        }
      } else {
        await context.read<ProductFeedProvider>().likeProduct(_product.id);
        // Provide success haptic feedback
        HapticFeedback.mediumImpact();
        await _refreshProduct();
      }
    } catch (e) {
      print('Like operation error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshProduct() async {
    try {
      final updatedProduct = await context
          .read<ProductFeedProvider>()
          .refreshProduct(_product.id);
      if (updatedProduct != null && mounted) {
        setState(() => _product = updatedProduct);
        widget.onProductUpdated?.call(_product);
      }
    } catch (e) {
      print('Error refreshing product: $e');
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
            ),
            Expanded(
              child: ProductCardImageCarousel(
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
            ProductCardActionRow(
              product: _product,
              isLiked: _isProductLikedByCurrentUser(),
              likeAnimationController: _likeAnimationController,
              onLikeTap: _handleLikeTap,
              onCommentTap: () {},
              onChatTap: () {},
            ),
            ProductCardInfo(product: _product),
          ],
        ),
      ),
    );
  }
}
