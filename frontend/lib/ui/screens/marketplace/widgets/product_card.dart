import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/constants/colors.dart';
import 'package:frontend/core/constants/app_durations.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/product.dart';
import '../../../../domain/entities/product_entity.dart';
import 'package:get_it/get_it.dart';
import '../../../../logic/helpers/product_like_helpers.dart';
import '../../../../logic/view_models/product_feed_view_model.dart';
import '../../../../logic/view_models/saved_listings_view_model.dart';
import '../../../../logic/view_models/chat_view_model.dart';

import '../../../../logic/view_models/user_view_model.dart';
import '../../../../domain/repository_interfaces/i_product_repository.dart';
import '../../edit/edit_product_page.dart';
import '../product_detail_page.dart';
import '../../profile/other_profile_page.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../widgets/app_snack_bar.dart';
import 'product_card_action_row.dart';
import 'product_card_image_carousel.dart';
import 'product_card_info.dart';
import 'product_card_seller_header.dart';
import 'product_card_action_handler.dart';
import '../../../../logic/services/share_service.dart';

final getIt = GetIt.instance;

/// ProductCard displays a product in the marketplace feed.
class ProductCard extends StatefulWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final Function(ProductEntity)? onProductUpdated;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onProductUpdated,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
  with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  static const List<String> _reportReasonOptions = [
    'Spam or scam',
    'Prohibited or illegal item',
    'Counterfeit item',
    'Misleading description',
    'Inappropriate content',
    'Other',
  ];

  int _currentImageIndex = 0;
  late PageController _pageController;
  late AnimationController _likeAnimationController;
  late ProductEntity _product;
  bool _isLoading = false;
  bool _isActionLoading = false;
  late IProductRepository _productRepository;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _productRepository = getIt<IProductRepository>();
    _pageController = PageController();
    _likeAnimationController = AnimationController(
      duration: AppDurations.slow,
      vsync: this,
    );
    _product = widget.product;
  }

  @override
  void didUpdateWidget(ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product != widget.product) {
      // Reset carousel only if it's a different product
      if (oldWidget.product.id != widget.product.id) {
        if (mounted) {
          setState(() {
            _currentImageIndex = 0;
            _product = widget.product;
          });
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        }
      } else {
        final imagesChanged = oldWidget.product.imageUrls != widget.product.imageUrls;
        if (imagesChanged && mounted) {
          setState(() => _product = widget.product);
        } else {
          _product = widget.product;
        }
      }
    }
  }

  Future<void> _handleCommentTap() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: ProductDetailArgs(
        productId: _product.id,
        focusComments: true,
        initialProduct: _product,
      ),
    );
  }

  Future<void> _handleChatTap() async {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) {
      AppSnackBar.error(context, 'Please sign in to start chatting.');
      return;
    }
    if (_product.userId == userId) {
      AppSnackBar.show(context, 'You cannot message to yourself:)');
      return;
    }

    final chatViewModel = context.read<ChatRoomViewModel>();
    final productModel = _product.toModel();

    // Prefer existing conversation for this product, else any chat with seller
    final existingConversation =
        chatViewModel.findConversationForProduct(_product.id) ??
        chatViewModel.findConversationWithUser(_product.userId);
    if (existingConversation != null) {
      chatViewModel.selectConversation(existingConversation);
      chatViewModel.addAttachedProduct(productModel);
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.chatRoom,
        arguments: ChatRoomRouteArgs(
          conversationId: existingConversation.id,
          attachProductOnCompose: true,
        ),
      );
      return;
    }

    final conversation = await chatViewModel.createConversation(_product.id);
    if (!mounted) return;

    if (conversation == null) {
      AppSnackBar.error(
        context,
        chatViewModel.currentConversationError ?? 'Unable to open chat.',
      );
      return;
    }

    chatViewModel.addAttachedProduct(productModel);
    await Navigator.pushNamed(
      context,
      AppRoutes.chatRoom,
      arguments: ChatRoomRouteArgs(
        conversationId: conversation.id,
        attachProductOnCompose: true,
      ),
    );
  }

  bool _isProductLikedByCurrentUser() {
    return ProductLikeHelpers.isLikedByUser(
      product: _product,
      userId: context.read<UserViewModel>().userId,
    );
  }

  bool _isOwner() {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) return false;
    return _product.userId == userId;
  }

  void _showSnack(String message) {
    AppSnackBar.show(context, message);
  }

  bool _isSavedProduct() {
    return context.read<SavedListingsViewModel>().hasSavedProduct(_product.id);
  }

  Future<void> _ensureSavedProductsLoaded() async {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) return;

    await context.read<SavedListingsViewModel>().ensureLoadedForUser(userId: userId);
  }

  Future<void> _handleToggleSaveProduct() async {
    if (_isActionLoading) return;

    final savedListingsVm = context.read<SavedListingsViewModel>();
    final isSaved = _isSavedProduct();

    setState(() => _isActionLoading = true);
    try {
      if (isSaved) {
        await context.read<ProductFeedViewModel>().unsaveListing(_product.id);
        savedListingsVm.removeSavedProductLocally(productId: _product.id);

        if (mounted) {
          AppSnackBar.showUndo(
            context,
            'Removed from saved.',
            onUndo: () async {
              try {
                await context.read<ProductFeedViewModel>().saveListing(_product.id);
                savedListingsVm.addSavedProductLocally(_product);
              } catch (_) {
                if (!mounted) return;
                AppSnackBar.error(context, 'Failed to undo unsave product.');
              }
            },
          );
        }
      } else {
        await context.read<ProductFeedViewModel>().saveListing(_product.id);
        savedListingsVm.addSavedProductLocally(_product);

        if (mounted) {
          AppSnackBar.showUndo(
            context,
            'Saved to your list.',
            onUndo: () async {
              try {
                await context.read<ProductFeedViewModel>().unsaveListing(_product.id);
                savedListingsVm.removeSavedProductLocally(productId: _product.id);
              } catch (_) {
                if (!mounted) return;
                AppSnackBar.error(context, 'Failed to undo save product.');
              }
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(
          context,
          isSaved ? 'Failed to unsave product.' : 'Failed to save product.',
        );
      }
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
        builder: (context) => EditProductPage(product: Product.fromEntity(_product)),
      ),
    );

    // If edit was successful, refresh product feed
    if (result == true && mounted) {
      context.read<ProductFeedViewModel>().refresh();
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
        context.read<ProductFeedViewModel>().refresh();
      }

      _showSnack('Listing deleted.');
    } catch (e, st) {
      debugPrint('ProductCard._handleDeleteListing failed: $e\n$st');
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
      final provider = context.read<ProductFeedViewModel>();
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
    await executeAction(
      () async {
        final shareUrl = await context.read<ProductFeedViewModel>().shareProduct(_product.id);
        if (shareUrl == null || shareUrl.isEmpty) {
          throw Exception('Failed to get share link');
        }
        await ShareService.shareProduct(
          title: _product.title,
          url: shareUrl,
          text: '${_product.title} - ${_product.price} on NisitTrade',
        );
      },
      onLoadingChanged: (loading) => setState(() => _isActionLoading = loading),
      successMessage: 'Shared successfully!',
      errorMessage: 'Failed to share product.',
    );
  }

  Future<void> _handleReportListing() async {
    String selectedReason = _reportReasonOptions.first;
    final detailsController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Report listing'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  items: _reportReasonOptions
                      .map(
                        (reason) => DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedReason = value);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Details (optional)',
                  ),
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
      },
    );

    if (shouldSubmit != true) {
      detailsController.dispose();
      return;
    }

    final reason = selectedReason.trim();
    final details = detailsController.text.trim();
    detailsController.dispose();

    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      if (!mounted) return;
      await context.read<ProductFeedViewModel>().reportProduct(
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

  Future<void> _showProductActions() async {
    await _ensureSavedProductsLoaded();
    if (!mounted) return;

    final handler = ProductCardActionHandler(
      context: context,
      product: _product,
      isOwner: _isOwner(),
      isSaved: _isSavedProduct(),
      onEditProduct: _handleEditListing,
      onDeleteProduct: _handleDeleteListing,
      onToggleSaveProduct: _handleToggleSaveProduct,
      onHideToggle: _handleHideToggle,
      onShareProduct: _handleShareListing,
      onReportProduct: _handleReportListing,
    );
    handler.showActionSheet();
  }

  ProductEntity _optimisticallyLikeProduct(ProductEntity product, int userId) {
    if (ProductLikeHelpers.isLikedByUser(product: product, userId: userId)) {
      return product;
    }

    final optimisticLikeId = -DateTime.now().microsecondsSinceEpoch;
    return ProductEntity(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      status: product.status,
      userId: product.userId,
      categoryId: product.categoryId,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      seller: product.seller,
      category: product.category,
      imageUrls: product.imageUrls,
      likes: [
        ...product.likes,
        ProductLikeEntity(id: optimisticLikeId, userId: userId),
      ],
      comments: product.comments,
      likeCount: product.likeCount + 1,
      commentCount: product.commentCount,
      isLiked: true,
    );
  }

  ProductEntity _optimisticallyUnlikeProduct(ProductEntity product, int userId) {
    if (!ProductLikeHelpers.isLikedByUser(product: product, userId: userId)) {
      return product;
    }

    final updatedLikes = [...product.likes]..removeWhere((like) => like.userId == userId);
    final nextLikeCount = product.likeCount > 0 ? product.likeCount - 1 : 0;

    return ProductEntity(
      id: product.id,
      title: product.title,
      description: product.description,
      price: product.price,
      status: product.status,
      userId: product.userId,
      categoryId: product.categoryId,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
      seller: product.seller,
      category: product.category,
      imageUrls: product.imageUrls,
      likes: updatedLikes,
      comments: product.comments,
      likeCount: nextLikeCount,
      commentCount: product.commentCount,
      isLiked: false,
    );
  }

  Future<void> _handleLikeTap() async {
    if (_isLoading) return;

    final userId = context.read<UserViewModel>().userId;
    if (userId == null) {
      AppSnackBar.error(
        context,
        'Unable to load your account. Please try again.',
      );
      return;
    }

    // Trigger animation
    _likeAnimationController.forward(from: 0.0);

    // Provide haptic feedback for modern feel
    HapticFeedback.lightImpact();

    final previousProduct = _product;
    final isCurrentlyLiked = _isProductLikedByCurrentUser();
    final unlikeLikeId = isCurrentlyLiked
        ? ProductLikeHelpers.findUserLikeId(product: _product, userId: userId)
        : null;
    final optimisticProduct = isCurrentlyLiked
        ? _optimisticallyUnlikeProduct(_product, userId)
        : _optimisticallyLikeProduct(_product, userId);

    setState(() {
      _product = optimisticProduct;
      _isLoading = true;
    });
    widget.onProductUpdated?.call(_product);

    try {
      final provider = context.read<ProductFeedViewModel>();

      ProductEntity? updatedProduct;

      if (isCurrentlyLiked) {
        var likeId = unlikeLikeId;

        if (likeId == null) {
          final refreshed = await provider.refreshProduct(_product.id);
          if (refreshed != null && mounted) {
            setState(() => _product = refreshed);
          }
          likeId = ProductLikeHelpers.findUserLikeId(
            product: _product,
            userId: userId,
          );
        }

        if (likeId == null) {
          if (mounted) {
            AppSnackBar.error(
              context,
              'Unable to find your like. Please try again.',
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
        final nextProduct = updatedProduct;
        setState(() => _product = nextProduct);
        widget.onProductUpdated?.call(_product);
      }

      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Like operation error: $e');
      if (mounted) {
        setState(() => _product = previousProduct);
        widget.onProductUpdated?.call(_product);
        AppSnackBar.error(
          context,
          'Failed to update like. Please try again.',
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
                  images: _product.imageUrls,
                  currentIndex: _currentImageIndex,
                  pageController: _pageController,
                  pageViewKey: PageStorageKey('product-card-carousel-${_product.id}'),
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
              onChatTap: _handleChatTap,
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
  final ProductEntity product;
  final bool isLiked;
  final AnimationController likeAnimationController;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onChatTap;

  const _ProductCardActionSection({
    required this.product,
    required this.isLiked,
    required this.likeAnimationController,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProductCardActionRow(
      product: product,
      isLiked: isLiked,
      likeAnimationController: likeAnimationController,
      onLikeTap: onLikeTap,
      onCommentTap: onCommentTap,
      onChatTap: onChatTap,
    );
  }
}

