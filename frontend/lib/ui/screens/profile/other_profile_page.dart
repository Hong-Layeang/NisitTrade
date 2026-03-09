import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/repository_interfaces/i_user_repository.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user_profile.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/extensions/state_extensions.dart';
import '../../widgets/empty_state.dart';
import 'widgets/profile_widgets.dart';
import '../marketplace/product_detail_page.dart';

final getIt = GetIt.instance;

class OtherProfileArgs {
  final int userId;

  const OtherProfileArgs({required this.userId});
}

class OtherProfilePage extends StatefulWidget {
  final int userId;

  const OtherProfilePage({super.key, required this.userId});

  @override
  State<OtherProfilePage> createState() => _OtherProfilePageState();
}

class _OtherProfilePageState extends State<OtherProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final IUserRepository _userRepository;

  UserProfile? _profile;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  bool _isFollowing = false;

  // Using AppDimensions for layout constants

  @override
  void initState() {
    super.initState();    _userRepository = getIt<IUserRepository>();    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userResponse = await _userRepository.getUserById(widget.userId);
      if (!userResponse.isSuccess) {
        throw userResponse.error!;
      }

      final profile = userResponse.data!;
      final productsResponse = await _userRepository.getUserProducts(
        userId: profile.id,
        limit: 50,
        offset: 0,
      );

      if (!productsResponse.isSuccess) {
        throw productsResponse.error!;
      }

      setStateIfMounted(() {
        _profile = UserProfile.fromEntity(profile);
        _products = (productsResponse.data ?? []).toModels();
        _isFollowing = profile.isFollowing;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setStateIfMounted(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null) return;

    // Optimistic update
    final wasFollowing = _isFollowing;
    final oldFollowerCount = _profile!.followerCount;
    setState(() {
      _isFollowing = !_isFollowing;
      _profile = _profile!.copyWith(
        isFollowing: _isFollowing,
        followerCount: _isFollowing ? oldFollowerCount + 1 : oldFollowerCount - 1,
      );
    });

    final response = wasFollowing
        ? await _userRepository.unfollowUser(widget.userId)
        : await _userRepository.followUser(widget.userId);

    if (!response.isSuccess && mounted) {
      // Revert on error
      setState(() {
        _isFollowing = wasFollowing;
        _profile = _profile!.copyWith(
          isFollowing: wasFollowing,
          followerCount: oldFollowerCount,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadProfile, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.textPrimary,
                    title: Text(
                      profile.fullName,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    expandedHeight: 0,
                  ),
                  SliverToBoxAdapter(
                    child: ProfileHeaderSection(
                      data: ProfileHeaderData(
                        coverImage: profile.coverImage,
                        profileImage: profile.profileImage,
                        fullName: profile.fullName,
                        bio: profile.bio,
                        followerCount: profile.followerCount,
                        followingCount: profile.followingCount,
                        major: profile.major,
                        schoolShortName: ProfileUtils.getSchoolShortName(profile.university?.toEntity()),
                      ),
                      coverHeight: AppDimensions.profileCoverHeight,
                      avatarRadius: AppDimensions.profileAvatarRadius,
                      avatarBorder: AppDimensions.profileAvatarBorder,
                      avatarGap: AppDimensions.profileAvatarGap,
                      statsDetailGap: 20,
                      actionsBelow: _buildActionButtons(profile),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyTabBarDelegate(
                      tabBar: _buildTabBar(context),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [_buildProductGrid(profile), _buildPostsTab()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(UserProfile profile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _toggleFollow,
              icon: Icon(
                _isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined,
                size: 18,
              ),
              label: Text(_isFollowing ? 'Unfollow' : 'Follow'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border, width: 1.5),
                elevation: 0,
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRoutes.chatRoom,
                arguments: {'userId': profile.id},
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Message'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size.fromHeight(44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildTabBar(BuildContext context) {
    final productCount = _products.length;
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
              label: Text('$productCount'),
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              child: const Icon(Icons.shopping_bag_outlined, size: 24),
            ),
          ),
          const Tab(icon: Icon(Icons.article_outlined, size: 24)),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return const CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: EmptyState(
              icon: Icons.article_outlined,
              title: 'Posts coming soon',
              subtitle: 'Stay tuned for updates.',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid(UserProfile profile) {
    if (_products.isEmpty) {
      return const CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No listings yet',
                subtitle: 'This user has not listed anything.',
              ),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8, left: 2, right: 2, bottom: 2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        final imageUrl = product.firstImageUrl;
        if (imageUrl == null || imageUrl.isEmpty) {
          return GestureDetector(
            onTap: () => _openProduct(product),
            child: Container(
              color: AppColors.surface,
              child: const Icon(Icons.image, color: AppColors.textSecondary),
            ),
          );
        }

        return GestureDetector(
          onTap: () => _openProduct(product),
          child: RepaintBoundary(
            child: CachedNetworkImage(
              key: ValueKey('other_profile_product_${product.id}_$imageUrl'),
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              useOldImageOnUrlChange: true,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (context, url) => Container(
                color: AppColors.surface,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surface,
                child: const Icon(Icons.image, color: AppColors.textSecondary),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openProduct(Product product) {
    Navigator.pushNamed(
      context,
      AppRoutes.productDetail,
      arguments: ProductDetailArgs(
        productId: product.id,
        initialProduct: product.toEntity(),
      ),
    );
  }
}

// Delegate for sticky tab bar in NestedScrollView
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate({required this.tabBar});

  final Widget tabBar;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return tabBar;
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}
