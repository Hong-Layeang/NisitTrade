import 'package:flutter/material.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../utils/constants/colors.dart';
import '../../widgets/common/category_widgets.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/marketplace/product_card.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  final PageController _pageController = PageController();
  final CategoryRepository _categoryRepository = CategoryRepositoryImpl();
  final ProductRepository _productRepository = ProductRepositoryImpl();
  int? _selectedCategoryIndex;
  late final List<Category> _categories;
  late final List<Product> _products;
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _categories = _categoryRepository.getCategories();
    _products = _productRepository.getProducts();
    _filteredProducts = _products;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCategorySelected(int? index) {
    setState(() {
      _selectedCategoryIndex = index;
      if (index == null) {
        _filteredProducts = _products;
      } else {
        final category = _categories[index];
        _filteredProducts =
            _productRepository.getProductsByCategoryId(category.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: CategoryList(
            categories: _categories,
            selectedIndex: _selectedCategoryIndex,
            onCategorySelected: _onCategorySelected,
            height: 90,
            circleSize: 56,
          ),
        ),
        const Divider(height: 1, color: AppColors.surface),
        Expanded(
          child: _filteredProducts.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'No products found',
                  subtitle: 'Try selecting a different category',
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: _filteredProducts[index]);
                  },
                ),
        ),
      ],
    );
  }
}