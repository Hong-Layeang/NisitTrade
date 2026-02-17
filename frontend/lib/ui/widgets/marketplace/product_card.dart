import 'package:flutter/material.dart';
import '../../../models/product.dart';
import '../../../utils/constants/colors.dart';
import 'product_card_action_row.dart';
import 'product_card_image_carousel.dart';
import 'product_card_info.dart';
import 'product_card_seller_header.dart';

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _currentImageIndex = 0;
  late PageController _pageController;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isLiked = widget.product.isLiked;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductCardSellerHeader(product: widget.product),
          Expanded(
            child: ProductCardImageCarousel(
              images: widget.product.images,
              currentIndex: _currentImageIndex,
              pageController: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
            ),
          ),
          ProductCardActionRow(
            product: widget.product,
            isLiked: _isLiked,
            onLikeTap: () {
              setState(() {
                _isLiked = !_isLiked;
              });
            },
            onCommentTap: () {},
            onChatTap: () {},
          ),
          ProductCardInfo(product: widget.product),
        ],
      ),
    );
  }
}
