import 'package:flutter/material.dart';
import '../../../utils/constants/colors.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../services/api/api_exception.dart';
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
  final ProductRepository _productRepository = ProductRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();
  
  List<Category>? _categories;
  List<Product>? _allProducts;
  List<Product> _filteredProducts = [];
  int? _selectedCategoryIndex;
  final Set<int> _likedProducts = {}; // Changed to int for proper product IDs
  
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load categories
      final categoriesResponse = await _categoryRepository.getCategories();
      if (!categoriesResponse.isSuccess) {
        throw categoriesResponse.error!;
      }

      // Load products
      final productsResponse = await _productRepository.getProducts();
      if (!productsResponse.isSuccess) {
        throw productsResponse.error!;
      }

      if (mounted) {
        setState(() {
          _categories = categoriesResponse.data;
          _allProducts = productsResponse.data;
          _filteredProducts = _allProducts ?? [];
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

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    List<Product> filtered = _allProducts ?? [];

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
    if (_selectedCategoryIndex != null) {
      final selectedCategory = _categories![_selectedCategoryIndex!];
      filtered = filtered
          .where((product) => product.categoryId == selectedCategory.id)
          .toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_categories == null || _allProducts == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildSearchBar(),
        _buildCategoryFilter(),
        Expanded(child: _buildProductGrid()),
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
          _applyFilters();
        },
        onSeeAllTap: () {},
        height: 90,
        circleSize: 56,
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty) {
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
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return ProductGridCard(
          product: product,
          isLiked: _likedProducts.contains(product.id),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.productDetail,
              arguments: ProductDetailArgs(productId: product.id),
            );
          },
          onLikeTap: () {
            setState(() {
              if (_likedProducts.contains(product.id)) {
                _likedProducts.remove(product.id);
              } else {
                _likedProducts.add(product.id);
              }
            });
          },
        );
      },
    );
  }
}
