import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../data/dtos/category_dto.dart';
import '../../../data/dtos/user_profile_dto.dart';
import '../../../data/dtos/product_dto.dart';
import '../../../logic/helpers/product_like_helpers.dart';
import '../../../logic/view_models/search_view_model.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/presence_view_model.dart';
import '../../../logic/view_models/user_view_model.dart';
import '../../../core/utils/user_presence_formatter.dart';
import '../../widgets/product_grid_card.dart';
import '../../widgets/category_filter_strip.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/user_widgets.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_refresh_indicator.dart';
import '../../widgets/loading_error_builder.dart';
import '../../../core/navigation/app_routes.dart';
import '../marketplace/product_detail_page.dart';
import '../profile/other_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => SearchPageState();
}
class SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isBootstrapping = true;
  late final FocusNode _searchFocusNode;
  final Map<int, ValueNotifier<int>> _optimisticLikeNotifiers =
      <int, ValueNotifier<int>>{};

  late final TabController _tabController;
  late final ScrollController _productsScrollController;
  late final ScrollController _studentsScrollController;

  // Optimistic like state for instant UI feedback
  final Set<int> _optimisticallyLikedIds = {};
  final Set<int> _optimisticallyUnlikedIds = {};
  final Set<int> _likingProductIds = {};

  static const PageStorageKey<String> _productsGridStorageKey =
      PageStorageKey<String>('search-products-grid');
  static const PageStorageKey<String> _studentsListStorageKey =
      PageStorageKey<String>('search-students-list');

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode = FocusNode();
    _productsScrollController = ScrollController();
    _productsScrollController.addListener(_onScroll);
    _studentsScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  void _onScroll() {
    // Load more products when user scrolls near the bottom
    if (!_productsScrollController.hasClients) return;

    if (_productsScrollController.position.pixels >=
        _productsScrollController.position.maxScrollExtent - 500) {
      final productFeedVm = context.read<ProductFeedViewModel>();
      if (productFeedVm.hasMore && !productFeedVm.isLoadingMore) {
        productFeedVm.loadNextPage();
      }
    }
  }

  Future<void> scrollToTopAndRefresh() async {
    if (!mounted) return;

    if (_tabController.index == 0) {
      if (_productsScrollController.hasClients &&
          _productsScrollController.offset > 0) {
        await _productsScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }

      if (!mounted) return;
      await context.read<ProductFeedViewModel>().refresh();
      return;
    }

    if (_studentsScrollController.hasClients && _studentsScrollController.offset > 0) {
      await _studentsScrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }

    if (!mounted) return;
    await context.read<SearchViewModel>().loadUsers();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _productsScrollController.removeListener(_onScroll);
    _productsScrollController.dispose();
    _studentsScrollController.dispose();
    for (final notifier in _optimisticLikeNotifiers.values) {
      notifier.dispose();
    }
    _optimisticLikeNotifiers.clear();
    super.dispose();
  }

  void _onTabChanged() {
    final nextIndex = _tabController.index;
    context.read<SearchViewModel>().toggleUserSearch(nextIndex == 1);
  }

  ValueNotifier<int> _likeNotifierFor(int productId) {
    return _optimisticLikeNotifiers.putIfAbsent(
      productId,
      () => ValueNotifier<int>(0),
    );
  }

  void _notifyOptimisticLikeChanged(int productId) {
    _likeNotifierFor(productId).value++;
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    if (!_isBootstrapping) {
      setState(() {
        _isBootstrapping = true;
      });
    }

    try {
      // Load categories and ensure products are loaded
      final searchViewModel = context.read<SearchViewModel>();
      final productFeedViewModel = context.read<ProductFeedViewModel>();

      await searchViewModel.loadCategories();

      if (mounted && productFeedViewModel.products.isEmpty) {
        await productFeedViewModel.load();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapping = false;
        });
      }
    }
  }

  /// Effective like status considering optimistic overrides
  bool _isLiked(ProductDto product) {
    if (_optimisticallyLikedIds.contains(product.id)) return true;
    if (_optimisticallyUnlikedIds.contains(product.id)) return false;
    return ProductLikeHelpers.isLikedByUser(
      product: product,
      userId: context.read<UserViewModel>().userId,
    );
  }

  void _onSearchChanged() {
    context.read<SearchViewModel>().setSearchQuery(_searchController.text);
  }

  List<ProductDto> _getFilteredProductsFromData(
    List<ProductDto> allProducts,
    String searchQuery,
    int? selectedCategoryIndex,
    List<CategoryDto> categories,
  ) {
    List<ProductDto> filtered = allProducts;

    if (searchQuery.isNotEmpty) {
      final searchTerm = searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (product) =>
                product.title.toLowerCase().contains(searchTerm) ||
                (product.description?.toLowerCase().contains(searchTerm) ??
                    false),
          )
          .toList();
    }

    if (selectedCategoryIndex != null) {
      final selectedIndex = selectedCategoryIndex;
      if (selectedIndex < categories.length) {
        final selectedCategory = categories[selectedIndex];
        filtered = filtered
            .where((product) => product.categoryId == selectedCategory.id)
            .toList();
      }
    }

    return filtered;
  }

  Future<void> _handleLikeTap(ProductDto product) async {
    if (_likingProductIds.contains(product.id)) return;

    final isCurrentlyLiked = _isLiked(product);

    _likingProductIds.add(product.id);
    if (isCurrentlyLiked) {
      _optimisticallyLikedIds.remove(product.id);
      _optimisticallyUnlikedIds.add(product.id);
    } else {
      _optimisticallyUnlikedIds.remove(product.id);
      _optimisticallyLikedIds.add(product.id);
    }
    _notifyOptimisticLikeChanged(product.id);

    HapticFeedback.lightImpact();

    try {
      final provider = context.read<ProductFeedViewModel>();
      final userId = context.read<UserViewModel>().userId;

      if (isCurrentlyLiked) {
        final likeRecord = ProductLikeHelpers.findUserLike(
          product: product,
          userId: userId,
        );
        if (likeRecord != null) {
          await provider.unlikeProduct(
            productId: product.id,
            likeId: likeRecord.id,
          );
        }
      } else {
        await provider.likeProduct(product.id);
      }
    } catch (e) {
      debugPrint('Like operation error: $e');
      // Revert optimistic update on error
      if (mounted) {
        if (isCurrentlyLiked) {
          _optimisticallyUnlikedIds.remove(product.id);
        } else {
          _optimisticallyLikedIds.remove(product.id);
        }
        _notifyOptimisticLikeChanged(product.id);
        AppSnackBar.error(
          context,
          isCurrentlyLiked
              ? 'Failed to unlike product'
              : 'Failed to like product',
        );
      }
    } finally {
      if (mounted) {
        _likingProductIds.remove(product.id);
        _optimisticallyLikedIds.remove(product.id);
        _optimisticallyUnlikedIds.remove(product.id);
        _notifyOptimisticLikeChanged(product.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Use Selector to rebuild only when specific fields change
    return Selector2<
      SearchViewModel,
      ProductFeedViewModel,
      ({
        bool isLoading,
        String? error,
        int categoriesCount,
        int productsCount,
        bool productsLoading,
        String? productsError,
      })
    >(
      selector: (_, searchVm, productVm) => (
        isLoading: searchVm.isLoading,
        error: searchVm.error,
        categoriesCount: searchVm.categories.length,
        productsCount: productVm.products.length,
        productsLoading: productVm.isLoading,
        productsError: productVm.error,
      ),
      builder: (context, data, _) {
        final isInitialLoad = data.categoriesCount == 0 || data.productsCount == 0;
        final isLoading = _isBootstrapping || data.isLoading || data.productsLoading;
        final error = data.error ?? data.productsError;

        return _buildContent(context, isInitialLoad, isLoading, error);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isInitialLoad,
    bool isLoading,
    String? error,
  ) {
    final productFeedViewModel = context.read<ProductFeedViewModel>();
    return LoadingErrorBuilder(
      isLoading: isLoading,
      isInitialLoad: isInitialLoad,
      error: error,
      onRetry: () async {
        await _loadInitialData();
        await productFeedViewModel.refresh();
      },
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildStudentsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Selector<
      SearchViewModel,
      ({
        List<CategoryDto> categories,
        int? selectedCategoryIndex,
        bool showCategoryFilter,
      })
    >(
      selector: (_, vm) => (
        categories: vm.categories,
        selectedCategoryIndex: vm.selectedCategoryIndex,
        showCategoryFilter: vm.showCategoryFilter,
      ),
      builder: (context, data, _) {
        return AnimatedBuilder(
          animation: Listenable.merge([_tabController, _searchFocusNode]),
          builder: (context, _) => _buildHeaderContent(
            context,
            data.categories,
            data.selectedCategoryIndex,
            data.showCategoryFilter,
            _tabController.index == 0,
          ),
        );
      },
    );
  }

  Widget _buildHeaderContent(
    BuildContext context,
    List<CategoryDto> categories,
    int? selectedCategoryIndex,
    bool showCategoryFilter,
    bool onProductsTab,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.background,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedSize(
                duration: AppDurations.fast,
                curve: Curves.easeInOut,
                child: _searchFocusNode.hasFocus
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          dividerColor: Colors.transparent,
                          tabs: const [
                            Tab(text: 'Products'),
                            Tab(text: 'Students'),
                          ],
                        ),
                      ),
              ),
              // Search bar always visible on the right
              Expanded(
                child: SearchBarWidget(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        // Category filter strip
        if (onProductsTab && categories.isNotEmpty)
          CategoryFilterStrip(
            categories: categories,
            selectedIndex: selectedCategoryIndex,
            onCategorySelected: (index) =>
                context.read<SearchViewModel>().selectCategory(index),
            isOpen: showCategoryFilter,
            onToggle: () =>
                context.read<SearchViewModel>().toggleCategoryFilter(),
          ),
      ],
    );
  }

  // Products tab
  Widget _buildProductsTab() {
    final productFeedViewModel = context.read<ProductFeedViewModel>();
    return AppRefreshIndicator(
      onRefresh: () async {
        await productFeedViewModel.refresh();
      },
      child: Selector2<
        SearchViewModel,
        ProductFeedViewModel,
        ({
          List<CategoryDto> categories,
          String searchQuery,
          int? selectedCategoryIndex,
          List<ProductDto> products,
        })
      >(
        selector: (_, searchVm, productVm) => (
          categories: searchVm.categories,
          searchQuery: searchVm.searchQuery,
          selectedCategoryIndex: searchVm.selectedCategoryIndex,
          products: productVm.products,
        ),
        builder: (context, data, _) {
          final filteredProducts = _getFilteredProductsFromData(
            data.products,
            data.searchQuery,
            data.selectedCategoryIndex,
            data.categories,
          );
          final filteredProductIds = filteredProducts
              .map((product) => product.id)
              .toList(growable: false);

          return _buildProductGrid(filteredProductIds);
        },
      ),
    );
  }

  Widget _buildProductGrid(List<int> filteredProductIds) {
    if (filteredProductIds.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your search or filters',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      key: _productsGridStorageKey,
      controller: _productsScrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredProductIds.length,
      itemBuilder: (context, index) {
        final productId = filteredProductIds[index];
        return Selector<ProductFeedViewModel, ProductDto?>(
          selector: (_, vm) => vm.getCachedProduct(productId),
          builder: (context, product, _) {
            if (product == null) {
              return const SizedBox.shrink();
            }

            return ValueListenableBuilder<int>(
              valueListenable: _likeNotifierFor(product.id),
              builder: (context, value, child) {
                final isLiked = _isLiked(product);
                return ProductGridCard(
                  key: ValueKey(product.id),
                  product: product,
                  isLiked: isLiked,
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
                  onLikeTap: () => _handleLikeTap(product),
                );
              },
            );
          },
        );
      },
    );
  }

  // Students tab
  Widget _buildStudentsTab() {
    return Selector<
      SearchViewModel,
      ({
        bool isLoadingUsers,
        List<UserProfileDto> users,
        String searchQuery,
        Set<int> updatingFollowUserIds,
      })
    >(
      selector: (_, vm) => (
        isLoadingUsers: vm.isLoadingUsers,
        users: vm.users,
        searchQuery: vm.searchQuery,
        updatingFollowUserIds: Set<int>.from(vm.updatingFollowUserIds),
      ),
      builder: (context, data, _) {
        if (data.isLoadingUsers) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = _getFilteredUsersFromData(
          data.users,
          data.searchQuery,
        );

        return Consumer<PresenceViewModel>(
          builder: (context, presenceViewModel, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              presenceViewModel.watchUserIds(
                filtered.map((user) => user.id).where((id) => id > 0),
              );
            });

            return AppRefreshIndicator(
              onRefresh: () async {
                await context.read<SearchViewModel>().loadUsers();
              },
              child: _buildStudentsContent(
                context,
                filtered,
                data.updatingFollowUserIds,
                presenceViewModel,
              ),
            );
          },
        );
      },
    );
  }

  List<UserProfileDto> _getFilteredUsersFromData(
    List<UserProfileDto> users,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return users;
    final searchTerm = searchQuery.toLowerCase();
    return users.where((user) {
      return user.fullName.toLowerCase().contains(searchTerm) ||
          user.email.toLowerCase().contains(searchTerm) ||
          (user.university?.name.toLowerCase().contains(searchTerm) ?? false);
    }).toList();
  }

  Widget _buildStudentsContent(
    BuildContext context,
    List<UserProfileDto> filtered,
    Set<int> updatingFollowUserIds,
    PresenceViewModel presenceViewModel,
  ) {
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_search,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different name or university',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      key: _studentsListStorageKey,
      controller: _studentsScrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];
        final realtimePresence = presenceViewModel.presenceForUser(user.id);
        final isOnline = realtimePresence?.isOnline ?? user.isOnline;
        final lastSeenAt = realtimePresence?.lastSeenAt ?? user.lastSeenAt;
        final statusLabel = buildPresenceLabel(
          isOnline: isOnline,
          lastSeenAt: lastSeenAt,
        );
        final university = user.university?.name.trim() ?? '';
        final subtitle = university.isEmpty
            ? statusLabel
            : '$university \u00B7 $statusLabel';
        final currentUserId = context.read<UserViewModel>().userId;
        final isCurrentUser = currentUserId == user.id;
        return UserProfileListTile(
          user: user,
          subtitle: subtitle,
          showStatusDot: true,
          statusDotColor: presenceColor(isOnline: isOnline),
          isFollowing: user.isFollowing,
          isFollowLoading: updatingFollowUserIds.contains(user.id),
          showFollowButton: !isCurrentUser,
          onTap: () async {
            if (currentUserId == user.id) {
              // Navigate to own profile tab
              await Navigator.pushNamed(context, AppRoutes.profile);
            } else {
              // Navigate to other user's profile
              await Navigator.pushNamed(
                context,
                AppRoutes.userProfile,
                arguments: OtherProfileArgs(userId: user.id),
              );
            }

            if (!context.mounted) return;
            await context.read<SearchViewModel>().loadUsers();
          },
          onFollowTap: isCurrentUser
              ? null
              : () async {
                  final nextIsFollowing = !user.isFollowing;
                  final ok = await context.read<SearchViewModel>().toggleFollow(user.id);
                  if (ok && context.mounted) {
                    context
                        .read<UserViewModel>()
                        .adjustFollowingCount(increment: nextIsFollowing);
                  }
                  if (!ok && context.mounted) {
                    AppSnackBar.error(
                      context,
                      context.read<SearchViewModel>().actionError ??
                          'Failed to update follow status',
                    );
                  }
                },
        );
      },
    );
  }
}
