import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../utils/constants/colors.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../models/category.dart';
import '../../../models/like.dart';
import '../../../models/product.dart';
import '../../../services/api/api_exception.dart';
import '../../../providers/product_feed_provider.dart';
import '../../widgets/common/category_widgets.dart';
import '../../widgets/common/product_grid_card.dart';
import '../../widgets/common/search_bar_widget.dart';
import '../../../utils/routes/app_routes.dart';
import '../marketplace/product_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final CategoryRepository _categoryRepository = CategoryRepositoryImpl();
  final UserRepository _userRepository = UserRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();

  List<Category>? _categories;
  int? _selectedCategoryIndex;
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
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    setState(() {}); // Trigger rebuild to recompute filtered list
  }

  List<Product> _getFilteredProducts(List<Product> allProducts) {
    List<Product> filtered = allProducts;

    // Filter by search term
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where((product) =>
              product.title.toLowerCase().contains(searchTerm) ||
              (product.description?.toLowerCase().contains(searchTerm) ?? false))
          .toList();
    }

    // Filter by category
    if (_selectedCategoryIndex != null && _categories != null) {
      final selectedCategory = _categories![_selectedCategoryIndex!];
      filtered = filtered
          .where((product) => product.categoryId == selectedCategory.id)
          .toList();
    }

    return filtered;
  }

  Future<void> _handleLikeTap(Product product) async {
    if (_likingProductIds.contains(product.id)) return;

    final isCurrentlyLiked = _isLiked(product);

    // Optimistic update — show change immediately
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
          // Clear optimistic overrides — provider now has server data
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
        _buildSearchBar(),
        _buildCategoryFilter(),
        Expanded(child: _buildProductGrid(filteredProducts)),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SearchBarWidget(
        controller: _searchController,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CategoryList(
        categories: _categories!,
        selectedIndex: _selectedCategoryIndex,
        onCategorySelected: (index) {
          setState(() => _selectedCategoryIndex = index);
        },
        onSeeAllTap: () {},
        height: 90,
        circleSize: 56,
      ),
    );
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
        childAspectRatio: 0.85,
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
            await context.read<ProductFeedProvider>().refreshProduct(product.id);
          },
          onLikeTap: () => _handleLikeTap(product),
        );
      },
    );
  }
}
