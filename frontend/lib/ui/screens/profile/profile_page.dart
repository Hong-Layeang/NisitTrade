import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user_profile.dart';
import '../../../logic/state_managers/product_feed_provider.dart';
import '../../../logic/state_managers/user_provider.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_routes.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/full_screen_image_viewer.dart';
import '../../widgets/profile/profile_widgets.dart';
import '../marketplace/product_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final UserRepository _userRepository = UserRepositoryImpl();

  List<Product> _products = [];
  bool _isLoading = false;
  bool _isUploadingCover = false;
  bool _isUploadingAvatar = false;
  String? _error;
  bool _productsLoaded = false;

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
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;

    if (profile == null && userProvider.isLoading) {
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
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          _buildCoverAndAvatar(),
                          _buildStatsRow(),
                          _buildNameAndBio(textTheme),
                          const SizedBox(height: 16),
                        ],
                      ),
                      // Avatar + camera button live here so they are inside
                      // this Stack's layout bounds and are always hittable.
                      // (If placed inside _buildCoverAndAvatar with a negative
                      // bottom offset they fall outside that Stack's 220 px
                      // layout height and Flutter's hit-test ignores them.)
                      Positioned(
                        top: _coverHeight - _avatarTotalRadius,
                        left: 0,
                        right: 0,
                        child: Center(child: _buildAvatarWithCamera()),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    tabBar: _buildTabBar(context),
                    productCount: _products.length,
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [_buildProductGrid(), _buildPostsTab()],
            ),
          ),
        ),
      ],
    );
  }

  /// Reload product listings
  Future<void> refresh() async {
    await _loadProducts();
  }

  /// Cover image (no avatar – avatar is overlaid at the SliverToBoxAdapter level)
  Widget _buildCoverAndAvatar() {
    final profile = context.read<UserProvider>().profile;
    final coverUrl = profile?.coverImage;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

    return Stack(
      children: [
        // Cover
        GestureDetector(
          onTap: hasCover && !_isUploadingCover
              ? () => _viewFullScreen(coverUrl)
              : null,
          child: SizedBox(
            height: _coverHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background
                hasCover
                    ? Image.network(
                        coverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildCoverPlaceholder(),
                      )
                    : _buildCoverPlaceholder(),

                // Dim + spinner while uploading
                if (_isUploadingCover)
                  const ColoredBox(
                    color: Colors.black54,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),

                // Add / Edit cover button
                if (!_isUploadingCover)
                  Positioned(
                    bottom: _avatarTotalRadius + 10,
                    right: 14,
                    child: GestureDetector(
                      onTap: _pickAndUploadCover,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasCover
                                  ? Icons.camera_alt_outlined
                                  : Icons.add_photo_alternate_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hasCover ? 'Edit' : 'Add cover',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
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
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              padding: const EdgeInsets.all(8),
              onSelected: (value) {
                if (value == 'logout') _handleLogout();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Log out',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Avatar circle + camera-badge button.
  /// Rendered as a Positioned overlay at the SliverToBoxAdapter Stack level
  /// so the camera badge is always within hit-test bounds.
  Widget _buildAvatarWithCamera() {
    final userProvider = context.read<UserProvider>();
    final profile = userProvider.profile;
    final avatarUrl = profile?.profileImage;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Tap avatar → full-screen viewer
        GestureDetector(
          onTap: hasAvatar && !_isUploadingAvatar
              ? () => _viewFullScreen(avatarUrl)
              : null,
          child: ProfileAvatar(
            imageUrl: profile?.profileImage,
            displayName: profile?.fullName,
            radius: _avatarRadius,
            borderWidth: _avatarBorder,
            gapWidth: _avatarGap,
          ),
        ),
        // Upload spinner over avatar
        if (_isUploadingAvatar)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          )
        else
          // Camera badge → edit/upload
          Positioned(
            bottom: _avatarGap + 2,
            right: _avatarGap + 2,
            child: GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 13),
              ),
            ),
          ),
      ],
    );
  }

  /// Stats flanking the avatar overlap area
  Widget _buildStatsRow() {
    final profile = context.read<UserProvider>().profile;
    final schoolShort = _getSchoolShortName(profile);
    return SizedBox(
      height: _avatarTotalRadius + 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: followers + following, right-aligned towards avatar
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildCountStat(
                    Icons.person_add_outlined,
                    '${profile?.followerCount ?? 0}',
                    'Followers',
                  ),
                  const SizedBox(height: 10),
                  _buildCountStat(
                    Icons.people_outline,
                    '${profile?.followingCount ?? 0}',
                    'Following',
                  ),
                ],
              ),
            ),
            // Center gap for avatar
            SizedBox(width: _avatarTotalRadius * 2 + 16),
            // Right: major + school, left-aligned towards avatar
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileStatItem(
                    icon: Icons.school_outlined,
                    value: profile?.major ?? 'N/A',
                  ),
                  const SizedBox(height: 10),
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

  /// Count stat with icon: [icon] bold-number / small-label
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
  String _getSchoolShortName(UserProfile? profile) {
    final university = profile?.university;
    if (university == null) return 'N/A';

    // Try abbreviation from name first (first letter of each significant word)
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

  /// Profile name and bio text
  Widget _buildNameAndBio(TextTheme textTheme) {
    final profile = context.read<UserProvider>().profile;
    final name = profile?.fullName ?? 'User';
    final bio = (profile?.bio != null && profile!.bio!.isNotEmpty)
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

  Widget _buildProductGrid() {
    if (_isLoading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return CustomScrollView(
        slivers: const [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No items yet',
                subtitle: 'List your first item for sale.',
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_productsLoaded) {
      final userId = context.read<UserProvider>().userId;
      if (userId != null) {
        _productsLoaded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadProducts();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildCoverPlaceholder() {
    return const ColoredBox(color: Colors.black);
  }

  void _viewFullScreen(String imageUrl) {
    FullScreenImageViewer.show(context, imageUrl);
  }

  Future<void> _pickAndUploadCover() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.profile == null || _isUploadingCover) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingCover = true);

    try {
      final newUrl = await userProvider.updateCover(
        userId: userProvider.profile!.id,
        filePath: picked.path,
      );

      if (!mounted) return;

      if (newUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update cover')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final userProvider = context.read<UserProvider>();
    if (userProvider.profile == null || _isUploadingAvatar) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    // Crop the selected image
    final cropper = ImageCropper();
    final croppedFile = await cropper.cropImage(
      sourcePath: picked.path,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          statusBarColor: AppColors.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
          showCropGrid: true,
          cropFrameColor: AppColors.primary,
          cropGridColor: AppColors.primary.withOpacity(0.5),
          activeControlsWidgetColor: AppColors.primary,
          dimmedLayerColor: Colors.black.withOpacity(0.5),
          cropGridRowCount: 3,
          cropGridColumnCount: 3,
          cropStyle: CropStyle.rectangle,
        ),
        IOSUiSettings(
          title: 'Crop Avatar',
          cancelButtonTitle: 'Cancel',
          doneButtonTitle: 'Done',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );

    if (croppedFile == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final newUrl = await userProvider.updateAvatar(
        userId: userProvider.profile!.id,
        filePath: croppedFile.path,
      );

      if (!mounted) return;

      if (newUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update photo. Please try again.')),
        );
      } else {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _handleLogout() async {
    if (mounted) {
      context.read<ProductFeedProvider>().clear();
      context.read<UserProvider>().clear();
    }
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.welcome,
        (route) => false,
      );
    }
  }

  Future<void> _loadProfile() async {
    final userProvider = context.read<UserProvider>();
    // Ensure user profile is loaded in the provider
    if (userProvider.profile == null && !userProvider.isLoading) {
      await userProvider.load();
    }
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final userId = context.read<UserProvider>().userId;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productsResponse = await _userRepository.getUserProducts(
        userId: userId,
        limit: 50,
        offset: 0,
      );

      if (!productsResponse.isSuccess) {
        throw productsResponse.error!;
      }

      if (mounted) {
        setState(() {
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
  const _StickyTabBarDelegate({
    required this.tabBar,
    required this.productCount,
  });

  final Widget tabBar;
  final int productCount;

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
    return productCount != oldDelegate.productCount;
  }
}
