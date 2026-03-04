import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../utils/constants/colors.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/category.dart';
import '../../../models/like.dart';
import '../../../models/product.dart';
import '../../../models/user_profile.dart';
import '../../../services/api/api_exception.dart';
import '../../../providers/product_feed_provider.dart';
import '../../widgets/common/product_grid_card.dart';
import '../../widgets/common/category_filter_strip.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../../widgets/common/user_widgets.dart';
import '../../../utils/routes/app_routes.dart';
import '../marketplace/product_detail_page.dart';
import '../profile/other_profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  bool _showCategoryFilter = false;
  final CategoryRepository _categoryRepository = CategoryRepositoryImpl();
  final UserRepository _userRepository = UserRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();
  late final FocusNode _searchFocusNode;
  bool _searchFocused = false;

  late final TabController _tabController;

  // Products tab state
  List<Category>? _categories;
  int? _selectedCategoryIndex;

  // Students tab state
  List<UserProfile> _allUsers = [];
  bool _usersLoaded = false;

  // Shared state
  bool _isLoading = false;
  String? _error;
  int? _currentUserId;

  // Optimistic like state for instant UI feedback
  final Set<int> _optimisticallyLikedIds = {};
  final Set<int> _optimisticallyUnlikedIds = {};
  final Set<int> _likingProductIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode = FocusNode();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // Load students lazily when the tab is first visited
    if (_tabController.index == 1 && !_usersLoaded) {
      _loadUsers();
    }
    setState(() {});
  }

  void _onSearchFocusChanged() {
    setState(() => _searchFocused = _searchFocusNode.hasFocus);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userResponse = await _userRepository.getCurrentUser();
      if (userResponse.isSuccess) {
        _currentUserId = userResponse.data?.id;
      }

      // Load categories
      final categoriesResponse = await _categoryRepository.getCategories();
      if (!categoriesResponse.isSuccess) {
        throw categoriesResponse.error!;
      }

      // Ensure products are loaded in the shared provider
      if (mounted) {
        final provider = context.read<ProductFeedProvider>();
        if (provider.products.isEmpty && !provider.isLoading) {
          await provider.load();
        }
      }

      if (mounted) {
        setState(() {
          _categories = categoriesResponse.data;
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

  Future<void> _loadUsers() async {
    try {
      final response = await _userRepository.getAllUsers(limit: 100);
      if (response.isSuccess && mounted) {
        setState(() {
          _allUsers = response.data ?? [];
          _usersLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _usersLoaded = true);
    }
  }

  Like? _findUserLike(Product product) {
    final userId = _currentUserId;
    if (userId == null) return null;

    for (final like in product.likes) {
      if (like.userId == userId) {
        return like;
      }
    }
    return null;
  }

  /// Effective like status considering optimistic overrides
  bool _isLiked(Product product) {
    if (_optimisticallyLikedIds.contains(product.id)) return true;
    if (_optimisticallyUnlikedIds.contains(product.id)) return false;
    return _findUserLike(product) != null;
  }

  void _onSearchChanged() {
    setState(() {}); // Trigger rebuild to recompute filtered lists
  }

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    List<Product> filtered = allProducts;

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where((product) =>
              product.title.toLowerCase().contains(searchTerm) ||
              (product.description?.toLowerCase().contains(searchTerm) ??
                  false))
          .toList();
    }

    if (_selectedCategoryIndex != null && _categories != null) {
      final selectedCategory = _categories![_selectedCategoryIndex!];
      filtered = filtered
          .where((product) => product.categoryId == selectedCategory.id)
          .toList();
    }

    return filtered;
  }

  List<UserProfile> _getFilteredUsers() {
    if (_searchController.text.isEmpty) return _allUsers;
    final searchTerm = _searchController.text.toLowerCase();
    return _allUsers.where((user) {
      return user.fullName.toLowerCase().contains(searchTerm) ||
          user.email.toLowerCase().contains(searchTerm) ||
          (user.university?.name.toLowerCase().contains(searchTerm) ?? false);
    }).toList();
  }

  Future<void> _handleLikeTap(Product product) async {
    if (_likingProductIds.contains(product.id)) return;

    final isCurrentlyLiked = _isLiked(product);

    setState(() {
      _likingProductIds.add(product.id);
      if (isCurrentlyLiked) {
        _optimisticallyLikedIds.remove(product.id);
        _optimisticallyUnlikedIds.add(product.id);
      } else {
        _optimisticallyUnlikedIds.remove(product.id);
        _optimisticallyLikedIds.add(product.id);
      }
    });

    HapticFeedback.lightImpact();

    try {
      final provider = context.read<ProductFeedProvider>();

      if (isCurrentlyLiked) {
        final likeRecord = _findUserLike(product);
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
        setState(() {
          if (isCurrentlyLiked) {
            _optimisticallyUnlikedIds.remove(product.id);
          } else {
            _optimisticallyLikedIds.remove(product.id);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyLiked
                ? 'Failed to unlike product'
                : 'Failed to like product'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _likingProductIds.remove(product.id);
          _optimisticallyLikedIds.remove(product.id);
          _optimisticallyUnlikedIds.remove(product.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider so the search page rebuilds when likes change on any page
    final provider = context.watch<ProductFeedProvider>();
    final allProducts = provider.products;
    final filteredProducts = _getFilteredProducts(allProducts);

    if (_isLoading || provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || provider.error != null) {
      final message = _error ?? provider.error ?? 'Unknown error';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $message'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadInitialData();
                provider.refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_categories == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProductsTab(filteredProducts),
              _buildStudentsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final onProductsTab = _tabController.index == 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: AppColors.background,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: _searchFocused
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
        Divider(height: 1, thickness: 1, color: AppColors.border),
        // Category filter strip
        if (onProductsTab && _categories != null)
          CategoryFilterStrip(
            categories: _categories!,
            selectedIndex: _selectedCategoryIndex,
            onCategorySelected: (index) =>
                setState(() => _selectedCategoryIndex = index),
            isOpen: _showCategoryFilter,
            onToggle: () =>
                setState(() => _showCategoryFilter = !_showCategoryFilter),
          ),
      ],
    );
  }

  // Products tab
  Widget _buildProductsTab(List<Product> filteredProducts) {
    return _buildProductGrid(filteredProducts);
  }

  Widget _buildProductGrid(List<Product> filteredProducts) {
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        final isLiked = _isLiked(product);

        return ProductGridCard(
          product: product,
          isLiked: isLiked,
          onTap: () async {
            await Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: ProductDetailArgs(productId: product.id),
            );
            if (!context.mounted) return;
            // Refresh product data when returning from detail page
            await context
                .read<ProductFeedProvider>()
                .refreshProduct(product.id);
          },
          onLikeTap: () => _handleLikeTap(product),
        );
      },
    );
  }

  // Students tab
  Widget _buildStudentsTab() {
    if (!_usersLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _getFilteredUsers();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final user = filtered[index];
        return UserProfileListTile(
          user: user,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.userProfile,
              arguments: OtherProfileArgs(userId: user.id),
            );
          },
        );
      },
    );
  }
}
