import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

import '../../../data/models/product.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/saved_listings_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';

import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/school_short_name.dart';
import '../../widgets/app_refresh_indicator.dart';
import '../../widgets/app_action_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_error_builder.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/app_snack_bar.dart';
import '../community/community_detail_page.dart';
import '../edit/edit_product_page.dart';
import '../marketplace/product_detail_page.dart';

class SavedListingsPage extends StatefulWidget {
  const SavedListingsPage({super.key});

  @override
  State<SavedListingsPage> createState() => _SavedListingsPageState();
}

class _SavedListingsPageState extends State<SavedListingsPage>
    with SingleTickerProviderStateMixin {
  bool _didInitialLoad = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final userId = context.read<UserViewModel>().userId;
    if (userId != null) {
      _didInitialLoad = context
          .read<SavedListingsViewModel>()
          .hasLoadedForUser(userId: userId);

      if (!_didInitialLoad) {
        _loadSavedListings();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedListings() async {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) return;
    await context.read<SavedListingsViewModel>().loadSavedListings(
          userId: userId,
          showLoading: !_didInitialLoad,
        );
    _didInitialLoad = true;
  }

  Future<void> _refreshSavedListings() async {
    final userId = context.read<UserViewModel>().userId;
    if (userId == null) return;
    await context.read<SavedListingsViewModel>().loadSavedListings(
          userId: userId,
          showLoading: false,
        );
    _didInitialLoad = true;
  }

  Widget _buildTabBar({
    required int productCount,
    required int postCount,
  }) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
          borderSide: BorderSide(color: AppColors.primary, width: 3),
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            icon: Badge(
              isLabelVisible: productCount > 0,
              label: Text('$productCount'),
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              child: const Icon(Icons.shopping_bag_outlined, size: 24),
            ),
            text: 'Products',
          ),
          Tab(
            icon: Badge(
              isLabelVisible: postCount > 0,
              label: Text('$postCount'),
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              child: const Icon(Icons.article_outlined, size: 24),
            ),
            text: 'Posts',
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreviewImage({
    required String image,
    required bool isNetworkImage,
    required int imageCount,
  }) {
    final imageWidget = isNetworkImage
        ? CachedNetworkImage(
            imageUrl: image,
            fit: BoxFit.cover,
            width: double.infinity,
            useOldImageOnUrlChange: true,
            fadeInDuration: Duration.zero,
            fadeOutDuration: Duration.zero,
            placeholder: (context, url) => Container(
              color: AppColors.surface,
              child: const Center(
                child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.surface,
              child: const Center(
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          )
        : Image.asset(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.surface,
              child: const Center(
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: imageWidget,
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.22),
                  ],
                ),
              ),
            ),
          ),
          if (imageCount > 1)
            Positioned(
              right: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$imageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAuthorAvatar(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          useOldImageOnUrlChange: true,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          errorWidget: (context, url, error) => Container(
            width: 40,
            height: 40,
            color: AppColors.surface,
            child: const Icon(Icons.person_outline, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_outline, color: AppColors.textSecondary),
    );
  }

  Future<void> _removeSaved(ProductEntity product) async {
    final ok = await context
        .read<SavedListingsViewModel>()
        .removeSavedListing(productId: product.id);

    if (!mounted) return;
    if (!ok) {
      AppSnackBar.error(
        context,
        context.read<SavedListingsViewModel>().actionError ??
            'Failed to remove saved listing.',
      );
    }
  }

  Future<void> _removeSavedPost(int postId) async {
    final ok = await context
        .read<SavedListingsViewModel>()
        .removeSavedPost(postId: postId);

    if (!mounted) return;
    if (!ok) {
      AppSnackBar.error(
        context,
        context.read<SavedListingsViewModel>().actionError ??
            'Failed to remove saved post.',
      );
      return;
    }

    AppSnackBar.show(context, 'Post removed from saved.');
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
      _refreshSavedListings();
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
      AppSnackBar.error(
        context,
        savedListingsVm.actionError ?? 'Failed to delete listing.',
      );
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

  Widget _buildProductsGrid() {
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
          actionIcon: Icons.bookmark_remove_outlined,
          actionIconColor: AppColors.primary,
          onTap: () async {
            await Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: ProductDetailArgs(
                productId: product.id,
                initialProduct: product,
              ),
            );
          },
          onLikeTap: () => _removeSaved(product),
          onLongPress: () => _showOwnerActions(product),
        );
      },
    );
  }

  Widget _buildSavedPostsTab() {
    final savedPosts = context.watch<SavedListingsViewModel>().savedPosts;
    if (savedPosts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          EmptyState(
            icon: Icons.article_outlined,
            title: 'No saved posts yet',
            subtitle: 'Save posts from community to view them here.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      itemCount: savedPosts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final post = savedPosts[index];
        final firstImage = post.orderedImages.isNotEmpty ? post.orderedImages.first : null;
        final isNetworkImage = (firstImage?.startsWith('http://') ?? false) ||
            (firstImage?.startsWith('https://') ?? false);
        final imageCount = post.orderedImages.length;
        final authorHandle = buildSchoolShortName(
          universityName: post.author.university?.name,
          universityDomain: post.author.university?.domain,
          fallback: '',
        );

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          shadowColor: Colors.black.withValues(alpha: 0.08),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.pushNamed(
                context,
                AppRoutes.communityDetail,
                arguments: CommunityDetailArgs(
                  postId: post.id,
                  initialPost: post,
                ),
              );
              if (mounted) {
                _refreshSavedListings();
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAuthorAvatar(post.author.profileImage),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.author.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                if (authorHandle.isNotEmpty)
                                  Flexible(
                                    child: Text(
                                      '@$authorHandle',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                if (authorHandle.isNotEmpty) const SizedBox(width: 6),
                                Timeago(
                                  date: post.createdAt,
                                  builder: (context, value) => Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _removeSavedPost(post.id),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(
                            Icons.bookmark_remove_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    post.content,
                    maxLines: firstImage == null ? 4 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.42,
                    ),
                  ),
                  if (firstImage != null) ...[
                    const SizedBox(height: 10),
                    _buildPostPreviewImage(
                      image: firstImage,
                      isNetworkImage: isNetworkImage,
                      imageCount: imageCount,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMetaChip(
                              icon: Icons.favorite_border,
                              label: '${post.likesCount}',
                            ),
                            _buildMetaChip(
                              icon: Icons.mode_comment_outlined,
                              label: '${post.commentsCount}',
                            ),
                            if (imageCount > 0)
                              _buildMetaChip(
                                icon: Icons.photo_library_outlined,
                                label: '$imageCount',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.communityDetail,
                            arguments: CommunityDetailArgs(
                              postId: post.id,
                              initialPost: post,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          minimumSize: const Size(0, 32),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: const Text(
                          'View',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
    final productCount = vm.savedProducts.length;
    final postCount = vm.savedPosts.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildTabBar(productCount: productCount, postCount: postCount),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                LoadingErrorBuilder(
                  isLoading: vm.isLoading,
                  error: vm.error,
                  onRetry: _loadSavedListings,
                  isInitialLoad: !_didInitialLoad,
                  child: AppRefreshIndicator(
                    onRefresh: _refreshSavedListings,
                    child: _buildProductsGrid(),
                  ),
                ),
                AppRefreshIndicator(
                  onRefresh: _refreshSavedListings,
                  child: _buildSavedPostsTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

