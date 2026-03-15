import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/repository_interfaces/i_user_repository.dart';
import '../../../data/models/community_post.dart';
import '../../../data/repositories/community_repository_impl.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../data/models/product.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../logic/view_models/saved_listings_view_model.dart';
import '../../../logic/view_models/marketplace_view_model.dart';
import '../../../logic/view_models/search_view_model.dart';
import '../../../logic/view_models/community_view_model.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/auth/auth_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../core/utils/extensions/state_extensions.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/full_screen_image_viewer.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_refresh_indicator.dart';
import 'widgets/profile_widgets.dart';
import '../marketplace/product_detail_page.dart';
import '../community/community_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app.dart';

final getIt = GetIt.instance;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin, RouteAware {
  late final TabController _tabController;
  late final IUserRepository _userRepository;
  late final CommunityRepository _communityRepository;

  List<Product> _products = [];
  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  bool _isUploadingCover = false;
  bool _isUploadingAvatar = false;
  bool _isSavingProfile = false;
  String? _error;
  bool _productsLoaded = false;

  // Using AppDimensions for layout constants

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserViewModel>();
    final profile = userProvider.profile;

    if (profile == null && userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppErrorMessages.resolve(_error)),
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
          child: AppRefreshIndicator(
            onRefresh: () async {
              await context.read<UserViewModel>().refresh();
              await refresh();
            },
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
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
                      schoolShortName: ProfileUtils.getSchoolShortName(profile.university),
                    ),
                    coverHeight: AppDimensions.profileCoverHeight,
                    avatarRadius: AppDimensions.profileAvatarRadius,
                    avatarBorder: AppDimensions.profileAvatarBorder,
                    avatarGap: AppDimensions.profileAvatarGap,
                    statsDetailGap: 10,
                    onCoverTap: profile.coverImage != null && profile.coverImage!.isNotEmpty && !_isUploadingCover
                        ? () => _viewFullScreen(profile.coverImage!)
                        : null,
                    onAvatarTap: profile.profileImage != null && profile.profileImage!.isNotEmpty && !_isUploadingAvatar
                        ? () => _viewFullScreen(profile.profileImage!)
                        : null,
                    coverOverlay: _buildCoverOverlay(profile),
                    avatarOverlay: _buildAvatarOverlay(),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    tabBar: _buildTabBar(context),
                    productCount: _products.length,
                    postCount: _posts.length,
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
        ),
      ],
    );
  }

  /// Reload product listings
  Future<void> refresh() async {
    await _loadProducts();
  }

  /// Build overlay for cover image (edit button, upload spinner, menu)
  Widget _buildCoverOverlay(UserEntity profile) {
    final coverUrl = profile.coverImage;
    final hasCover = coverUrl != null && coverUrl.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
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
            bottom: AppDimensions.profileAvatarTotalRadius + 10,
            right: 14,
            child: GestureDetector(
              onTap: _pickAndUploadCover,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 0.5),
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

        // Three-dot menu
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              padding: const EdgeInsets.all(8),
              onSelected: (value) {
                if (value == 'edit_profile') _openEditProfileDialog();
                if (value == 'logout') _handleLogout();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit_profile',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Edit profile'),
                    ],
                  ),
                ),
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

  /// Build overlay for avatar (camera button, upload spinner)
  Widget _buildAvatarOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Upload spinner over avatar
        if (_isUploadingAvatar)
          Container(
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
          )
        else
          // Camera badge to edit/upload
          Positioned(
            bottom: AppDimensions.profileAvatarGap + 2,
            right: AppDimensions.profileAvatarGap + 2,
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


  Widget _buildTabBar(BuildContext context) {
    final productCount = _products.length;
    final postCount = _posts.length;
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
          Tab(
            icon: Badge(
              label: Text('$postCount'),
              backgroundColor: AppColors.primary,
              textColor: Colors.white,
              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              child: const Icon(Icons.article_outlined, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return const CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyState(
                icon: Icons.article_outlined,
                title: 'No posts yet',
                subtitle: 'Share your first post with an image.',
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
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final imageUrl = post.orderedImages.first;

        return GestureDetector(
          onTap: () => _openPost(post),
          child: RepaintBoundary(
            child: CachedNetworkImage(
              key: ValueKey('profile_post_${post.id}_$imageUrl'),
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

  Widget _buildProductGrid() {
    if (_isLoading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return const CustomScrollView(
        slivers: [
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
          child: RepaintBoundary(
            child: CachedNetworkImage(
              key: ValueKey('profile_product_${product.id}_$imageUrl'),
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

  void _openPost(CommunityPost post) {
    Navigator.pushNamed(
      context,
      AppRoutes.communityDetail,
      arguments: CommunityDetailArgs(
        postId: post.id,
        initialPost: post,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _userRepository = getIt<IUserRepository>();
    _communityRepository = getIt<CommunityRepository>();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register with RouteObserver to detect when returning from other routes
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route as PageRoute);
    }
    
    if (!_productsLoaded) {
      final userId = context.read<UserViewModel>().userId;
      if (userId != null) {
        _productsLoaded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            refresh();
          }
        });
      }
    }
  }

  @override
  void didPopNext() {
    _productsLoaded = false;
    if (mounted) {
      refresh();  
    }
    super.didPopNext();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _tabController.dispose();
    super.dispose();
  }

  void _viewFullScreen(String imageUrl) {
    FullScreenImageViewer.show(context, imageUrl);
  }

  Future<void> _pickAndUploadCover() async {
    final userProvider = context.read<UserViewModel>();
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
        AppSnackBar.error(context, 'Failed to update cover');
      }
    } finally {
      setStateIfMounted(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final userProvider = context.read<UserViewModel>();
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
          statusBarLight: false,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          hideBottomControls: false,
          showCropGrid: true,
          cropFrameColor: AppColors.primary,
          cropGridColor: AppColors.primary.withValues(alpha: 0.5),
          activeControlsWidgetColor: AppColors.primary,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.5),
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
        AppSnackBar.error(context, 'Failed to update photo. Please try again.');
      } else {
        AppSnackBar.success(context, 'Photo updated successfully!');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Error uploading photo: $e');
    } finally {
      setStateIfMounted(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _handleLogout() async {
    if (mounted) {
      // Clear all ViewModels to ensure no data persists between user sessions
      context.read<ProductFeedViewModel>().clear();
      context.read<UserViewModel>().clear();
      context.read<SavedListingsViewModel>().clear();
      context.read<MarketplaceViewModel>().clear();
      context.read<SearchViewModel>().clear();
      context.read<CommunityViewModel>().clear();
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

  Future<void> _openEditProfileDialog() async {
    final userProvider = context.read<UserViewModel>();
    final profile = userProvider.profile;
    if (profile == null || _isSavingProfile) return;

    final result = await showDialog<_EditProfileResult>(
      context: context,
      builder: (_) => _EditProfileDialog(profile: profile),
    );

    if (!mounted || result == null) return;

    setState(() => _isSavingProfile = true);

    try {
      final success = await userProvider.updateProfile(
        fullName: result.fullName,
        bio: result.bio,
        major: result.major,
      );

      if (!mounted) return;

      if (success) {
        AppSnackBar.success(context, 'Profile updated successfully.');
      } else {
        AppSnackBar.error(
          context,
          userProvider.error ?? 'Failed to update profile.',
        );
      }
    } finally {
      setStateIfMounted(() => _isSavingProfile = false);
    }
  }

  Future<void> _loadProfile() async {
    final userProvider = context.read<UserViewModel>();
    // Ensure user profile is loaded in the provider
    if (userProvider.profile == null && !userProvider.isLoading) {
      await userProvider.load();
    }
    await refresh();
  }

  Future<void> _loadProducts() async {
    final userId = context.read<UserViewModel>().userId;
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
      final postsResponse = await _communityRepository.getPosts(
        feed: 'community',
        userId: userId,
        limit: 50,
        offset: 0,
      );

      if (!productsResponse.isSuccess) {
        throw productsResponse.error!;
      }
      if (!postsResponse.isSuccess) {
        throw postsResponse.error!;
      }

      setStateIfMounted(() {
        _products = (productsResponse.data ?? []).toModels();
        _posts = (postsResponse.data ?? [])
            .where((post) => post.orderedImages.isNotEmpty)
            .toList();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setStateIfMounted(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

}

// Delegate for sticky tab bar in NestedScrollView
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _StickyTabBarDelegate({
    required this.tabBar,
    required this.productCount,
    required this.postCount,
  });

  final Widget tabBar;
  final int productCount;
  final int postCount;

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
    return productCount != oldDelegate.productCount ||
        postCount != oldDelegate.postCount;
  }
}

class _EditProfileResult {
  const _EditProfileResult({
    required this.fullName,
    this.bio,
    this.major,
  });

  final String fullName;
  final String? bio;
  final String? major;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile});

  final UserEntity profile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _majorController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _majorController = TextEditingController(text: widget.profile.major ?? '');
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _majorController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  hintText: 'Enter your full name',
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Full name is required';
                  if (text.length < 2) return 'Full name is too short';
                  return null;
                },
              ),
              TextFormField(
                controller: _majorController,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Major',
                  hintText: 'E.g. Computer Science',
                ),
              ),
              TextFormField(
                controller: _bioController,
                minLines: 3,
                maxLines: 4,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  hintText: 'Tell people about yourself',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final fullName = _nameController.text.trim();
    final major = _majorController.text.trim();
    final bio = _bioController.text.trim();

    Navigator.pop(
      context,
      _EditProfileResult(
        fullName: fullName,
        major: major.isEmpty ? null : major,
        bio: bio.isEmpty ? null : bio,
      ),
    );
  }
}

