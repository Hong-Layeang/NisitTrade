import 'package:flutter/material.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/product.dart';
import '../../../models/user_profile.dart';
import '../../../services/api/api_exception.dart';
import '../../../utils/constants/colors.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/profile/profile_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final UserRepository _userRepository = UserRepositoryImpl();

  static const _coverImageUrl =
      'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800';
  static const _placeholderAvatar = 'https://i.pravatar.cc/300?img=12';

  UserProfile? _profile;
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  // ── Layout constants ──
  static const double _coverHeight = 220;
  static const double _avatarRadius = 65;
  static const double _avatarBorder = 3;
  static const double _avatarGap = 3;
  static const double _avatarTotalRadius =
      _avatarRadius + _avatarGap + _avatarBorder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
          ],
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Expanded(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildCoverAndAvatar(),
                      _buildStatsRow(),
                      _buildNameAndBio(textTheme),
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
              children: [_buildProductGrid(), _buildFriendsTab()],
            ),
          ),
        ),
      ],
    );
  }

  /// Cover image with overlapping avatar and three-dot menu
  Widget _buildCoverAndAvatar() {
    final avatarUrl = _profile?.profileImage ?? _placeholderAvatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image
        SizedBox(
          height: _coverHeight,
          width: double.infinity,
          child: Image.network(
            _coverImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.accent.withOpacity(0.3),
              child: const Icon(Icons.image, size: 48, color: Colors.white54),
            ),
          ),
        ),
        // Three-dot menu
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ),
        // Profile avatar overlapping bottom of cover
        Positioned(
          bottom: -_avatarTotalRadius,
          left: 0,
          right: 0,
          child: Center(
            child: ProfileAvatar(
              imageUrl: avatarUrl,
              radius: _avatarRadius,
              borderWidth: _avatarBorder,
              gapWidth: _avatarGap,
            ),
          ),
        ),
      ],
    );
  }

  /// Stats flanking the avatar overlap area
  Widget _buildStatsRow() {
    final institution = _profile?.university?.name ?? 'Unknown';
    final role = _profile?.role ?? 'User';
    final itemsSold = _products.length.toString();
    return SizedBox(
      height: _avatarTotalRadius + 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Left stats
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ProfileStatItem(
                    icon: Icons.people_outline,
                    value: '0',
                    label: 'Friends',
                  ),
                  const SizedBox(height: 6),
                  ProfileStatItem(
                    icon: Icons.shopping_cart_outlined,
                    value: itemsSold,
                    label: 'items sold',
                  ),
                ],
              ),
              ),
            ),
            // Center gap for avatar
            SizedBox(width: _avatarTotalRadius * 2),
            // Right stats
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ProfileStatItem(
                    icon: Icons.inventory_2_outlined,
                    value: institution,
                  ),
                  const SizedBox(height: 6),
                  ProfileStatItem(icon: Icons.verified_outlined, value: role),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Profile name and bio text
  Widget _buildNameAndBio(TextTheme textTheme) {
    final profile = _profile;
    final name = profile?.fullName ?? 'User';
    final bio = profile?.email ?? 'No bio available.';
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
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on, size: 28)),
          Tab(icon: Icon(Icons.people_outline, size: 28)),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: EmptyState(
        icon: Icons.group_outlined,
        title: 'Friends coming soon',
        subtitle: 'Stay tuned for updates.',
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No items yet',
          subtitle: 'List your first item for sale.',
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
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
          return Container(
            color: AppColors.surface,
            child: const Icon(Icons.image, color: AppColors.textSecondary),
          );
        }

        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.surface,
            child: const Icon(Icons.image, color: AppColors.textSecondary),
          ),
        );
      },
    );
  }

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
      final userResponse = await _userRepository.getCurrentUser();
      if (!userResponse.isSuccess) {
        throw userResponse.error!;
      }

      final profile = userResponse.data;
      final productsResponse = await _userRepository.getUserProducts(
        userId: profile!.id,
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
