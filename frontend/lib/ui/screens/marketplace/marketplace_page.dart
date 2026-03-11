import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/navigation/app_routes.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../logic/view_models/product_feed_view_model.dart';
import '../../../logic/view_models/marketplace_view_model.dart';
import '../../widgets/app_refresh_indicator.dart';
import '../../widgets/category_filter_strip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_error_builder.dart';
import 'widgets/product_card.dart';
import 'product_detail_page.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => MarketplacePageState();
}

class MarketplacePageState extends State<MarketplacePage> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  bool _isBootstrapping = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapPageData();
    });
  }

  Future<void> _bootstrapPageData() async {
    if (!mounted) return;

    try {
      await _loadDataIfNeeded();

      if (!mounted) return;
      final provider = context.read<ProductFeedViewModel>();

      if (!provider.isLoading) {
        await provider.load();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapping = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Check if user is near the end of list and load more products
  void _checkAndLoadMore(int currentIndex, int totalItems) {
    final productProvider = context.read<ProductFeedViewModel>();
    
    // Load more when user is within 3 items of the end
    if (currentIndex >= totalItems - 3 && productProvider.hasMore && !productProvider.isLoadingMore) {
      productProvider.loadNextPage();
    }
  }

  /// Only load categories if they haven't been loaded yet
  Future<void> _loadDataIfNeeded() async {
    if (!mounted) return;
    final viewModel = context.read<MarketplaceViewModel>();
    if (viewModel.categories.isEmpty && !viewModel.isLoading) {
      await viewModel.loadCategories();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Selector2<MarketplaceViewModel, ProductFeedViewModel,
        ({
          List<CategoryEntity> categories,
          int? selectedCategoryIndex,
          bool isLoading,
          String? error,
          bool showCategoryFilter,
          List<ProductEntity> products,
          bool productsLoading,
          String? productsError,
        })>(
      selector: (_, marketplaceVm, productVm) => (
        categories: marketplaceVm.categories,
        selectedCategoryIndex: marketplaceVm.selectedCategoryIndex,
        isLoading: marketplaceVm.isLoading,
        error: marketplaceVm.error,
        showCategoryFilter: marketplaceVm.showCategoryFilter,
        products: productVm.products,
        productsLoading: productVm.isLoading,
        productsError: productVm.error,
      ),
      builder: (context, data, _) {
        // Work directly with entities
        final filteredProducts = data.selectedCategoryIndex == null
            ? data.products
            : data.products
                .where(
                  (product) => product.categoryId ==
                      data.categories[data.selectedCategoryIndex!].id,
                )
                .toList();

        final effectiveError = data.error ?? data.productsError;

        return _buildContent(
          context,
          data.categories,
          data.selectedCategoryIndex,
          data.showCategoryFilter,
          data.isLoading,
          data.productsLoading,
          effectiveError,
          filteredProducts,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<CategoryEntity> categories,
    int? selectedCategoryIndex,
    bool showCategoryFilter,
    bool isLoading,
    bool productsLoading,
    String? effectiveError,
    List<ProductEntity> filteredProducts,
  ) {

    return LoadingErrorBuilder(
      isLoading: _isBootstrapping || isLoading || productsLoading,
      isInitialLoad:
          _isBootstrapping || categories.isEmpty || filteredProducts.isEmpty,
      error: effectiveError,
      onRetry: () async {
        final marketplaceVm = context.read<MarketplaceViewModel>();
        final productVm = context.read<ProductFeedViewModel>();
        await marketplaceVm.loadCategories();
        await productVm.refresh();
      },
      child: Column(
        children: [
          CategoryFilterStrip(
            categories: categories,
            selectedIndex: selectedCategoryIndex,
            onCategorySelected: (index) =>
                context.read<MarketplaceViewModel>().selectCategory(index),
            isOpen: showCategoryFilter,
            onToggle: () =>
                context.read<MarketplaceViewModel>().toggleCategoryFilter(),
          ),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: () async {
                final marketplaceVm = context.read<MarketplaceViewModel>();
                final productVm = context.read<ProductFeedViewModel>();
                marketplaceVm.clearSelection();
                if (_pageController.hasClients) {
                  await _pageController.animateToPage(
                    0,
                    duration: AppDurations.standard,
                    curve: Curves.easeOut,
                  );
                }
                await marketplaceVm.loadCategories();
                await productVm.refresh();
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
                      onPageChanged: (index) {
                        // Load more products when user is near the end
                        _checkAndLoadMore(index, filteredProducts.length);
                      },
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ProductCard(
                          key: ValueKey(product.id),
                          product: product,
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
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
