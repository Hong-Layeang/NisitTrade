import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

import '../../../data/dtos/comment_dto.dart';
import '../../../data/dtos/like_dto.dart';
import '../../../data/dtos/product_dto.dart';
import '../../../data/repository_interfaces/i_product_repository.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/saved_listings_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../logic/view_models/chat_view_model.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/utils/school_short_name.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../widgets/app_action_chip.dart';
import '../../widgets/app_comment_composer.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../../widgets/user_widgets.dart';
import '../edit/edit_product_page.dart';
import 'widgets/product_card_image_carousel.dart';
import 'widgets/comment_item.dart';
import 'widgets/edit_comment_dialog.dart';
import 'widgets/product_card_action_handler.dart';
import '../profile/other_profile_page.dart' hide getIt;
import '../../../logic/services/share_service.dart';

class ProductDetailArgs {
  final int productId;
  final bool focusComments;
  final ProductDto? initialProduct;

  const ProductDetailArgs({
    required this.productId,
    this.focusComments = false,
    this.initialProduct,
  });
}

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final bool focusComments;
  final ProductDto? initialProduct;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.focusComments = false,
    this.initialProduct,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  static const double _productImageAspectRatio = 5 / 4;

  static const List<String> _reportReasonOptions = [
    'Spam or scam',
    'Prohibited or illegal item',
    'Counterfeit item',
    'Misleading description',
    'Inappropriate content',
    'Other',
  ];

  final TextEditingController _commentController = TextEditingController();
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsSectionKey = GlobalKey();
  final FocusNode _commentFocusNode = FocusNode();
  late AnimationController _likeAnimationController;
  late IProductRepository _productRepository;

  ProductDto? _product;
  String? _error;
  bool _isLoading = false;
  bool _isSubmittingComment = false;
  bool _isActionLoading = false;

  bool _isTogglingLike = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _productRepository = getIt<IProductRepository>();
    _likeAnimationController = AnimationController(
      duration: AppDurations.slow,
      vsync: this,
    );

    // Use initial product if provided, or check cache
    if (widget.initialProduct != null) {
      _product = widget.initialProduct!;
      _loadData(silent: true);
    } else {
      final cachedProduct = context
          .read<ProductFeedViewModel>()
          .getCachedProduct(widget.productId);
      if (cachedProduct != null) {
        _product = cachedProduct;
        _loadData(silent: true);
      } else {
        _loadData();
      }
    }
  }

  void _scrollToComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final commentContext = _commentsSectionKey.currentContext;
      if (commentContext != null) {
        Scrollable.ensureVisible(
          commentContext,
          duration: AppDurations.standard,
          curve: Curves.easeOut,
          alignment: 0.2,
        );
        return;
      }

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.standard,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToLatestComment() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppDurations.standard,
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openChatWithSeller(ProductDto product) async {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) {
      AppSnackBar.error(context, 'Please sign in to start chatting.');
      return;
    }
    if (product.userId == userId) {
      AppSnackBar.show(context, 'You cannot chat on your own listing.');
      return;
    }

    final chatViewModel = context.read<ChatRoomViewModel>();

    // Prefer existing conversation for this product, else any chat with seller
    final existingConversation =
        chatViewModel.findConversationForProduct(product.id) ??
        chatViewModel.findConversationWithUser(product.userId);
    if (existingConversation != null) {
      chatViewModel.selectConversation(existingConversation);
      chatViewModel.addAttachedProduct(product);
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

    final conversation = await chatViewModel.createConversation(product.id);
    if (!mounted) return;

    if (conversation == null) {
      AppSnackBar.error(
        context,
        chatViewModel.currentConversationError ?? 'Unable to open chat.',
      );
      return;
    }

    chatViewModel.addAttachedProduct(product);
    await Navigator.pushNamed(
      context,
      AppRoutes.chatRoom,
      arguments: ChatRoomRouteArgs(
        conversationId: conversation.id,
        attachProductOnCompose: true,
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    _commentFocusNode.dispose();
    _likeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final product = await context.read<ProductFeedViewModel>().refreshProduct(
        widget.productId,
      );
      if (product == null) {
        throw ApiException(message: 'Product not found');
      }

      if (mounted) {
        setState(() {
          _product = product;
          if (!silent) {
            _isLoading = false;
          }
        });
        if (widget.focusComments) {
          _scrollToComments();
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (!silent) {
            _error = e.message;
            _isLoading = false;
          }
        });
      }
    }
  }

  Future<void> _refreshProduct() async {
    try {
      final product = await context.read<ProductFeedViewModel>().refreshProduct(
        widget.productId,
      );
      if (mounted && product != null) {
        setState(() => _product = product);
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.message);
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;
    final userId = context.read<UserViewModel>().userId;
    final product = _product;
    if (userId == null || product == null) return;

    final likeId = product.likes
        .where((like) => like.userId == userId)
        .map((like) => like.id)
        .cast<int?>()
        .firstWhere((id) => id != null, orElse: () => null);
    final wasLiked = likeId != null;
    final previousProduct = product;

    final optimisticProduct = wasLiked
        ? product.copyWith(
            likes: [...product.likes]
              ..removeWhere((like) => like.userId == userId),
          )
        : product.copyWith(
            likes: [
              ...product.likes,
              LikeDto(
                id: -DateTime.now().microsecondsSinceEpoch,
                userId: userId,
                productId: product.id,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ],
          );

    _likeAnimationController.forward(from: 0.0);
    setState(() {
      _product = optimisticProduct;
      _isTogglingLike = true;
    });

    try {
      final provider = context.read<ProductFeedViewModel>();
      final updatedProduct = likeId == null
          ? await provider.likeProduct(widget.productId)
          : await provider.unlikeProduct(
              productId: widget.productId,
              likeId: likeId,
            );
      if (mounted && updatedProduct != null) {
        setState(() => _product = updatedProduct);
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _product = previousProduct);
        AppSnackBar.error(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingLike = false);
      }
    }
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty || _isSubmittingComment) return;

    setState(() => _isSubmittingComment = true);

    try {
      final updatedProduct = await context
          .read<ProductFeedViewModel>()
          .addComment(productId: widget.productId, content: content);
      _commentController.clear();
      if (mounted && updatedProduct != null) {
        setState(() => _product = updatedProduct);
        _scrollToLatestComment();
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  Future<void> _editComment(CommentDto comment) async {
    final newContent = await EditCommentDialog.show(
      context,
      initialContent: comment.content,
    );

    if (!mounted) return;

    if (newContent == null || newContent == comment.content) return;

    try {
      final updatedProduct = await context
          .read<ProductFeedViewModel>()
          .updateComment(
            productId: widget.productId,
            commentId: comment.id,
            content: newContent,
          );
      if (mounted && updatedProduct != null) {
        setState(() => _product = updatedProduct);
        AppSnackBar.success(context, 'Comment updated successfully');
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.message);
      }
    }
  }

  Future<void> _deleteComment(CommentDto comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed != true) return;

    try {
      final updatedProduct = await context
          .read<ProductFeedViewModel>()
          .deleteComment(productId: widget.productId, commentId: comment.id);
      if (mounted && updatedProduct != null) {
        setState(() => _product = updatedProduct);
        AppSnackBar.success(context, 'Comment deleted successfully');
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.message);
      }
    }
  }

  bool _isOwner() {
    final product = _product;
    final userId = context.read<UserViewModel>().userId;
    return product != null && userId != null && product.userId == userId;
  }

  bool _isSavedProduct() {
    return context.read<SavedListingsViewModel>().hasSavedProduct(
      widget.productId,
    );
  }

  Future<void> _ensureSavedProductsLoaded() async {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) return;

    await context.read<SavedListingsViewModel>().ensureLoadedForUser(
      userId: userId,
    );
  }

  Future<void> _handleToggleSaveProduct() async {
    final product = _product;
    if (product == null) return;
    if (_isActionLoading) return;

    final savedListingsVm = context.read<SavedListingsViewModel>();
    final isSaved = _isSavedProduct();

    setState(() => _isActionLoading = true);
    try {
      if (isSaved) {
        await context.read<ProductFeedViewModel>().unsaveListing(
          widget.productId,
        );
        savedListingsVm.removeSavedProductLocally(productId: widget.productId);

        if (mounted) {
          AppSnackBar.showUndo(
            context,
            'Removed from saved.',
            onUndo: () async {
              try {
                await context.read<ProductFeedViewModel>().saveListing(
                  widget.productId,
                );
                savedListingsVm.addSavedProductLocally(product);
              } catch (_) {
                if (!mounted) return;
                AppSnackBar.error(context, 'Failed to undo unsave product.');
              }
            },
          );
        }
      } else {
        await context.read<ProductFeedViewModel>().saveListing(
          widget.productId,
        );
        savedListingsVm.addSavedProductLocally(product);

        if (mounted) {
          AppSnackBar.showUndo(
            context,
            'Saved to your list.',
            onUndo: () async {
              try {
                await context.read<ProductFeedViewModel>().unsaveListing(
                  widget.productId,
                );
                savedListingsVm.removeSavedProductLocally(
                  productId: widget.productId,
                );
              } catch (_) {
                if (!mounted) return;
                AppSnackBar.error(context, 'Failed to undo save product.');
              }
            },
          );
        }
      }
    } catch (_) {
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

  Future<void> _handleEditProduct() async {
    final product = _product;
    if (product == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(product: product),
      ),
    );

    if (result == true && mounted) {
      await _refreshProduct();
    }
  }

  Future<void> _handleDeleteProduct() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product'),
        content: const Text('Are you sure you want to delete this product?'),
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

    if (shouldDelete != true || _isActionLoading) return;

    setState(() => _isActionLoading = true);

    try {
      final response = await _productRepository.deleteProduct(widget.productId);
      if (!response.isSuccess) {
        throw response.error!;
      }

      if (!mounted) return;
      context.read<ProductFeedViewModel>().refresh();
      AppSnackBar.success(context, 'Product deleted.');
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to delete product.');
      }
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
      final product = _product;
      if (product == null) return;

      final provider = context.read<ProductFeedViewModel>();
      final updated = product.isHidden
          ? await provider.unhideProduct(widget.productId)
          : await provider.hideProduct(widget.productId);

      if (updated != null && mounted) {
        setState(() => _product = updated);
        AppSnackBar.success(
          context,
          product.isHidden ? 'Product unhidden.' : 'Product hidden.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to update product visibility.');
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleShareProduct() async {
    await executeAction(
      () async {
        final shareUrl = await context
            .read<ProductFeedViewModel>()
            .shareProduct(widget.productId);
        if (shareUrl == null || shareUrl.isEmpty) {
          throw Exception('Failed to get share link');
        }
        await ShareService.shareProduct(
          title: _product?.title ?? 'Product',
          url: shareUrl,
          text:
              '${_product?.title ?? 'Check this out'} - ${_product?.price ?? ''} on NisitTrade',
        );
      },
      onLoadingChanged: (loading) => setState(() => _isActionLoading = loading),
      successMessage: 'Shared successfully!',
      errorMessage: 'Failed to share product.',
    );
  }

  Future<void> _handleReportProduct() async {
    String selectedReason = _reportReasonOptions.first;
    final detailsController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Report product'),
            content: SingleChildScrollView(
              child: Column(
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
                            child: Text(
                              reason,
                              overflow: TextOverflow.ellipsis,
                            ),
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
    if (!mounted) return;

    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      await context.read<ProductFeedViewModel>().reportProduct(
        productId: widget.productId,
        reason: reason,
        details: details.isEmpty ? null : details,
      );
      if (mounted) {
        AppSnackBar.success(context, 'Report submitted.');
      }
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Failed to submit report.');
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _showProductActions() async {
    final product = _product;
    if (product == null) return;

    await _ensureSavedProductsLoaded();
    if (!mounted) return;
    FocusScope.of(context).unfocus();

    final handler = ProductCardActionHandler(
      context: context,
      product: product,
      isOwner: _isOwner(),
      isSaved: _isSavedProduct(),
      onEditProduct: _handleEditProduct,
      onDeleteProduct: _handleDeleteProduct,
      onToggleSaveProduct: _handleToggleSaveProduct,
      onHideToggle: _handleHideToggle,
      onShareProduct: _handleShareProduct,
      onReportProduct: _handleReportProduct,
    );
    handler.showActionSheet();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(AppErrorMessages.resolve(_error)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final product = _product;
    if (product == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        actions: [
          IconButton(
            onPressed: _isActionLoading ? null : _showProductActions,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProduct,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(product),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: _buildHeader(product),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSellerRow(product),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildActions(product),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildDescription(product),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: AppColors.border),
                    Padding(
                      key: _commentsSectionKey,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: _buildCommentsHeader(product),
                    ),
                    _buildComments(product.comments),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          _buildCommentComposer(),
        ],
      ),
    );
  }

  Widget _buildImageSection(ProductDto product) {
    final images = product.imageUrls;
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: _productImageAspectRatio,
        child: Container(
          width: double.infinity,
          color: AppColors.surface,
          child: const Icon(
            Icons.image,
            size: 80,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _productImageAspectRatio,
      child: GestureDetector(
        onTap: () => FullScreenImageViewer.show(
          context,
          images[_currentImageIndex],
          allImages: images,
          initialIndex: _currentImageIndex,
        ),
        child: ProductCardImageCarousel(
          images: images,
          currentIndex: _currentImageIndex,
          pageController: _pageController,
          pageViewKey: PageStorageKey(
            'product-detail-carousel-${widget.productId}',
          ),
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ProductDto product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              product.formattedPrice,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            _buildStatusChip(product.statusLabel),
            const Spacer(),
            Timeago(
              date: product.createdAt,
              builder: (context, value) => Text(
                value,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          product.categoryName,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  void _navigateToUserProfile(int userId) {
    final currentUserId = context.read<UserViewModel>().userId;
    if (currentUserId == userId) {
      // Navigate to own profile tab
      Navigator.pushNamed(context, AppRoutes.profile);
    } else {
      // Navigate to other user's profile
      Navigator.pushNamed(
        context,
        AppRoutes.userProfile,
        arguments: OtherProfileArgs(userId: userId),
      );
    }
  }

  Widget _buildSellerRow(ProductDto product) {
    return Selector<UserViewModel, ({int? userId, String? profileImage})>(
      selector: (_, vm) =>
          (userId: vm.userId, profileImage: vm.profile?.profileImage),
      builder: (context, userData, _) {
        final isCurrentUser =
            userData.userId != null && product.userId == userData.userId;
        final avatarUrl = isCurrentUser
            ? userData.profileImage
            : product.sellerProfileImage;

        return _buildSellerRowContent(product, isCurrentUser, avatarUrl);
      },
    );
  }

  Widget _buildSellerRowContent(
    ProductDto product,
    bool isCurrentUser,
    String? avatarUrl,
  ) {
    final trimmedAvatarUrl = avatarUrl?.trim();
    final resolvedAvatarUrl =
        trimmedAvatarUrl != null && trimmedAvatarUrl.isNotEmpty
        ? ImageUrlHelper.getFullImageUrl(trimmedAvatarUrl)
        : '';
    final handle = buildSchoolShortName(
      universityName: product.user?.university?.name,
      universityDomain: product.user?.university?.domain,
      email: product.user?.email,
      fallback: '',
    );

    return Row(
      children: [
        GestureDetector(
          onTap: () => _navigateToUserProfile(product.userId),
          child: Row(
            children: [
              RepaintBoundary(
                child: UserAvatar(
                  key: ValueKey(
                    'detail_seller_avatar_${product.userId}_$resolvedAvatarUrl',
                  ),
                  imageUrl: resolvedAvatarUrl,
                  displayName: product.sellerName,
                  radius: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.sellerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    handle.isNotEmpty ? '@$handle' : '',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        if (!isCurrentUser)
          FilledButton.icon(
            onPressed: _isActionLoading
                ? null
                : () => _openChatWithSeller(product),
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Chat'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _buildActions(ProductDto product) {
    final userId = context.read<UserViewModel>().userId;
    final isLiked =
        userId != null && product.likes.any((like) => like.userId == userId);
    return Row(
      children: [
        AppActionChip(
          icon: ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.25).animate(
              CurvedAnimation(
                parent: _likeAnimationController,
                curve: Curves.elasticOut,
              ),
            ),
            child: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: isLiked ? Colors.redAccent : AppColors.textSecondary,
            ),
          ),
          label: product.likesCount.toString(),
          labelColor: isLiked ? Colors.redAccent : AppColors.textSecondary,
          onTap: _toggleLike,
          isDisabled: _isTogglingLike,
        ),
        const SizedBox(width: 12),
        AppActionChip(
          icon: const Icon(
            Icons.chat_bubble_outline,
            size: 18,
            color: AppColors.textSecondary,
          ),
          label: product.commentsCount.toString(),
          labelColor: AppColors.textSecondary,
          onTap: _scrollToComments,
        ),
      ],
    );
  }

  Widget _buildDescription(ProductDto product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description ?? 'No description provided.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildCommentsHeader(ProductDto product) {
    return Row(
      children: [
        const Text(
          'Comments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          product.commentsCount.toString(),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildComments(List<CommentDto> comments) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No comments yet. Be the first to comment.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      itemCount: comments.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 16, color: AppColors.border),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return CommentItem(
          key: ValueKey(comment.id),
          comment: comment,
          onUserTap: () => _navigateToUserProfile(comment.userId),
          onEdit: () => _editComment(comment),
          onDelete: () => _deleteComment(comment),
        );
      },
    );
  }

  Widget _buildCommentComposer() {
    return AppCommentComposer(
      controller: _commentController,
      focusNode: _commentFocusNode,
      onSend: _submitComment,
      isSubmitting: _isSubmittingComment,
      maxLines: 3,
      pinnedToBottom: true,
    );
  }
}

