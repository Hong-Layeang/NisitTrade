import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/comment.dart';
import '../../../models/like.dart';
import '../../../models/product.dart';
import '../../../providers/product_feed_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/api/api_exception.dart';
import '../../../utils/constants/colors.dart';
import '../../../utils/routes/app_routes.dart';
import '../../widgets/common/app_action_chip.dart';
import '../../widgets/common/full_screen_image_viewer.dart';
import '../../widgets/marketplace/product_card_image_carousel.dart';
import '../profile/other_profile_page.dart';

class ProductDetailArgs {
  final int productId;
  final bool focusComments;

  const ProductDetailArgs({
    required this.productId,
    this.focusComments = false,
  });
}

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final bool focusComments;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.focusComments = false,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage>
    with TickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _commentFocusNode = FocusNode();
  late AnimationController _likeAnimationController;

  Product? _product;
  String? _error;
  bool _isLoading = false;
  bool _isSubmittingComment = false;
  bool _isTogglingLike = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadData();
  }

  void _scrollToComments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
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

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final product = await context
          .read<ProductFeedProvider>()
          .refreshProduct(widget.productId);
      if (product == null) {
        throw ApiException(message: 'Product not found');
      }

      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
        if (widget.focusComments) {
          _scrollToComments();
        }
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

  Future<void> _refreshProduct() async {
    try {
      final product = await context
          .read<ProductFeedProvider>()
          .refreshProduct(widget.productId);
      if (mounted && product != null) {
        setState(() => _product = product);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    }
  }

  Like? _findUserLike() {
    final userId = context.read<UserProvider>().userId;
    if (userId == null) return null;
    final likes = _product?.likes ?? [];
    for (final like in likes) {
      if (like.userId == userId) {
        return like;
      }
    }
    return null;
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;
    if (context.read<UserProvider>().userId == null) return;
    final like = _findUserLike();

    _likeAnimationController.forward(from: 0.0);
    setState(() => _isTogglingLike = true);
    try {
      final provider = context.read<ProductFeedProvider>();
      final updatedProduct = like == null
          ? await provider.likeProduct(widget.productId)
          : await provider.unlikeProduct(
              productId: widget.productId,
              likeId: like.id,
            );
      if (mounted && updatedProduct != null) {
        setState(() => _product = updatedProduct);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
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
      final updatedProduct = await context.read<ProductFeedProvider>().addComment(
            productId: widget.productId,
            content: content,
          );
      _commentController.clear();
      if (mounted && updatedProduct != null) {
        setState(() => _product = updatedProduct);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final product = _product;
    if (product == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
      ),
      body: RefreshIndicator(
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: _buildCommentsHeader(product),
              ),
              _buildComments(product.comments ?? []),
              const SizedBox(height: 12),
              _buildCommentComposer(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(Product product) {
    final images = product.imageUrls;
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 3,
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
      aspectRatio: 4 / 3,
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
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Product product) {
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
            Text(
              product.timeAgo,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
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
    Navigator.pushNamed(
      context,
      AppRoutes.userProfile,
      arguments: OtherProfileArgs(userId: userId),
    );
  }

  Widget _buildSellerRow(Product product) {
    final userProvider = context.watch<UserProvider>();
    final isCurrentUser =
        userProvider.userId != null && product.userId == userProvider.userId;
    final avatarUrl = isCurrentUser
        ? userProvider.profile?.profileImage
        : product.sellerProfileImage;

    return Row(
      children: [
        GestureDetector(
          onTap: () => _navigateToUserProfile(product.userId),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surface,
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.textSecondary)
                    : null,
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
                    _extractUniversity(product.user?.email ?? ''),
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
        OutlinedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chat is not implemented yet.')),
            );
          },
          child: const Text('Chat'),
        ),
      ],
    );
  }

  Widget _buildActions(Product product) {
    final isLiked = _findUserLike() != null;
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

  Widget _buildDescription(Product product) {
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
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsHeader(Product product) {
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

  Widget _buildComments(List<Comment> comments) {
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
      separatorBuilder: (_, __) => const Divider(height: 16, color: AppColors.border),
      itemBuilder: (context, index) {
        final comment = comments[index];
        final userProvider = context.watch<UserProvider>();
        final isCurrentUser = userProvider.userId != null &&
            comment.userId == userProvider.userId;
        final commentAvatarUrl = isCurrentUser
            ? userProvider.profile?.profileImage
            : comment.user?.profileImage;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _navigateToUserProfile(comment.userId),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surface,
                backgroundImage: commentAvatarUrl != null
                    ? NetworkImage(commentAvatarUrl)
                    : null,
                child: commentAvatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.textSecondary)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToUserProfile(comment.userId),
                    child: Text(
                      comment.user?.fullName ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeAgo(comment.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              focusNode: _commentFocusNode,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write a comment...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _isSubmittingComment ? null : _submitComment,
            icon: _isSubmittingComment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _extractUniversity(String email) {
    final parts = email.split('@');
    if (parts.length < 2) return email;
    
    final domainParts = parts[1].split('.');
    if (domainParts.length >= 2) {
      return '@${domainParts[1]}';
    }
    return email;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}
