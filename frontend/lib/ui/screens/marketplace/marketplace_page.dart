import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/repository_interfaces/i_category_repository.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../widgets/app_refresh_indicator.dart';
import '../../widgets/category_filter_strip.dart';
import '../../widgets/empty_state.dart';
import 'widgets/product_card.dart';
import 'product_detail_page.dart';

final getIt = GetIt.instance;

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => MarketplacePageState();
}

class MarketplacePageState extends State<MarketplacePage> {
  final PageController _pageController = PageController();
  late final ICategoryRepository _categoryRepository;
  
  List<Category>? _categories;
  int? _selectedCategoryIndex;
  bool _isLoading = false;
  String? _error;
  bool _showCategoryFilter = false;

  Future<void> resetFilterAndRefresh() async {
    if (!mounted) return;

    setState(() {
      _selectedCategoryIndex = null;
      _showCategoryFilter = false;
    });
    if (_pageController.hasClients) {
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    await _loadData();
    if (mounted) {
      await context.read<ProductFeedViewModel>().refresh();
    }
  }

  @override
  void initState() {
    super.initState();
    _categoryRepository = getIt<ICategoryRepository>();
    _loadDataIfNeeded();
    // Always reload products to ensure fresh data for the current user session.
    // This prevents stale cached data from a previous user being shown after
    // a logout/login cycle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductFeedViewModel>();
      if (!provider.isLoading) {
        provider.load();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Only load categories if they haven't been loaded yet
  Future<void> _loadDataIfNeeded() async {
    if (_categories != null) {
      return; // Already loaded, skip
    }
    await _loadData();
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

      if (mounted) {
        setState(() {
          _categories = (categoriesResponse.data ?? [])
              .map((entity) => Category.fromEntity(entity))
              .toList();
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

  void _onCategorySelected(int? index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductFeedViewModel>();
    final productsEntities = productProvider.products;
    final products = productsEntities.map((e) => Product.fromEntity(e)).toList();
    final filteredProducts = _selectedCategoryIndex == null
        ? products
        : products
            .where(
              (product) =>
                  product.categoryId == _categories?[_selectedCategoryIndex!].id,
            )
            .toList();

    if (_isLoading || productProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || productProvider.error != null) {
      final message = _error ?? productProvider.error ?? 'Unknown error';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $message'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _loadData();
                productProvider.refresh();
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
        CategoryFilterStrip(
          categories: _categories!,
          selectedIndex: _selectedCategoryIndex,
          onCategorySelected: _onCategorySelected,
          isOpen: _showCategoryFilter,
          onToggle: () =>
              setState(() => _showCategoryFilter = !_showCategoryFilter),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () async {
              if (mounted) {
                setState(() {
                  _selectedCategoryIndex = null;
                  _showCategoryFilter = false;
                });
              }
              if (_pageController.hasClients) {
                await _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
              await _loadData();
              await productProvider.refresh();
            },
            child: filteredProducts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 24),
                      EmptyState(
                        icon: Icons.shopping_bag_outlined,
                        title: 'No products found',
                        subtitle: 'Try selecting a different category',
                      ),
                    ],
                  )
                : PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.productDetail,
                            arguments: ProductDetailArgs(productId: product.id),
                          );
                          if (!context.mounted) return;
                          // Refresh the product data when returning to ensure like status is updated
                          await context.read<ProductFeedViewModel>().refreshProduct(product.id);
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
