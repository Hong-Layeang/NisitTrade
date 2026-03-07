import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user_profile.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/profile/profile_widgets.dart';
import '../marketplace/product_detail_page.dart';

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
  final UserRepository _userRepository = UserRepositoryImpl();

  UserProfile? _profile;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  bool _isFollowing = false;

  // ── Layout constants ──
  static const double _coverHeight = 220;
  static const double _avatarRadius = 65;
  static const double _avatarBorder = 3;
  static const double _avatarGap = 3;
  static const double _avatarTotalRadius =
      _avatarRadius + _avatarGap + _avatarBorder;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

      if (mounted) {
        setState(() {
          _profile = profile;
          _products = productsResponse.data ?? [];
          _isFollowing = profile.isFollowing;
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
                    child: Column(
                      children: [
                        _buildCoverAndAvatar(profile),
                        _buildStatsRow(profile),
                        _buildNameAndBio(textTheme, profile),
                        const SizedBox(height: 16),
                      ],
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

  Widget _buildCoverPlaceholder() {
    return const ColoredBox(color: Colors.black);
  }

  Widget _buildCoverAndAvatar(UserProfile profile) {
    final coverUrl = profile.coverImage;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image (server data) or gradient placeholder
        SizedBox(
          height: _coverHeight,
          width: double.infinity,
          child: coverUrl != null && coverUrl.isNotEmpty
              ? Image.network(
                  coverUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                )
              : _buildCoverPlaceholder(),
        ),
        // Profile avatar overlapping bottom of cover
        Positioned(
          bottom: -_avatarTotalRadius,
          left: 0,
          right: 0,
          child: Center(
            child: ProfileAvatar(
              imageUrl: profile.profileImage,
              displayName: profile.fullName,
              radius: _avatarRadius,
              borderWidth: _avatarBorder,
              gapWidth: _avatarGap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(UserProfile profile) {
    final schoolShort = _getSchoolShortName(profile);
    return SizedBox(
      height: _avatarTotalRadius + 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildCountStat(
                    Icons.person_add_outlined,
                    '${profile.followerCount}',
                    'Followers',
                  ),
                  const SizedBox(height: 10),
                  _buildCountStat(
                    Icons.people_outline,
                    '${profile.followingCount}',
                    'Following',
                  ),
                ],
              ),
            ),
            // Center gap for avatar
            SizedBox(width: _avatarTotalRadius * 2 + 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileStatItem(
                    icon: Icons.school_outlined,
                    value: profile.major ?? 'N/A',
                  ),
                  const SizedBox(height: 20),
                  ProfileStatItem(
                    icon: Icons.verified_outlined,
                    value: schoolShort,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountStat(IconData icon, String count, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Extract a short school abbreviation from the university's name.
  /// e.g. "Cambodian Academy of Digital Technology" → "CADT"
  String _getSchoolShortName(UserProfile profile) {
    final university = profile.university;
    if (university == null) return 'N/A';

    // Try abbreviation from name first
    const skipWords = {'of', 'the', 'and', 'in', 'at', 'for', 'a', 'an', 'to'};
    final nameParts = university.name.trim().split(RegExp(r'\s+'));
    final initials = nameParts
        .where((w) => w.isNotEmpty && !skipWords.contains(w.toLowerCase()))
        .map((w) => w[0].toUpperCase())
        .join();
    if (initials.isNotEmpty) return initials;

    // Fallback: parse domain
    const excluded = {'student', 'mail', 'www', 'edu', 'ac', 'com', 'org', 'net', 'kh'};
    final domainParts = university.domain.split('.');
    final meaningful = domainParts.where(
      (p) => p.length > 2 && !excluded.contains(p.toLowerCase()),
    );
    if (meaningful.isNotEmpty) return meaningful.first.toUpperCase();
    return domainParts.isNotEmpty ? domainParts.first.toUpperCase() : 'N/A';
  }

  Widget _buildNameAndBio(TextTheme textTheme, UserProfile profile) {
    final name = profile.fullName;
    final bio = (profile.bio != null && profile.bio!.isNotEmpty)
        ? profile.bio!
        : 'No bio yet.';
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          name,
          style: textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            bio,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
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
        ),
      ],
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
    return CustomScrollView(
      slivers: const [
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
      return CustomScrollView(
        slivers: const [
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
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surface,
              child: const Icon(Icons.image, color: AppColors.textSecondary),
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
      arguments: ProductDetailArgs(productId: product.id),
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
